
# 主菜单
Main() {
    clear
    echo "================================="
    echo -e "${Green}欢迎使用 mihomo 一键脚本 Beta 版${Reset}"
    echo -e "${Green}作者：${Yellow}AdsJK567${Reset}"
    echo -e "${Red}请保证科学上网已经开启${Reset}"
    echo -e "${Red}安装过程中可以按 ctrl+c 强制退出${Reset}"
    echo "================================="
    echo -e "${Green} 0${Reset}. 更新脚本"
    echo "---------------------------------"
    echo -e "${Green} 1${Reset}. 安装 mihomo"
    echo -e "${Green} 2${Reset}. 更新 mihomo"
    echo -e "${Green} 3${Reset}. 卸载 mihomo"
    echo "---------------------------------"
    echo -e "${Green} 4${Reset}. 启动 mihomo"
    echo -e "${Green} 5${Reset}. 停止 mihomo"
    echo -e "${Green} 6${Reset}. 重启 mihomo"
    echo "---------------------------------"
    echo -e "${Green} 7${Reset}. 更换订阅"
    echo -e "${Green} 8${Reset}. 更换面板"
    echo -e "${Green}10${Reset}. 退出脚本"
    echo "================================="
    Show_Status
    echo "================================="
    read -p "请输入选项[0-8]：" num
    case "$num" in
        1) Install ;;
        2) Update ;;
        3) Uninstall ;;
        4) Start ;;
        5) Stop ;;
        6) Restart ;;
        7) Configure ;;
        8) Panel ;;
        10) exit 0 ;;
        0) Update_Shell ;;
        *) echo -e "${Red}无效选项，请重新选择${Reset}" 
           exit 1 ;;
    esac
}

# 启动主菜单
Main
