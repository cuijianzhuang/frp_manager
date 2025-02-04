#!/bin/bash

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# FRP 版本和下载链接
get_initial_version() {
    local version
    version=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
    if [ -z "$version" ]; then
        echo "0.51.3"  # 如果获取失败，使用默认版本
    else
        echo "${version#v}"  # 移除版本号前的 'v' 字符
    fi
}

FRP_VERSION=$(get_initial_version)
ARCH=$(uname -m)
case "${ARCH}" in
    x86_64) ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    *) echo "不支持的架构: ${ARCH}"; exit 1 ;;
esac

FRP_DOWNLOAD_URL="https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/frp_${FRP_VERSION}_linux_${ARCH}.tar.gz"
INSTALL_DIR="/usr/local/frp"
SERVICE_FILE="/etc/systemd/system/frps.service"

# 检查是否为root用户
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}错误: 请使用root权限运行此脚本${NC}"
        exit 1
    fi
}

# 安装FRP
install_frp() {
    check_root

    if [ -d "$INSTALL_DIR" ]; then
        echo -e "${YELLOW}FRP已经安装。如需重新安装，请先卸载。${NC}"
        return
    fi

    echo -e "${GREEN}开始安装FRP...${NC}"

    # 创建临时目录
    TMP_DIR=$(mktemp -d)
    cd $TMP_DIR

    # 下载并解压
    wget $FRP_DOWNLOAD_URL -O frp.tar.gz
    tar xzf frp.tar.gz

    # 创建安装目录
    mkdir -p $INSTALL_DIR
    cd frp_${FRP_VERSION}_linux_${ARCH}
    cp -r * $INSTALL_DIR/

    # 创建服务文件
    cat > $SERVICE_FILE << EOF
[Unit]
Description=FRP Server
After=network.target

[Service]
Type=simple
ExecStart=$INSTALL_DIR/frps -c $INSTALL_DIR/frps.ini
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    # 设置权限
    chmod 755 $SERVICE_FILE

    # 清理临时文件
    cd
    rm -rf $TMP_DIR

    echo -e "${GREEN}FRP安装完成！${NC}"
}

# 配置FRP
configure_frp() {
    check_root

    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}错误: FRP未安装${NC}"
        return
    fi

    # 创建基本配置文件
    cat > $INSTALL_DIR/frps.ini << EOF
[common]
bind_port = 7000
dashboard_port = 7500
dashboard_user = admin
dashboard_pwd = admin
token = 12345678
EOF

    echo -e "${GREEN}已创建基本配置文件，请根据需要修改 $INSTALL_DIR/frps.ini${NC}"
}

# 启动FRP
start_frp() {
    check_root

    if [ ! -f "$SERVICE_FILE" ]; then
        echo -e "${RED}错误: FRP服务文件不存在${NC}"
        return
    fi

    systemctl start frps
    systemctl enable frps
    echo -e "${GREEN}FRP服务已启动${NC}"
}

# 停止FRP
stop_frp() {
    check_root

    systemctl stop frps
    systemctl disable frps
    echo -e "${GREEN}FRP服务已停止${NC}"
}

# 重启FRP
restart_frp() {
    check_root

    systemctl restart frps
    echo -e "${GREEN}FRP服务已重启${NC}"
}

# 查看状态
status_frp() {
    systemctl status frps
}

# 删除FRP
remove_frp() {
    check_root

    systemctl stop frps
    systemctl disable frps
    rm -f $SERVICE_FILE
    rm -rf $INSTALL_DIR
    echo -e "${GREEN}FRP已完全删除${NC}"
}

# 设置开机自启动
enable_autostart() {
    check_root

    if [ ! -f "$SERVICE_FILE" ]; then
        echo -e "${RED}错误: FRP服务文件不存在${NC}"
        return
    fi

    systemctl enable frps
    echo -e "${GREEN}FRP已设置为开机自启动${NC}"
}

# 关闭开机自启动
disable_autostart() {
    check_root

    systemctl disable frps
    echo -e "${GREEN}FRP已关闭开机自启动${NC}"
}

# 获取最新版本号
get_latest_version() {
    local latest_version
    latest_version=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
    if [ -z "$latest_version" ]; then
        echo -e "${RED}获取最新版本失败${NC}"
        return 1
    fi
    echo "${latest_version#v}"  # 移除版本号前的 'v' 字符
}

# 检查更新
check_update() {
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}错误: FRP未安装${NC}"
        return 1
    fi

    local latest_version
    latest_version=$(get_latest_version)
    if [ $? -ne 0 ]; then
        return 1
    fi

    if [ "$FRP_VERSION" = "$latest_version" ]; then
        echo -e "${GREEN}当前已是最新版本 ${FRP_VERSION}${NC}"
        return 0
    else
        echo -e "${YELLOW}发现新版本: ${latest_version}${NC}"
        echo -e "当前版本: ${FRP_VERSION}"
        return 2
    fi
}

# 更新FRP
update_frp() {
    check_root

    local latest_version
    latest_version=$(get_latest_version)
    if [ $? -ne 0 ]; then
        return 1
    fi

    # 检查是否需要更新
    if [ "$FRP_VERSION" = "$latest_version" ]; then
        echo -e "${GREEN}当前已是最新版本 ${FRP_VERSION}${NC}"
        return 0
    fi

    echo -e "${GREEN}开始更新FRP...${NC}"

    # 备份配置文件
    if [ -f "$INSTALL_DIR/frps.ini" ]; then
        cp "$INSTALL_DIR/frps.ini" "/tmp/frps.ini.backup"
    fi

    # 停止服务
    systemctl stop frps

    # 下载新版本
    TMP_DIR=$(mktemp -d)
    cd $TMP_DIR

    FRP_DOWNLOAD_URL="https://github.com/fatedier/frp/releases/download/v${latest_version}/frp_${latest_version}_linux_${ARCH}.tar.gz"
    wget $FRP_DOWNLOAD_URL -O frp.tar.gz
    if [ $? -ne 0 ]; then
        echo -e "${RED}下载新版本失败${NC}"
        rm -rf $TMP_DIR
        return 1
    fi

    tar xzf frp.tar.gz

    # 更新文件
    cd frp_${latest_version}_linux_${ARCH}
    cp -r * $INSTALL_DIR/

    # 恢复配置文件
    if [ -f "/tmp/frps.ini.backup" ]; then
        mv "/tmp/frps.ini.backup" "$INSTALL_DIR/frps.ini"
    fi

    # 清理临时文件
    cd
    rm -rf $TMP_DIR

    # 更新版本号变量
    FRP_VERSION=$latest_version

    # 重启服务
    systemctl start frps

    echo -e "${GREEN}FRP已更新到版本 ${latest_version}${NC}"
}

# 重启FRP和面板服务
restart_all_services() {
    echo -e "${GREEN}重启所有服务...${NC}"
    
    # 重启FRP服务
    echo -e "${GREEN}1. 重启FRP服务...${NC}"
    systemctl restart frps
    if [ $? -ne 0 ]; then
        echo -e "${RED}FRP服务重启失败${NC}"
    else
        echo -e "${GREEN}FRP服务已重启${NC}"
    fi

    # 重启Web面板服务
    echo -e "${GREEN}2. 重启Web管理面板...${NC}"
    systemctl restart frp-panel
    if [ $? -ne 0 ]; then
        echo -e "${RED}Web管理面板重启失败${NC}"
    else
        echo -e "${GREEN}Web管理面板已重启${NC}"
    fi
}

# 安装管理面板依赖
install_panel_deps() {
    check_root

    # 检查是否已安装
    if [ -d "/usr/local/frp-panel" ]; then
        echo -e "${YELLOW}Web管理面板已安装。如需重新安装，请先删除现有安装。${NC}"
        echo -e "${YELLOW}您可以使用选项13来检查更新。${NC}"
        return 1
    fi

    # 安装Node.js和npm
    if ! command -v node &> /dev/null; then
        echo -e "${GREEN}正在安装Node.js...${NC}"
        curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
        apt-get install -y nodejs
    fi

    # 创建面板目录
    echo -e "${GREEN}1. 创建面板目录...${NC}"
    mkdir -p /usr/local/frp-panel

    # 克隆最新代码
    echo -e "${GREEN}2. 下载面板文件...${NC}"
    TMP_DIR=$(mktemp -d)
    cd $TMP_DIR || exit

    git clone --depth 1 https://github.com/cuijianzhuang/frp_manager.git
    if [ $? -ne 0 ]; then
        echo -e "${RED}下载面板文件失败${NC}"
        rm -rf $TMP_DIR
        return 1
    fi

    # 复制面板文件
    cp -r frp_manager/frp_panel/* /usr/local/frp-panel/
    rm -rf $TMP_DIR

    # 生成随机密码
    RANDOM_PASSWORD=$(openssl rand -base64 12)

    # 创建.env文件
    echo -e "${GREEN}3. 创建配置文件...${NC}"
    cat > /usr/local/frp-panel/.env << EOF
ADMIN_USER=admin
ADMIN_PASSWORD=$RANDOM_PASSWORD
PORT=3000
EOF

    # 安装依赖
    echo -e "${GREEN}4. 安装依赖包...${NC}"
    cd /usr/local/frp-panel
    npm install --production
    
    # 确保Chart.js正确安装
    if [ ! -f "node_modules/chart.js/dist/chart.umd.js" ]; then
        echo -e "${GREEN}安装Chart.js...${NC}"
        npm install chart.js@latest
    fi

    # 创建服务文件
    echo -e "${GREEN}5. 创建服务...${NC}"
    cat > /etc/systemd/system/frp-panel.service << EOF
[Unit]
Description=FRP Web Panel
After=network.target

[Service]
Type=simple
WorkingDirectory=/usr/local/frp-panel
ExecStart=/usr/bin/node app.js
Restart=always
RestartSec=5
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable frp-panel

    # 重启所有服务
    restart_all_services

    echo -e "${GREEN}Web管理面板安装完成！${NC}"
    echo -e "${GREEN}访问地址: http://your-ip::3000${NC}"
    echo -e "${GREEN}用户名: admin${NC}"
    echo -e "${GREEN}密码: $RANDOM_PASSWORD${NC}"
    echo -e "${YELLOW}请保存好以上登录信息！${NC}"
}

# 检查git是否安装
check_git() {
    if ! command -v git &> /dev/null; then
        echo -e "${YELLOW}正在安装git...${NC}"
        if command -v apt &> /dev/null; then
            apt update && apt install -y git
        elif command -v yum &> /dev/null; then
            yum install -y git
        else
            echo -e "${RED}无法安装git，请手动安装${NC}"
            return 1
        fi
    fi
    return 0
}

# 删除Web管理面板
remove_panel() {
    check_root

    if [ ! -d "/usr/local/frp-panel" ]; then
        echo -e "${RED}错误: Web管理面板未安装${NC}"
        return 1
    fi

    echo -e "${YELLOW}警告: 此操作将完全删除Web管理面板及其所有数据${NC}"
    read -p "是否继续？(y/n): " confirm
    if [ "$confirm" != "y" ]; then
        echo -e "${GREEN}操作已取消${NC}"
        return 0
    fi

    echo -e "${GREEN}开始删除Web管理面板...${NC}"

    # 停止服务
    echo -e "${GREEN}1. 停止Web管理面板服务...${NC}"
    systemctl stop frp-panel
    systemctl disable frp-panel
    
    # 删除服务文件
    echo -e "${GREEN}2. 删除服务文件...${NC}"
    rm -f /etc/systemd/system/frp-panel.service
    systemctl daemon-reload

    # 备份配置文件
    if [ -f "/usr/local/frp-panel/.env" ]; then
        echo -e "${GREEN}3. 备份配置文件到 /root/frp-panel-backup/...${NC}"
        mkdir -p /root/frp-panel-backup
        cp "/usr/local/frp-panel/.env" "/root/frp-panel-backup/.env.backup-$(date +%Y%m%d%H%M%S)"
        echo -e "${GREEN}配置文件已备份到 /root/frp-panel-backup/.env.backup-$(date +%Y%m%d%H%M%S)${NC}"
    fi

    # 删除面板目录
    echo -e "${GREEN}4. 删除面板文件...${NC}"
    rm -rf /usr/local/frp-panel

    echo -e "${GREEN}Web管理面板已完全删除！${NC}"
    if [ -d "/root/frp-panel-backup" ]; then
        echo -e "${YELLOW}配置文件备份保存在 /root/frp-panel-backup/${NC}"
    fi
}

# 检查Web面板更新
check_panel_update() {
    check_root
    
    if [ ! -d "/usr/local/frp-panel" ]; then
        echo -e "${RED}错误: Web面板未安装${NC}"
        return 1
    }

    echo -e "${GREEN}正在检查Web面板更新...${NC}"
    
    # 创建临时目录
    TMP_DIR=$(mktemp -d)
    cd $TMP_DIR

    # 克隆最新代码
    git clone --depth 1 https://github.com/cuijianzhuang/frp_manager.git
    if [ $? -ne 0 ]; then
        echo -e "${RED}检查更新失败${NC}"
        rm -rf $TMP_DIR
        return 1
    }

    # 比较版本
    CURRENT_VERSION=$(cat /usr/local/frp-panel/version.txt 2>/dev/null || echo "0.0.0")
    NEW_VERSION=$(cat frp_manager/frp_panel/version.txt 2>/dev/null || echo "0.0.0")

    if [ "$CURRENT_VERSION" = "$NEW_VERSION" ]; then
        echo -e "${GREEN}当前已是最新版本 ${CURRENT_VERSION}${NC}"
        rm -rf $TMP_DIR
        return 0
    else
        echo -e "${YELLOW}发现新版本: ${NEW_VERSION}${NC}"
        echo -e "当前版本: ${CURRENT_VERSION}"
        rm -rf $TMP_DIR
        return 2
    fi
}

# 更新Web面板
update_panel() {
    check_root

    if [ ! -d "/usr/local/frp-panel" ]; then
        echo -e "${RED}错误: Web面板未安装${NC}"
        return 1
    }

    echo -e "${GREEN}开始更新Web面板...${NC}"

    # 创建临时目录
    TMP_DIR=$(mktemp -d)
    cd $TMP_DIR

    # 克隆最新代码
    git clone --depth 1 https://github.com/cuijianzhuang/frp_manager.git
    if [ $? -ne 0 ]; then
        echo -e "${RED}下载更新失败${NC}"
        rm -rf $TMP_DIR
        return 1
    }

    # 备份当前配置
    if [ -f "/usr/local/frp-panel/.env" ]; then
        cp "/usr/local/frp-panel/.env" "/tmp/frp-panel.env.backup"
    fi

    # 停止服务
    systemctl stop frp-panel

    # 更新文件
    cp -r frp_manager/frp_panel/* /usr/local/frp-panel/

    # 恢复配置文件
    if [ -f "/tmp/frp-panel.env.backup" ]; then
        mv "/tmp/frp-panel.env.backup" "/usr/local/frp-panel/.env"
    fi

    # 更新依赖
    cd /usr/local/frp-panel
    npm install --production

    # 确保Chart.js正确安装
    if [ ! -f "node_modules/chart.js/dist/chart.umd.js" ]; then
        echo -e "${GREEN}安装Chart.js...${NC}"
        npm install chart.js@latest
    fi

    # 清理临时文件
    rm -rf $TMP_DIR

    # 重启服务
    systemctl restart frp-panel

    echo -e "${GREEN}Web面板更新完成！${NC}"
}

# 主菜单
show_menu() {
    clear
    echo "============================"
    echo "    FRP 服务器管理脚本     "
    echo "============================"
    echo "1. 安装 FRP"
    echo "2. 配置 FRP"
    echo "3. 启动 FRP"
    echo "4. 停止 FRP"
    echo "5. 重启 FRP"
    echo "6. 查看状态"
    echo "7. 删除 FRP"
    echo "8. 设置开机自启动"
    echo "9. 关闭开机自启动"
    echo "10. 检查FRP更新"
    echo "11. 更新FRP"
    echo "12. 安装Web管理面板"
    echo "13. 删除Web管理面板"
    echo "14. 检查面板更新"
    echo "15. 更新Web面板"
    echo "0. 退出"
    echo "============================"
}

# 主循环
main() {
    while true; do
        show_menu
        read -p "请输入选项 [0-15]: " choice

        case $choice in
            1) install_frp ;;
            2) configure_frp ;;
            3) start_frp ;;
            4) stop_frp ;;
            5) restart_frp ;;
            6) status_frp ;;
            7) remove_frp ;;
            8) enable_autostart ;;
            9) disable_autostart ;;
            10) check_update ;;
            11) update_frp ;;
            12) install_panel_deps ;;
            13) remove_panel ;;
            14) check_panel_update ;;
            15) update_panel ;;
            0) exit 0 ;;
            *) echo -e "${RED}无效的选项${NC}" ;;
        esac

        echo
        read -p "按回车键继续..."
    done
}

# 运行主程序
main