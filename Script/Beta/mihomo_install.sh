#!/bin/bash

#!name = mihomo 一键安装脚本
#!desc = 安装
#!date = 2024-11-03 22:30
#!author = ChatGPT

sh_ver="1.0.1"

use_cdn=false

if ! curl -s --head --max-time 3 "https://www.google.com" > /dev/null; then
    use_cdn=true
fi

get_url() {
    local url=$1
    [ "$use_cdn" = true ] && echo "https://gh-proxy.com/$url" || echo "$url"
}

install_update() {
    apt update && apt upgrade -y
    apt install -y curl git gzip wget nano iptables tzdata
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    echo "Asia/Shanghai" | tee /etc/timezone > /dev/null
}

check_ip_forward() {
    local sysctl_file="/etc/sysctl.conf"
    if ! sysctl net.ipv4.ip_forward | grep -q "1"; then
        sysctl -w net.ipv4.ip_forward=1
        echo "net.ipv4.ip_forward=1" | tee -a "$sysctl_file" > /dev/null
    fi
    if ! sysctl net.ipv6.conf.all.forwarding | grep -q "1"; then
        sysctl -w net.ipv6.conf.all.forwarding=1
        echo "net.ipv6.conf.all.forwarding=1" | tee -a "$sysctl_file" > /dev/null
    fi
    sysctl -p > /dev/null
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

download_version() {
    local version_url=$(get_url "https://github.com/MetaCubeX/mihomo/releases/download/Prerelease-Alpha/version.txt")
    version=$(curl -sSL "$version_url") || { echo -e "${red}获取 mihomo 远程版本失败${reset}"; exit 1; }
}











