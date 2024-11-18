#!/bin/bash

# === 脚本信息 ===
echo "----------------------------------------------------"
echo "SSL 证书安装脚本 - 使用 acme.sh 通过 Cloudflare DNS 申请证书"
echo "----------------------------------------------------"

# === 检查是否以 root 用户运行 ===
if [ "$(id -u)" -ne 0 ]; then
  echo "错误：请使用 root 权限运行此脚本！"
  exit 1
fi

# === 用户输入部分 ===
# 获取 Cloudflare API token、账号 ID 和域名
read -p "请输入你的 Cloudflare API Token: " CF_Token
if [ -z "$CF_Token" ]; then
  echo "错误：API Token 不能为空！"
  exit 1
fi

read -p "请输入你的 Cloudflare 账号 ID: " CF_Account_ID
if [ -z "$CF_Account_ID" ]; then
  echo "错误：Cloudflare 账号 ID 不能为空！"
  exit 1
fi

read -p "请输入你要申请证书的域名: " DOMAIN
if [ -z "$DOMAIN" ]; then
  echo "错误：域名不能为空！"
  exit 1
fi

# 选择证书颁发机构
echo "请选择证书颁发机构 (CA)："
echo "1. Let’s Encrypt"
echo "2. Buypass"
echo "3. ZeroSSL"
read -p "请输入数字选择证书颁发机构 [1/2/3]： " CA_Choice
case $CA_Choice in
  1)
    echo "切换至 Let’s Encrypt..."
    acme.sh --set-default-ca --server letsencrypt
    ;;
  2)
    echo "切换至 Buypass..."
    acme.sh --set-default-ca --server buypass
    ;;
  3)
    echo "切换至 ZeroSSL..."
    acme.sh --set-default-ca --server zerossl

    # 自动注册 ZeroSSL 账户
    read -p "请输入你的电子邮件地址以注册 ZeroSSL 账户: " EMAIL
    if [ -z "$EMAIL" ]; then
      echo "错误：电子邮件地址不能为空！"
      exit 1
    fi
    echo "正在注册 ZeroSSL 账户..."
    acme.sh --register-account -m "$EMAIL" --server zerossl
    if [ $? -ne 0 ]; then
      echo "错误：ZeroSSL 账户注册失败！"
      exit 1
    fi
    ;;
  *)
    echo "无效选择，使用默认的证书颁发机构 Let’s Encrypt。"
    acme.sh --set-default-ca --server letsencrypt
    ;;
esac

# === 安装前检查 ===
echo "正在检查系统更新和安装依赖..."

# 更新包列表并安装依赖
apt update -y
apt install -y socat curl

# 安装 acme.sh
install_acme() {
  echo "正在安装 acme.sh..."
  curl https://get.acme.sh | sh
  if [ $? -ne 0 ]; then
    echo "错误：acme.sh 安装失败！"
    exit 1
  fi
}

# 安装证书
install_cert() {
  echo "正在申请证书..."
  acme.sh --issue --dns dns_cf -d "$DOMAIN"
  if [ $? -ne 0 ]; then
    echo "错误：证书申请失败！"
    exit 1
  fi
}

# 安装证书到指定目录
install_ssl_cert() {
  echo "正在安装证书..."
  mkdir -p /root/ssl
  acme.sh --install-cert -d "$DOMAIN" \
    --key-file /root/ssl/server.key \
    --fullchain-file /root/ssl/server.crt
  if [ $? -ne 0 ]; then
    echo "错误：证书安装失败！"
    exit 1
  fi
}

# === 安装和配置流程 ===
install_acme

# 设置 Cloudflare API token 和账号 ID
echo "正在设置 Cloudflare 环境变量..."
export CF_Token="$CF_Token"
export CF_Account_ID="$CF_Account_ID"

# 申请并安装证书
install_cert
install_ssl_cert

# === 完成提示 ===
echo "----------------------------------------------------"
echo "证书安装成功！证书已安装至 /root/ssl/ 目录。"
echo "----------------------------------------------------"
