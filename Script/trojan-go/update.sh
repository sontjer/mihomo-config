#!/bin/bash

#!name = trojan-go 一键更新脚本
#!desc = 更新
#!date = 2024-11-03 22:30
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
    [ "$use_cdn" = true ] && echo "https://gh-proxy.com/$url" || echo "$url"
}

start_main() {
    echo && echo -n -e "${red}* 按回车返回主菜单 *${reset}" 
    read temp
    exec /usr/bin/trojan-go
}

get_version() {
    local version_file="/root/trojan/version.txt"
    if [ -f "$version_file" ]; then
        cat "$version_file"
    else
        echo -e "${red}请先安装 trojan-go${reset}"
        start_main
    fi
}

get_install() {
    local file="/root/trojan/trojan-go"
    if [ ! -f "$file" ]; then
        echo -e "${red}请先安装 trojan-go${reset}"
        start_main
    fi
}

get_schema(){
    arch_raw=$(uname -m)
    case "${arch_raw}" in
        'x86_64')    arch='64';;
        'x86' | 'i686' | 'i386')     arch='32';;
        'aarch64' | 'arm64') arch='arm64-v8a';;
        'armv7' | 'armv7l')   arch='arm32-v7a';;
        's390x')    arch='s390x';;
        *)          echo -e "${red}不支持的架构: ${arch_raw}${reset}"; exit 1;;
    esac
}

get_version() {
    local version_url="https://api.github.com/repos/v2fly/trojan-go-core/releases/latest"
    version=$(curl -sSL "$version_url" | jq -r '.tag_name' | sed 's/v//') || {
        echo -e "${red}获取 trojan-go 远程版本失败${reset}";
        exit 1;
    }
}

download_trojan-go() {
    local version_file="/root/trojan/version.txt"
    local filename
    get_version
    case "$arch" in
        'amd64' | '386' | 'armv8' | 'armv7' | 's390x')
            filename="trojan-go-linux-${arch}.zip";;
        *) 
            echo -e "${red}未知的架构: ${arch}${reset}"
            exit 1;;
    esac
    local download_url=$(get_url "https://github.com/v2fly/trojan-go-core/releases/download/v${version}/${filename}")
    wget -t 3 -T 30 "${download_url}" -O "${filename}" || { echo -e "${red}trojan-go 下载失败，可能是网络问题，建议重新运行本脚本重试下载${reset}"; exit 1; }
    unzip "$filename" && rm "$filename" || { echo -e "${red}trojan-go 解压失败${reset}"; exit 1; }
    chmod +x trojan-go
    echo "$version" > "$version_file"
}

update_trojan-go() {
    local folders="/root/trojan"
    get_install
    echo -e "${green}开始检查 trojan-go 是否有更新${reset}"
    cd "$folders" || exit
    get_version
    current_version=$(get_version)
    latest_version="$version"
    if [ "$current_version" == "$latest_version" ]; then
        echo -e "当前版本：[ ${green}${current_version}${reset} ]"
        echo -e "最新版本：[ ${green}${latest_version}${reset} ]"
        echo -e "${green}当前已是最新版本，无需更新${reset}"
        start_main
    fi
    echo -e "${green}检查到 trojan-go 已有新版本${reset}"
    echo -e "当前版本：[ ${green}${current_version}${reset} ]"
    echo -e "最新版本：[ ${green}${latest_version}${reset} ]"
    while true; do
        read -p "是否升级到最新版本？(y/n): " confirm
        case $confirm in
            [Yy]* )
                download_trojan-go
                sleep 2s
                systemctl restart trojan-go
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

update_trojan-go