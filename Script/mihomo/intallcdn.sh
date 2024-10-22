#!/bin/bash

#!name = mihomo 一键安装脚本
#!desc = 安装
#!date = 2024-10-22 11:00
#!author = ChatGPT

set -e -o pipefail

# 颜色代码
Red="\033[31m"  ## 红色
Green="\033[32m"  ## 绿色 
Yellow="\033[33m"  ## 黄色
Blue="\033[34m"  ## 蓝色
Magenta="\033[35m"  ## 洋红
Cyan="\033[36m"  ## 青色
White="\033[37m"  ## 白色
Reset="\033[0m"  ## 黑色

# 脚本版本
sh_ver="0.0.1"

# 变量路径
FOLDERS="/root/mihomo"
FILE="/root/mihomo/mihomo"
WEB_FILE="/root/mihomo/ui"
SYSCTL_FILE="/etc/sysctl.conf"
CONFIG_FILE="/root/mihomo/config.yaml"
VERSION_FILE="/root/mihomo/version.txt"
SYSTEM_FILE="/etc/systemd/system/mihomo.service"

# 更新系统
echo -e "${Green}开始更新系统${Reset}"
apt update && apt upgrade -y

# 安装插件
echo -e "${Green}开始安装必要插件${Reset}"
apt install -y curl git wget nano iptables

# 获取本机 IP
GetLocal_ip(){
    # 获取本机的 IPv4 地址
    ipv4=$(ip addr show $(ip route | grep default | awk '{print $5}') | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
    # 获取本机的 IPv6 地址
    ipv6=$(ip addr show $(ip route | grep default | awk '{print $5}') | grep 'inet6 ' | awk '{print $2}' | cut -d/ -f1)
}

# 检查并开启 IP 转发
Check_ip_forward() {
    if ! sysctl net.ipv4.ip_forward | grep -q "1"; then
        sysctl -w net.ipv4.ip_forward=1
        echo "net.ipv4.ip_forward=1" | tee -a "$SYSCTL_FILE" > /dev/null
        sysctl -p > /dev/null  # 立即生效
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
    # 删除已有的 mihomo 文件夹（如果存在）
    if [ -d "${FOLDERS}" ]; then
        rm -rf "${FOLDERS}"
    fi
    # 创建 mihomo 文件夹并切换到该目录
    mkdir -p "${FOLDERS}" && cd "${FOLDERS}" 
    # 获取架构
    Get_schema
    echo -e "当前系统架构：[ ${Green}${ARCH_RAW}${Reset} ]"
    # 获取版本信息
    VERSION_URL="https://github.com/MetaCubeX/mihomo/releases/download/Prerelease-Alpha/version.txt"
    VERSION=$(curl -sSL "$VERSION_URL") || { echo -e "${Red}获取远程版本失败${Reset}"; exit 1; }
    echo -e "当前软件版本：[ ${Green}${VERSION}${Reset} ]"
    echo "$VERSION" > "$VERSION_FILE"
    # 构造文件名
    if [[ "$ARCH" == 'amd64' ]]; then
        FILENAME="mihomo-linux-${ARCH}-compatible-${VERSION}.gz"
    elif [[ "$ARCH" =~ ^(arm64|armv7|s390x|386)$ ]]; then
        FILENAME="mihomo-linux-${ARCH}-${VERSION}.gz"
    else
        echo -e "${Red}不支持的架构：${ARCH}${Reset}"
        exit 1
    fi
    # 开始下载
    DOWNLOAD_URL="https://gh-proxy.com/https://github.com/MetaCubeX/mihomo/releases/download/Prerelease-Alpha/${FILENAME}"
    # 等待3s
    sleep 3s
    wget -t 3 -T 30 "${DOWNLOAD_URL}" -O "${FILENAME}" || { echo -e "${Red}下载失败${Reset}"; exit 1; }
    # 开始解压
    gunzip "$FILENAME" || { echo -e "${Red}解压失败${Reset}"; exit 1; }
    # 重命名
    # 移动解压后的文件
    if [[ "$ARCH" == 'amd64' ]]; then
        mv "mihomo-linux-${ARCH}-compatible-${VERSION}" mihomo || { echo -e "${Red}找不到解压后的文件${Reset}"; exit 1; }
    else
        mv "mihomo-linux-${ARCH}-${VERSION}" mihomo || { echo -e "${Red}找不到解压后的文件${Reset}"; exit 1; }
    fi
    # 授权
    chmod 755 mihomo
    # 下载 ui
    WEB_URL="https://gh-proxy.com/https://github.com/metacubex/metacubexd.git"
    git clone "$WEB_URL" -b gh-pages "$WEB_FILE" || { echo -e "${Red}管理面板下载失败${Reset}"; exit 1; }
    # 系统服务
    SYSTEM_URL="https://gh-proxy.com/https://raw.githubusercontent.com/Abcd789JK/Tools/refs/heads/main/Service/mihomo.service"
    curl -s -o "$SYSTEM_FILE" "$SYSTEM_URL" || { echo -e "${Red}系统服务下载失败${Reset}"; exit 1; }
    chmod +x "$SYSTEM_FILE"
    echo -e "${Green}mihomo 安装完成，开始配置${Reset}"
    # 下载菜单管理脚本
    sh_url="https://gh-proxy.com/https://raw.githubusercontent.com/Abcd789JK/Tools/main/Script/mihomo/mihomo.sh"
    # 删除旧的 /usr/bin/mihomo 文件
    if [ -f "/usr/bin/mihomo" ]; then
        rm /usr/bin/mihomo
    fi
    # 下载新的 mihomo 文件并移动到 /usr/bin
    wget -q -O /usr/bin/mihomo --no-check-certificate "$sh_url"
    # 赋予可执行权限
    chmod +x /usr/bin/mihomo
    # 确保 /usr/bin 在 PATH 中
    if [[ ":$PATH:" != *":/usr/bin:"* ]]; then
        export PATH=$PATH:/usr/bin
    fi
    # 刷新可执行文件缓存
    hash -r
    # 删除安装脚本
    rm -f /root/install.sh
    # 开始配置
    Config_mihomo
}

# 配置文件
Config_mihomo(){
    # 配置文件 URL
    CONFIG_URL="https://gh-proxy.com/https://raw.githubusercontent.com/Abcd789JK/Tools/refs/heads/main/Config/mihomo.yaml"
    # 下载配置文件
    curl -s -o "$CONFIG_FILE" "$CONFIG_URL"
    # 获取用户输入的机场数量，默认为 1，且限制为 5 个以内
    while true; do
        read -p "请输入需要配置的机场数量（默认 1 个，最多 5 个）：" airport_count
        airport_count=${airport_count:-1}
        # 验证输入是否为 1 到 5 之间的正整数
        if [[ "$airport_count" =~ ^[0-9]+$ ]] && [ "$airport_count" -ge 1 ] && [ "$airport_count" -le 5 ]; then
            break
        else
            echo -e "${Red}无效的数量，请输入 1 到 5 之间的正整数。${Reset}"
        fi
    done
    # 初始化 proxy-providers 部分
    proxy_providers="proxy-providers:"
    # 动态添加机场
    for ((i=1; i<=airport_count; i++))
    do
        read -p "请输入第 $i 个机场的订阅连接：" airport_url
        read -p "请输入第 $i 个机场的名称：" airport_name
        
        proxy_providers="$proxy_providers
  provider_0$i:
    url: \"$airport_url\"
    type: http
    interval: 86400
    health-check: {enable: true,url: "https://www.gstatic.com/generate_204",interval: 300}
    override:
      additional-prefix: \"[$airport_name]\""
    done
    # 使用 awk 将 proxy-providers 插入到指定位置
    awk -v providers="$proxy_providers" '
    /^# 机场配置/ {
        print
        print providers
        next
    }
    { print }
    ' "$CONFIG_FILE" > temp.yaml && mv temp.yaml "$CONFIG_FILE"
    # 提示保存位置
    echo -e "mihomo 配置已完成并保存到 ${CONFIG_FILE} 文件夹"
    # 重新加载 systemd
    systemctl daemon-reload
    systemctl start mihomo
    systemctl enable mihomo
    echo -e "${Green}已设置开机自启动${Reset}"
    # 调用函数获取
    GetLocal_ip
    # 引导语
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
