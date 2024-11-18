#!/bin/bash

#!name = trojan-go 一键管理脚本
#!desc = 管理
#!date = 2024-11-18 19:30
#!author = ChatGPT

set -e -o pipefail

red="\033[31m"  ## 红色
green="\033[32m"  ## 绿色 
yellow="\033[33m"  ## 黄色
blue="\033[34m"  ## 蓝色
cyan="\033[36m"  ## 青色
reset="\033[0m"  ## 重置

sh_ver="0.0.1"

use_cdn=false

if ! curl -s --head --max-time 3 "https://www.google.com" > /dev/null; then
    use_cdn=true
fi

get_url() {
    local url=$1
    [ "$use_cdn" = true ] && echo "https://gh-proxy.com/$url" || echo "$url"
}

start_main() {
    echo && echo -n -e "${red}* 按回车返回主菜单 *${reset}" && read temp
    main
}

check_install() {
    local file="/root/trojan-go/trojan-go"
    if [ ! -f "$file" ]; then
        echo -e "${red}请先安装 trojan-go${reset}"
        start_main
    fi
}

check_status() {
    local file="/root/trojan-go/trojan-go"
    if pgrep -f "$file" > /dev/null; then
        status="running"
    else
        status="stopped"
    fi
}

get_version() {
    local version_file="/root/trojan-go/version.txt"
    if [ -f "$version_file" ]; then
        cat "$version_file"
    else
        echo -e "${red}请先安装 trojan-go${reset}"
    fi
}

show_status() {
    local file="/root/trojan-go/trojan-go"
    check_status
    if [ ! -f "$file" ]; then
        status="${red}未安装${reset}"
        run_status="${red}未运行${reset}"
        auto_start="${red}未设置${reset}"
    else
        check_status
        if [ "$status" == "running" ]; then
            status="${green}已安装${reset}"
            run_status="${green}运行中${reset}"
        else
            status="${green}已安装${reset}"
            run_status="${red}未运行${reset}"
        fi
        if systemctl is-enabled trojan-go.service &>/dev/null; then
            auto_start="${green}已设置${reset}"
        else
            auto_start="${red}未设置${reset}"
        fi
    fi
    echo -e "脚本版本：${green}${sh_ver}${reset}"
    echo -e "安装状态：${status}"
    echo -e "运行状态：${run_status}"
    echo -e "开机自启：${auto_start}"
}

manage_trojan-go() {
    local action="$1"
    check_install
    case "$action" in
        start) 
            action_text="启动" 
            if systemctl is-active --quiet trojan-go; then
                echo -e "${yellow}trojan-go 已经在运行，无需重复操作${reset}"
                start_main
            fi
            ;;
        stop)
            action_text="停止" 
            if ! systemctl is-active --quiet trojan-go; then
                echo -e "${yellow}trojan-go 已经停止，无需重复操作${reset}"
                start_main
                return 0
            fi
            ;;
        restart) action_text="重启" ;;
    esac
    echo -e "${green}trojan-go 准备${action_text}中${reset}"
    systemctl "$action" trojan-go
    sleep 1s
    echo -e "${green}trojan-go ${action_text}命令已发出${reset}"
    sleep 3s
    if [ "$action" = "stop" ]; then
        if systemctl is-active --quiet trojan-go; then
            echo -e "${red}trojan-go ${action_text}失败${reset}"
        else
            echo -e "${green}trojan-go ${action_text}成功${reset}"
        fi
    else
        if systemctl is-active --quiet trojan-go; then
            echo -e "${green}trojan-go ${action_text}成功${reset}"
        else
            echo -e "${red}trojan-go ${action_text}失败${reset}"
        fi
    fi
    start_main
}

start_trojan-go() { manage_trojan-go start; }
stop_trojan-go() { manage_trojan-go stop; }
restart_trojan-go() { manage_trojan-go restart; }

uninstall_trojan-go() {
    local folders="/root/trojan-go"
    local shell_file="/usr/bin/trojan-go"
    local system_file="/etc/systemd/system/trojan-go.service"
    check_install
    read -rp "确认卸载 trojan-go 吗？(y/n): " confirm
    if [[ -z $confirm || $confirm =~ ^[Nn]$ ]]; then
        echo "卸载已取消。"
        start_main
    fi
    echo -e "${green}trojan-go 开始卸载${reset}"
    sleep 1s
    echo -e "${green}trojan-go 卸载命令已发出${reset}"
    systemctl stop trojan-go.service 2>/dev/null || { echo -e "${red}停止 trojan-go 服务失败${reset}"; exit 1; }
    systemctl disable trojan-go.service 2>/dev/null || { echo -e "${red}禁用 trojan-go 服务失败${reset}"; exit 1; }
    rm -f "$system_file" || { echo -e "${red}删除服务文件失败${reset}"; exit 1; }
    rm -rf "$folders" || { echo -e "${red}删除相关文件夹失败${reset}"; exit 1; }
    systemctl daemon-reload || { echo -e "${red}重新加载 systemd 配置失败${reset}"; exit 1; }
    sleep 3s
    if [ ! -f "$system_file" ] && [ ! -d "$folders" ]; then
        echo -e "${green}trojan-go 卸载完成${reset}"
        echo ""
        echo -e "卸载成功，如果你想删除此脚本，则退出脚本后，输入 ${green}rm $shell_file -f${reset} 进行删除"
        echo ""
    else
        echo -e "${red}卸载过程中出现问题，请手动检查${reset}"
    fi
    start_main
}

update_shell() {
    local shell_file="/usr/bin/trojan-go"
    echo -e "${green}开始检查管理脚本是否有更新${reset}"
    sh_ver_url="https://raw.githubusercontent.com/Abcd789JK/Tools/main/Script/trojan-go/trojan-go.sh"
    sh_new_ver=$(wget --no-check-certificate -qO- "$sh_ver_url" | grep 'sh_ver="' | awk -F "=" '{print $NF}' | sed 's/\"//g' | head -1)
    if [ "$sh_ver" == "$sh_new_ver" ]; then
        echo -e "当前版本：[ ${green}${sh_ver}${reset} ]"
        echo -e "最新版本：[ ${green}${sh_new_ver}${reset} ]"
        echo -e "${green}当前已是最新版本，无需更新${reset}"
        start_main
    fi
    echo -e "${green}检查到已有新版本${reset}"
    echo -e "当前版本：[ ${green}${sh_ver}${reset} ]"
    echo -e "最新版本：[ ${green}${sh_new_ver}${reset} ]"
    while true; do
        read -p "是否升级到最新版本？(y/n)：" confirm
        case $confirm in
            [Yy]* )
                echo -e "开始下载最新版本 [ ${green}${sh_new_ver}${reset} ]"
                if [ -f "$shell_file" ]; then
                    rm $shell_file
                fi
                wget -O $shell_file --no-check-certificate "$sh_ver_url"
                chmod +x $shell_file
                if [[ ":$PATH:" != *":/usr/bin:"* ]]; then
                    export PATH=$PATH:/usr/bin
                fi
                hash -r
                echo -e "更新完成，当前版本已更新为 ${green}[ v${sh_new_ver} ]${reset}"
                echo -e "5 秒后执行新脚本"
                sleep 5s
                /usr/bin/trojan-go
                break
                ;;
            [Nn]* )
                echo -e "${red}更新已取消 ${reset}"
                start_main
                ;;
            * )
                echo -e "${red}无效的输入，请输入 y 或 n ${reset}"
                ;;
        esac
    done
    start_main
}

update_trojan-go() {
    check_install
    local update_url="https://raw.githubusercontent.com/Abcd789JK/Tools/refs/heads/main/Script/trojan-go/update.sh"
    update_url=$(get_url "$update_url")
    bash <(curl -Ls "$update_url")
    systemctl restart trojan-go
    start_main
}

download_config() {
    check_install
    local config_url="https://raw.githubusercontent.com/Abcd789JK/Tools/refs/heads/main/Script/trojan-go/config.sh"
    config_url=$(get_url "$config_url")
    bash <(curl -Ls "$config_url")
    start_main
}

download_trojan-go() {
    local file="/root/trojan-go/trojan-go"
    if [ -f "$file" ]; then
        echo -e "${red}trojan-go 已安装，请勿重复安装！${reset}"
        start_main
    fi
    local install_url="https://raw.githubusercontent.com/Abcd789JK/Tools/main/Script/trojan-go/install.sh"
    install_url=$(get_url "$install_url")
    bash <(curl -Ls "$install_url")
}

main() {
    clear
    echo "================================="
    echo -e "${green}欢迎使用 trojan-go 一键脚本 Beta 版${reset}"
    echo -e "${green}作者：${yellow} ChatGPT ${reset}"
    echo -e "${red}更换订阅不能保存以前添加的，需要重新添加以前订阅${reset}"
    echo "================================="
    echo -e "${green} 0${reset}. 更新脚本"
    echo "---------------------------------"
    echo -e "${green} 1${reset}. 安装 trojan-go"
    echo -e "${green} 2${reset}. 更新 trojan-go"
    echo -e "${green} 3${reset}. 卸载 trojan-go"
    echo "---------------------------------"
    echo -e "${green} 4${reset}. 启动 trojan-go"
    echo -e "${green} 5${reset}. 停止 trojan-go"
    echo -e "${green} 6${reset}. 重启 trojan-go"
    echo "---------------------------------"
    echo -e "${green}10${reset}. 退出脚本"
    echo "================================="
    show_status
    echo "================================="
    read -p "请输入选项[0-10]：" num
    case "$num" in
        1) download_trojan-go ;;
        2) update_trojan-go ;;
        3) uninstall_trojan-go ;;
        4) start_trojan-go ;;
        5) stop_trojan-go ;;
        6) restart_trojan-go ;;
        10) exit 0 ;;
        0) update_shell ;;
        *) echo -e "${Red}无效选项，请重新选择${reset}" 
           exit 1 ;;
    esac
}

main