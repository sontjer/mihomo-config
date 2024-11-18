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

Config() {
    local config_file="/root/trojan/config.json"
    local config_url=$(get_url "https://raw.githubusercontent.com/Abcd789JK/Tools/refs/heads/main/Config/trojan-go.json")
    curl -s -o "$config_file" "$config_url"
    echo -e "${green}开始下载配置文件 ${reset}"
    echo -e ""
    echo -e "${green}trojan-go 配置已下载到 ${config_file} 文件夹${reset}"
    echo -e "${green}你需要根据你自己的实际情况去修改${reset}"
    systemctl daemon-reload
    systemctl start trojan-go
    systemctl enable trojan-go
    echo -e "${green}trojan-go 已成功启动并设置为开机自启${reset}"
}

Config