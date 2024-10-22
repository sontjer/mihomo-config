#!/bin/sh

#!name = mihomo 一键安装脚本
#!desc = 安装
#!date = 2024-10-07 20:50
#!author = ChatGPT

set -e

# 颜色代码
Red="\033[31m"  ## 红色
Green="\033[32m"  ## 绿色 
Yellow="\033[33m"  ## 黄色
Blue="\033[34m"  ## 蓝色
Magenta="\033[35m"  ## 洋红
Cyan="\033[36m"  ## 青色
White="\033[37m"  ## 白色
Reset="\033[0m"  ## 黑色

# 变量路径
FOLDERS="/root/mihomo"
FILE="/root/mihomo/mihomo"
WEB_FILE="/root/mihomo/ui"
CONFIG_FILE="/root/mihomo/config.yaml"
VERSION_FILE="/root/mihomo/version.txt"
SYSTEM_FILE="/etc/systemd/system/mihomo.service"

# 更新系统
echo -e "${Green}开始更新系统${Reset}"
apk update && apk upgrade

# 安装插件
echo -e "${Green}开始安装必要插件${Reset}"
apk add --no-cache curl git wget nano iptables ip6tables openrc

# 获取本机 IP
GetLocal_ip(){
    ipv4=$(ip addr show $(ip route | grep default | awk '{print $5}') | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
    ipv6=$(ip addr show $(ip route | grep default | awk '{print $5}') | grep 'inet6 ' | awk '{print $2}' | cut -d/ -f1)
}

# 检查并开启 IP 转发
Check_ip_forward() {
    if ! sysctl net.ipv4.ip_forward | grep -q "1"; then
        sysctl -w net.ipv4.ip_forward=1
        echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
        sysctl -p > /dev/null
        echo -e "${Green}IP 转发已成功开启并立即生效${Reset}"
    fi
}

# 获取架构
Get_schema(){
    ARCH_RAW=$(uname -m)
    case "${ARCH_RAW}" in
        'x86_64')    ARCH='amd64';;
        'x86' | 'i686' | 'i386')     ARCH='386';;
        'aarch64' | 'arm64') ARCH='arm64';;
        'armv7l')   ARCH='armv7';;
        's390x')    ARCH='s390x';;
        *)          echo -e "${Red}不支持的架构：${ARCH_RAW}${Reset}"; exit 1;;
    esac
}

# 准备安装
echo -e "${Green}开始安装 mihomo ${Reset}"

# 开始安装
Install_mihomo(){
    if [ -d "${FOLDERS}" ]; then
        rm -rf "${FOLDERS}"
    fi
    mkdir -p "${FOLDERS}" && cd "${FOLDERS}" 
    Get_schema
    echo -e "当前系统架构：[ ${Green}${ARCH_RAW}${Reset} ]"
    VERSION_URL="https://github.com/MetaCubeX/mihomo/releases/download/Prerelease-Alpha/version.txt"
    VERSION=$(curl -sSL "$VERSION_URL") || { echo -e "${Red}获取远程版本失败${Reset}"; exit 1; }
    echo -e "当前软件版本：[ ${Green}${VERSION}${Reset} ]"
    echo "$VERSION" > "$VERSION_FILE"
    
    FILENAME="mihomo-linux-${ARCH}-${VERSION}.gz"
    DOWNLOAD_URL="https://github.com/MetaCubeX/mihomo/releases/download/Prerelease-Alpha/${FILENAME}"
    sleep 3s
    wget -t 3 -T 30 "${DOWNLOAD_URL}" -O "${FILENAME}" || { echo -e "${Red}下载失败${Reset}"; exit 1; }
    gunzip "$FILENAME" || { echo -e "${Red}解压失败${Reset}"; exit 1; }

    mv "mihomo-linux-${ARCH}-${VERSION}" mihomo || { echo -e "${Red}找不到解压后的文件${Reset}"; exit 1; }
    chmod 755 mihomo

    WEB_URL="https://github.com/metacubex/metacubexd.git"
    git clone "$WEB_URL" -b gh-pages "$WEB_FILE" || { echo -e "${Red}管理面板下载失败${Reset}"; exit 1; }
    
    SYSTEM_URL="https://raw.githubusercontent.com/Abcd789JK/Tools/refs/heads/main/Service/mihomo.service"
    curl -s -o "$SYSTEM_FILE" "$SYSTEM_URL" || { echo -e "${Red}系统服务下载失败${Reset}"; exit 1; }
    chmod +x "$SYSTEM_FILE"
    echo -e "${Green}mihomo 安装完成，开始配置${Reset}"

    sh_url="https://raw.githubusercontent.com/Abcd789JK/Tools/refs/heads/main/Script/mihomo/mihomo.sh"
    wget -q -O /usr/bin/mihomo --no-check-certificate "$sh_url"
    chmod +x /usr/bin/mihomo

    echo -e "${Green}已设置开机自启动${Reset}"
    Config_mihomo
}

# 配置文件
Config_mihomo(){
    CONFIG_URL="https://raw.githubusercontent.com/Abcd789JK/Tools/refs/heads/main/Config/mihomo.yaml"
    curl -s -o "$CONFIG_FILE" "$CONFIG_URL"

    while true; do
        read -p "请输入需要配置的机场数量（默认 1 个，最多 5 个）：" airport_count
        airport_count=${airport_count:-1}
        if [[ "$airport_count" =~ ^[0-9]+$ ]] && [ "$airport_count" -ge 1 ] && [ "$airport_count" -le 5 ]; then
            break
        else
            echo -e "${Red}无效的数量，请输入 1 到 5 之间的正整数。${Reset}"
        fi
    done

    proxy_providers="proxy-providers:"
    for ((i=1; i<=airport_count; i++)); do
        read -p "请输入第 $i 个机场的订阅连接：" airport_url
        read -p "请输入第 $i 个机场的名称：" airport_name
        
        proxy_providers="$proxy_providers
  provider_0$i:
    url: \"$airport_url\"
    type: http
    interval: 86400
    health-check: {enable: true,url: \"https://www.gstatic.com/generate_204\",interval: 300}
    override:
      additional-prefix: \"[$airport_name]\""
    done

    awk -v providers="$proxy_providers" '
    /^# 机场配置/ {
        print
        print providers
        next
    }
    { print }
    ' "$CONFIG_FILE" > temp.yaml && mv temp.yaml "$CONFIG_FILE"

    echo -e "mihomo 配置已完成并保存到 ${CONFIG_FILE} 文件夹"
    systemctl daemon-reload
    systemctl start mihomo
    systemctl enable mihomo
    
    GetLocal_ip
    echo -e ""
    echo -e "恭喜你，你的 mihomo 已经配置完成"
    echo -e "${Magenta}=========================${Reset}"
    echo -e "mihomo 管理面板地址"
    echo -e "${Green}http://$ipv4:9090/ui ${Reset}"
    echo -e "${White}-------------------------${Reset}"
    echo -e "${Yellow}mihomo          进入菜单 ${Reset}"
    echo -e "${Cyan}=========================${Reset}"
}

Check_ip_forward
Install_mihomo
