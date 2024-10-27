#!/bin/bash

#!name = mihomo 一键管理脚本
#!desc = 管理
#!date = 2024-10-27 17:20
#!author = ChatGPT

set -e -o pipefail

red="\033[31m"  ## 红色
green="\033[32m"  ## 绿色 
yellow="\033[33m"  ## 黄色
blue="\033[34m"  ## 蓝色
cyan="\033[36m"  ## 青色
reset="\033[0m"  ## 重置

sh_ver="0.0.1"

folders="/root/mihomo"
file="${folders}/mihomo"
sh_file="/usr/bin/mihomo"
wbe_file="${folders}/ui"
sysctl_file="/etc/sysctl.conf"
config_file="${folders}/config.yaml"
version_file="${folders}/version.txt"
system_file="/etc/systemd/system/mihomo.service"

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
    if [ ! -f "$file" ]; then
        echo -e "${red}请先安装 mihomo${reset}"
        start_main
    fi
}

check_status() {
    if pgrep -f "$file" > /dev/null; then
        status="running"
    else
        status="stopped"
    fi
}

get_version() {
    if [ -f "$version_file" ]; then
        cat "$version_file"
    else
        echo -e "${red}请先安装 mihomo${reset}"
    fi
}

show_status() {
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
        if systemctl is-enabled mihomo.service &>/dev/null; then
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

get_schema() {
    arch_raw=$(uname -m)
    case "${arch_raw}" in
        'x86_64') arch='amd64';;
        'x86' | 'i686' | 'i386') arch='386';;
        'aarch64' | 'arm64') arch='arm64';;
        'armv7l') arch='armv7';;
        's390x') arch='s390x';;
        *) echo -e "${red}不支持的架构：${arch_raw}${reset}"; exit 1;;
    esac
}

start_mihomo() {
    check_install
    if systemctl is-active --quiet mihomo; then
        echo -e "${green}mihomo 正在运行中${reset}"
        start_main
    fi
    echo -e "${green}mihomo 准备启动中${reset}"
    if systemctl start mihomo; then
        echo -e "${green}mihomo 启动命令已发出${reset}"
    else
        echo -e "${red}mihomo 启动失败${reset}"
        exit 1
    fi
    sleep 3s
    if systemctl is-active --quiet mihomo; then
        echo -e "${green}mihomo 启动成功${reset}"
    else
        echo -e "${red}mihomo 启动失败${reset}"
        exit 1
    fi
    start_main
}

stop_mihomo() {
    check_install
    if ! systemctl is-active --quiet mihomo; then
        echo -e "${green}mihomo 已经停止${reset}"
        exit 0
    fi
    echo -e "${green}mihomo 准备停止中${reset}"
    if systemctl stop mihomo; then
        echo -e "${green}mihomo 停止命令已发出${reset}"
    else
        echo -e "${red}mihomo 停止失败${reset}"
        exit 1
    fi
    sleep 3s
    if systemctl is-active --quiet mihomo; then
        echo -e "${red}mihomo 停止失败${reset}"
        exit 1
    else
        echo -e "${green}mihomo 停止成功${reset}"
    fi
    start_main
}

restart_mihomo() {
    check_install
    echo -e "${green}mihomo 准备重启中${reset}"
    if systemctl restart mihomo; then
        echo -e "${green}mihomo 重启命令已发出${reset}"
    else
        echo -e "${red}mihomo 重启失败${reset}"
        exit 1
    fi
    sleep 3s
    if systemctl is-active --quiet mihomo; then
        echo -e "${green}mihomo 重启成功${reset}"
    else
        echo -e "${red}mihomo 启动失败${reset}"
        exit 1
    fi
    start_main
}

uninstall_mihomo() {
    check_install
    read -rp "确认卸载 mihomo 吗？(y/n): " confirm
    if [[ -z $confirm || $confirm =~ ^[Nn]$ ]]; then
        echo "卸载已取消。"
        exit 0
    fi
    echo -e "${green}mihomo 开始卸载${reset}"
    echo -e "${green}mihomo 卸载命令已发出${reset}"
    systemctl stop mihomo.service 2>/dev/null || { echo -e "${red}停止 mihomo 服务失败${reset}"; exit 1; }
    systemctl disable mihomo.service 2>/dev/null || { echo -e "${red}禁用 mihomo 服务失败${reset}"; exit 1; }
    rm -f "$system_file" || { echo -e "${red}删除服务文件失败${reset}"; exit 1; }
    rm -rf "$folders" || { echo -e "${red}删除相关文件夹失败${reset}"; exit 1; }
    systemctl daemon-reload || { echo -e "${red}重新加载 systemd 配置失败${reset}"; exit 1; }
    sleep 3s
    if [ ! -f "$system_file" ] && [ ! -d "$folders" ]; then
        echo -e "${green}mihomo 卸载完成${reset}"
        echo ""
        echo -e "卸载成功，如果你想删除此脚本，则退出脚本后，输入 ${green}rm /usr/bin/mihomo -f${reset} 进行删除"
        echo ""
    else
        echo -e "${red}卸载过程中出现问题，请手动检查${reset}"
    fi
    exit 0
}

update_shell() {
    echo -e "${green}开始检查管理脚本是否有更新${reset}"
    sh_ver_url="https://raw.githubusercontent.com/Abcd789JK/Tools/main/Script/mihomo/mihomo.sh"
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
                if [ -f "/usr/bin/mihomo" ]; then
                    rm /usr/bin/mihomo
                fi
                wget -O /usr/bin/mihomo --no-check-certificate "$sh_ver_url"
                chmod +x /usr/bin/mihomo
                if [[ ":$PATH:" != *":/usr/bin:"* ]]; then
                    export PATH=$PATH:/usr/bin
                fi
                hash -r
                echo -e "更新完成，当前版本已更新为 ${green}[ v${sh_new_ver} ]${reset}"
                echo -e "5 秒后执行新脚本"
                sleep 5s
                /usr/bin/mihomo
                break
                ;;
            [Nn]* )
                echo -e "${red}更新已取消 ${reset}"
                exit 1
                ;;
            * )
                echo -e "${red}无效的输入，请输入 y 或 n ${reset}"
                ;;
        esac
    done
    start_main
}

update_mihomo() {
    check_install
    local update_url="https://raw.githubusercontent.com/Abcd789JK/Tools/refs/heads/main/Script/mihomo/update.sh"
    update_url=$(get_url "$update_url")
    bash <(curl -Ls "$update_url")
    systemctl restart mihomo
    start_main
}

download_config() {
    check_install
    local config_url="https://raw.githubusercontent.com/Abcd789JK/Tools/refs/heads/main/Script/mihomo/config.sh"
    config_url=$(get_url "$config_url")
    bash <(curl -Ls "$config_url")
    start_main
}

download_mihomo() {
    if [ -f "$file" ]; then
        echo -e "${red}mihomo 已安装，请勿重复安装！${reset}"
        start_main
    fi
    local install_url="https://raw.githubusercontent.com/Abcd789JK/Tools/main/Script/mihomo/install.sh"
    install_url=$(get_url "$install_url")
    bash <(curl -Ls "$install_url")
}

main() {
    clear
    echo "================================="
    echo -e "${green}欢迎使用 mihomo 一键脚本 Beta 版${reset}"
    echo -e "${green}作者：${yellow} ChatGPT ${reset}"
    echo -e "${red}更换订阅不能保存以前添加的，需要重新添加以前订阅${reset}"
    echo "================================="
    echo -e "${green} 0${reset}. 更新脚本"
    echo "---------------------------------"
    echo -e "${green} 1${reset}. 安装 mihomo"
    echo -e "${green} 2${reset}. 更新 mihomo"
    echo -e "${green} 3${reset}. 卸载 mihomo"
    echo "---------------------------------"
    echo -e "${green} 4${reset}. 启动 mihomo"
    echo -e "${green} 5${reset}. 停止 mihomo"
    echo -e "${green} 6${reset}. 重启 mihomo"
    echo "---------------------------------"
    echo -e "${green} 7${reset}. 更换订阅"
    echo -e "${green}10${reset}. 退出脚本"
    echo "================================="
    show_status
    echo "================================="
    read -p "请输入选项[0-10]：" num
    case "$num" in
        1) download_mihomo ;;
        2) update_mihomo ;;
        3) uninstall_mihomo ;;
        4) start_mihomo ;;
        5) stop_mihomo ;;
        6) restart_mihomo ;;
        7) download_config ;;
        10) exit 0 ;;
        0) update_shell ;;
        *) echo -e "${Red}无效选项，请重新选择${reset}" 
           exit 1 ;;
    esac
}

main
