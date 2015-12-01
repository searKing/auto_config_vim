#!/bin/bash

function log_info() {
	echo "[INFO]$@"
}

function log_debug() {
	echo "[DEBUG]$@"
}

function log_warn() {
	echo "[WARN]$@"
}

function log_error() {
	echo "[ERROR]$@"
}

#使用方法说明
function usage() {
	cat<<USAGEEOF
	NAME
		$g_shell_name - 自动配置vim tag环境
	SYNOPSIS
		source $g_shell_name [命令列表] [文件名]...
	DESCRIPTION
		$g_git_wrap_shell_name --自动配置git环境
			-h
				get help log_info
			-f
				force mode to override exist file of the same name
			-v
				verbose display
	AUTHOR 作者
    	由 searKing Chan 完成。

    DATE   日期
		2015-12-02

	REPORTING BUGS 报告缺陷
    	向 searKingChan@gmail.com 报告缺陷。
	REFERENCE	参见
		https://github.com/searKing/auto_config_vim.git
USAGEEOF
}

#设置默认配置参数
function set_default_cfg_param(){
	#覆盖前永不提示-f
	g_cfg_force_mode=0
	#是否显示详细信息
	g_cfg_visual=0
}
#设置默认变量参数
function set_default_var_param(){
	#获取当前脚本短路径名称
	g_shell_name="$(basename $0)"
	#切换并获取当前脚本所在路径
	g_shell_repositories_abs_dir="$(cd `dirname $0`; pwd)"
}
#解析输入参数
function parse_params_in() {
	if [ "$#" -lt 0 ]; then
		cat << HELPEOF
use option -h to get more log_information .
HELPEOF
		return 1
	fi
	set_default_cfg_param #设置默认配置参数
	set_default_var_param #设置默认变量参数
	unset OPTIND
	while getopts "m:p:dvfo:h" opt
	do
		case $opt in
		f)
			#覆盖前永不提示
			g_cfg_force_mode=1
			;;
		v)
			#是否显示详细信息
			g_cfg_visual=1
			;;
		h)
			usage
			return 1
			;;
		?)
			log_error "${LINENO}:$opt is Invalid"
			return 1
			;;
		*)
			;;
		esac
	done
	#去除options参数
	shift $(($OPTIND - 1))

	if [ "$#" -lt 0 ]; then
		cat << HELPEOF
use option -h to get more log_information .
HELPEOF
		return 0
	fi
}

#安装应用
function install_app()
{
	expected_params_in_num=1
	if [ $# -ne $expected_params_in_num ]; then
		log_error "${LINENO}:$FUNCNAME expercts $expected_params_in_num param_in, but receive only $#. EXIT"
		return 1;
	fi
	app_name=$1
	#检测是否安装成功msmtp
	if [ $g_cfg_visual -ne 0 ]; then
		which "$app_name"
	else
		which "$app_name"	1>/dev/null
	fi

	if [ $? -ne 0 ]; then
		sudo apt-get install "$app_name"
		ret=$?
		if [ $ret -ne 0 ]; then
			log_error "${LINENO}: install "$app_name" failed($ret). Exit."
			return 1;
		fi
	fi
}

#自动补全插件lua(neocomplete)
function install_lua()
{
	install_app "lua5.3"
	if [[ $? -ne 0 ]]; then
		return 1
	fi
}
#NodeJS环境 npm NodeJS (syntastic)
function install_NodeJS()
{
	install_app "npm"
	if [[ $? -ne 0 ]]; then
		return 1
	fi
	#JSHint语法检测
	sudo npm install -g jshint
	#CSSLint语法检测
	sudo npm install -g csslint
	#智能提示扩展JavaScript
	#sudo npm insatll -g tern
}
#Vimproc环境 Neocomplete,VimShell,Unite
function install_Vimproc()
{
	repo_name="vimproc.vim"
	if [[ -d "$repo_name" ]]; then
		if [ $g_cfg_force_mode -eq 0 ]; then
			log_error "${LINENO}:"$repo_name" files is already exist. Exit."
			return 1
		else
			log_info "force delete exist "$repo_name" files"
			rm "$repo_name" -Rf
		fi
	fi
	mkdir -p "$repo_name"
	git clone https://github.com/searKing/"$repo_name".git

	#切换到vimproc.vim的repo版本库目录
	cd "$repo_name"
	#make ARCHS='i386 x86_64'
	make
	if [[ $? -ne 0 ]]; then
		log_error "${LINENO}:"$repo_name" make failed. Exit."
		return 1
	fi
}
#the_silver_searcher(ag.vim)
function install_Vimproc()
{
	install_app "silversearcher-ag"
	if [[ $? -ne 0 ]]; then
		return 1
	fi
	#源码编译
	#git clone https://github.com/searKing/the_silver_searcher.git
	#cd the_silver_searcher
	#apt-get install -y automake pkg-config libpcre3-dev zlib1g-dev liblzma-dev
	#./build.sh
	#sudo make install
}

#循环嵌套调用程序,每次输入一个参数
#本shell中定义的其他函数都认为不支持空格字符串的序列化处理（pull其实也支持）
#@param func_in 	函数名 "func" 只支持单个函数
#@param param_in	以空格分隔的字符串"a b c",可以为空
function call_func_serializable()
{
	func_in=$1
	param_in=$2
	case $# in
		0 | 1)
			log_error "${LINENO}:$FUNCNAME expercts 2 param in at least, but receive only $#. EXIT"
			return 1
			;;
		*)	#有参数函数调用
			error_num=0
			for curr_param in $param_in
			do
				case $func_in in
					"install_app")
						app_name=$curr_param
						$func_in "$app_name"
						if [ $? -ne 0 ]; then
							error_num+=0
						fi
					 	;;
					*)
						log_error "${LINENO}:Invalid serializable cmd with params: $func_in"
						return 1
					 	;;
				esac
			done
			return $error_num
			;;
	esac
}

#自动配置vim插件
#@param_in app_names
function auto_config_vim()
{
		expected_params_in_num=0
		if [ $# -ne $expected_params_in_num ]; then
			log_error "${LINENO}:$FUNCNAME expercts $expected_params_in_num param_in, but receive only $#. EXIT"
			return 1;
		fi
		install_lua
		ret=$?
		if [[ $ret -ne 0 ]]; then
			return 1
		fi
		install_NodeJS
		ret=$?
		if [[ $ret -ne 0 ]]; then
			return 1
		fi
		install_Vimproc
		ret=$?
		if [[ $ret -ne 0 ]]; then
			return 1
		fi
}
#所有任务均在此入口
function do_work(){
	auto_config_vim
	ret=$?
	if [ $ret -ne 0 ]; then
		return 1
	fi
}

################################################################################
#脚本开始
################################################################################
function shell_wrap()
{
	#含空格的字符串若想作为一个整体传递，则需加*
	#"$*" is equivalent to "$1c$2c...",
	#where c is the first character of the value of the IFS variable.
	#"$@" is equivalent to "$1" "$2" ...
	#$*、$@不加"",则无区别，
	parse_params_in "$@"
	if [ $? -ne 0 ]; then
		return 1
	fi
	do_work
	if [ $? -ne 0 ]; then
		return 1
	fi
	log_info "$0 $@ is running successfully"
	read -n1 -p "Press any key to continue..."
	return 0
}
shell_wrap "$@"
