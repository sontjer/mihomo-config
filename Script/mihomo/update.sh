#!/bin/bash

#!name = mihomo 一键更新脚本
#!desc = 更新
#!date = 2024-11-22 10:35
#!author = ChatGPT

set -e -o pipefail

red="\033[31m"  ## 红色
green="\033[32m"  ## 绿色 
yellow="\033[33m"  ## 黄色
blue="\033[34m"  ## 蓝色
cyan="\033[36m"  ## 青色
reset="\033[0m"  ## 重置

sh_ver="1.0.1"

use_cdn=false

if ! curl -s --head --max-time 3 "https://www.google.com" > /dev/null; then
    use_cdn=true
fi

get_url() {
    local url=$1
    if [ "$use_cdn" = true ]; then
        if curl --silent --head --fail --max-time 3 "https://gh-proxy.com/$url" > /dev/null; then
            echo "https://gh-proxy.com/$url"
            return
        fi
        if curl --silent --head --fail --max-time 3 "https://ghp.ci/$url" > /dev/null; then
            echo "https://ghp.ci/$url"
            return
        fi
    fi
    echo "连接失败，可能是网络问题，请检查网络并稍后重试" >&2
    exit 1
}

start_main() {
    echo && echo -n -e "${red}* 按回车返回主菜单 *${reset}" 
    read temp
    exec /usr/bin/mihomo
}

get_version() {
    local version_file="/root/mihomo/version.txt"
    if [ -f "$version_file" ]; then
        cat "$version_file"
    else
        echo -e "${red}请先安装 mihomo${reset}"
        start_main
    fi
}

get_install() {
    local file="/root/mihomo/mihomo"
    if [ ! -f "$file" ]; then
        echo -e "${red}请先安装 mihomo${reset}"
        start_main
    fi
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

get_version() {
    local version_url
    version_url=$(get_url "https://github.com/MetaCubeX/mihomo/releases/download/Prerelease-Alpha/version.txt")
    version=$(curl -sSL "$version_url") || { echo -e "${red}获取 mihomo 远程版本失败${reset}"; exit 1; }
}

download_mihomo() {
    local version_file="/root/mihomo/version.txt"
    local filename
    get_schema
    get_version
    [[ "$arch" == 'amd64' ]] && filename="mihomo-linux-${arch}-compatible-go120-${version}.gz" ||
    filename="mihomo-linux-${arch}-${version}.gz"
    local download_url=$(get_url "https://github.com/MetaCubeX/mihomo/releases/download/Prerelease-Alpha/${filename}")
    wget -t 3 -T 30 "${download_url}" -O "${filename}" || { echo -e "${red}mihomo 下载失败，可能是网络问题，建议重新运行本脚本重试下载${reset}"; exit 1; }
    gunzip "$filename" || { echo -e "${red}mihomo 解压失败${reset}"; exit 1; }
    mv "mihomo-linux-${arch}-compatible-go120-${version}" mihomo 2>/dev/null || mv "mihomo-linux-${arch}-${version}" mihomo || { echo -e "${red}找不到解压后的文件${reset}"; exit 1; }
    chmod +x mihomo
    echo "$version" > "$version_file"
}

update_mihomo() {
    local folders="/root/mihomo"
    get_install
    echo -e "${green}开始检查 mihomo 是否有更新${reset}"
    cd "$folders" || exit
    download_version
    current_version=$(get_version)
    latest_version="$version"
    if [ "$current_version" == "$latest_version" ]; then
        echo -e "当前版本：[ ${green}${current_version}${reset} ]"
        echo -e "最新版本：[ ${green}${latest_version}${reset} ]"
        echo -e "${green}当前已是最新版本，无需更新${reset}"
        start_main
    fi
    echo -e "${green}已检查到 mihomo 已有新版本${reset}"
    echo -e "当前版本：[ ${green}${current_version}${reset} ]"
    echo -e "最新版本：[ ${green}${latest_version}${reset} ]"
    while true; do
        read -p "是否升级到最新版本？(y/n): " confirm
        case $confirm in
            [Yy]* )
                download_mihomo
                sleep 2s
                systemctl restart mihomo
                echo -e "${green}更新完成，当前版本已更新为：[ ${latest_version} ]${reset}"
                start_main
                ;;
            [Nn]* )
                echo -e "${red}更新已取消${reset}"
                start_main
                ;;
            * )
                echo -e "${red}无效的输入，请输入 y 或 n${reset}"
                ;;
        esac
    done
}

update_mihomo
