#!/bin/bash
# 错误处理
trap 'echo "发生错误，正在清理..." && docker-compose down' ERR

# 生成随机密码
generate_password() {
    tr -dc 'A-Za-z0-9!#$%&()*+,-./:;<=>?@[\]^_' < /dev/urandom | head -c 10
}

# 检查并配置 Docker
configure_docker() {
    if ! command -v docker &> /dev/null || ! docker info &> /dev/null; then
        echo "Docker 未安装或未启动，正在安装..."
        sudo apt update -y && sudo apt upgrade -y
        sudo apt-get remove -y docker.io docker-doc docker-compose podman-docker containerd runc
        sudo apt-get install -y ca-certificates curl gnupg
        
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt update -y
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    else
        echo "Docker 已安装，跳过安装步骤。"
    fi
}

# 创建配置文件
create_config() {
    mkdir -p ~/chromium && cd ~/chromium
    
    # 生成随机密码
    RANDOM_PASSWORD=$(generate_password)
    
    cat <<EOF > docker-compose.yaml
services:
  chromium:
    image: lscr.io/linuxserver/chromium:latest
    container_name: chromium
    environment:
      - CUSTOM_USER=admin
      - PASSWORD=$RANDOM_PASSWORD
      - PUID=0
      - PGID=0
      - TZ=Asia/Shanghai
      - DISPLAY=:1
      - DISPLAY_WIDTH=1920
      - DISPLAY_HEIGHT=1080
      - CUSTOM_QUALITY=100
      - CUSTOM_COMPRESSION=0
      - CUSTOM_FPS=60
      - ENABLE_OPENBOX=false
      - CUSTOM_PORT=3000
      - CUSTOM_HTTPS_PORT=3001
      - CHROME_CLI=--no-sandbox --disable-gpu --disable-dev-shm-usage --ignore-certificate-errors --start-maximized --default-browser-check --homepage https://chrome.google.com/webstore
      - VNC_RESIZE=scale
      - CUSTOM_RES_W=1920
      - CUSTOM_RES_H=1080
      - NOVNC_HEARTBEAT=30
      - VNC_VIEW_ONLY=0
      - CUSTOM_WEBRTC_FPS=30
      - BASE_URL=/
      - DRINODE=/dev/dri/renderD128
      - LANG=zh_CN.UTF-8
      - LANGUAGE=zh_CN:zh
      - LC_ALL=zh_CN.UTF-8
      - ENABLE_CJK_IME=true
      - ENABLE_CLIPBOARD=true
      - CLIPBOARD_COPY=true
      - CLIPBOARD_PASTE=true
      - ENABLE_KEYBOARD=true
      - KEYBOARD=zh-CN
    volumes:
      - ./config:/config
      - /dev/shm:/dev/shm
    ports:
      - "3020:3000"
      - "3021:3001"
    shm_size: "4gb"
    privileged: true
    security_opt:
      - seccomp=unconfined
    cap_add:
      - NET_ADMIN
      - SYS_ADMIN
    restart: unless-stopped
EOF
    mkdir -p config
    
    # 保存密码到文件
    echo "用户名: admin" > ~/chromium/login_info.txt
    echo "密码: $RANDOM_PASSWORD" >> ~/chromium/login_info.txt
    chmod 600 ~/chromium/login_info.txt
}

# 启动服务
start_service() {
    docker-compose up -d
    if [ $? -eq 0 ]; then
        echo "服务启动成功！"
        IP=$(hostname -I | awk '{print $1}')
        echo "请等待 30 秒后访问: http://$IP:3020"
        echo "登录信息已保存在 ~/chromium/login_info.txt"
        cat ~/chromium/login_info.txt
        echo "注意："
        echo "1. 首次启动可能需要等待1-2分钟才能完全加载"
        echo "2. 中文输入法可能需要在浏览器设置中启用"
        echo "3. 如需使用跨设备剪贴板，请允许浏览器的剪贴板访问权限"
    else
        echo "服务启动失败，请检查日志。"
        exit 1
    fi
}

# 主函数
main() {
    echo "开始安装远程浏览器服务..."
    configure_docker
    create_config
    start_service
}

# 执行主函数
main
