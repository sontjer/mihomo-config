#!/bin/bash

#!name = trojan-go 一键安装脚本
#!desc = 安装
#!date = 2024-11-18 19:30
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

get_schema(){
    arch_raw=$(uname -m)
    case "${arch_raw}" in
        'x86_64')    arch='amd64';;
        'x86' | 'i686' | 'i386')     arch='386';;
        'aarch64' | 'arm64') arch='armv8';;
        'armv7' | 'armv7l')   arch='armv7';;
        's390x')    arch='s390x';;
        *)          echo -e "${red}不支持的架构: ${arch_raw}${reset}"; exit 1;;
    esac
}

get_version() {
    local version_url="https://api.github.com/repos/p4gefau1t/trojan-go/releases/latest"
    version=$(curl -sSL "$version_url" | jq -r '.tag_name' | sed 's/v//') || {
        echo -e "${red}获取 trojan-go 远程版本失败${reset}";
        exit 1;
    }
}

install_update() {
    apt update && apt upgrade -y
    apt install -y curl git gzip wget nano unzip jq
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    echo "Asia/Shanghai" | tee /etc/timezone > /dev/null
}

download_trojan-go() {
    local version_file="/root/trojan-go/version.txt"
    local filename
    get_version
    case "$arch" in
        'amd64' | '386' | 'armv8' | 'armv7' | 's390x')
            filename="trojan-go-linux-${arch}.zip";;
        *) 
            echo -e "${red}未知的架构: ${arch}${reset}"
            exit 1;;
    esac
    local download_url=$(get_url "https://github.com/p4gefau1t/trojan-go/releases/download/v${version}/${filename}")
    wget -t 3 -T 30 "${download_url}" -O "${filename}" || { echo -e "${red}trojan-go 下载失败，可能是网络问题，建议重新运行本脚本重试下载${reset}"; exit 1; }
    unzip "$filename" && rm "$filename" || { echo -e "${red}trojan-go 解压失败${reset}"; exit 1; }
    chmod +x trojan-go
    echo "$version" > "$version_file"
}

download_service() {
    local system_file="/etc/systemd/system/trojan-go.service"
    local service_url=$(get_url "https://raw.githubusercontent.com/Abcd789JK/Tools/refs/heads/main/Service/trojan-go.service")
    curl -s -o "$system_file" "$service_url" || { echo -e "${red}系统服务下载失败，可能是网络问题，建议重新运行本脚本重试下载${reset}"; exit 1; }
    chmod +x "$system_file"
    systemctl enable trojan-go
}

download_shell() {
    local shell_file="/usr/bin/trojan-go"
    local sh_url=$(get_url "https://raw.githubusercontent.com/Abcd789JK/Tools/refs/heads/main/Script/trojan-go/trojan-go.sh")
    [ -f "$shell_file" ] && rm -f "$shell_file"
    wget -q -O "$shell_file" --no-check-certificate "$sh_url" || { echo -e "${red}trojan-go 管理脚本下载失败，可能是网络问题，建议重新运行本脚本重试下载${reset}"; exit 1; }
    chmod +x "$shell_file"
    [[ ":$PATH:" != *":/usr/bin:"* ]] && export PATH="$PATH:/usr/bin"
    hash -r
}

download_config() {
    local config_url="https://raw.githubusercontent.com/Abcd789JK/Tools/refs/heads/main/Script/trojan-go/config.sh"
    config_url=$(get_url "$config_url")
    bash <(curl -Ls "$config_url")
}

install_trojan-go() {
    local folders="/root/trojan-go"
    [ -d "$folders" ] && rm -rf "$folders"
    mkdir -p "$folders" && cd "$folders" 
    get_schema
    echo -e "当前系统架构：[ ${green}${arch_raw}${reset} ]" 
    get_version
    echo -e "当前软件版本：[ ${green}${version}${reset} ]"
    download_trojan-go
    download_service
    download_shell
    read -p "$(echo -e "${green}安装完成，是否下载配置文件\n${yellow}你也可以上传自己的配置文件到 $folders 目录下\n${red}配置文件名称必须是 config.yaml ${reset}，是否继续(y/n): ")" choice
    case "$choice" in
        [Yy]* ) download_config ;;
        [Nn]* ) echo -e "${green}跳过配置文件下载${reset}" ;;
        * ) echo -e "${red}无效选择，跳过配置文件下载${reset}" ;;
    esac
    rm -f /root/install.sh
}

install_update
install_trojan-go