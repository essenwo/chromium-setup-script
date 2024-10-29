#!/bin/bash

# 检查并配置 Docker
configure_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Docker 未安装，正在安装..."

        # 更新系统并安装必要包
        sudo apt update -y && sudo apt upgrade -y
        sudo apt-get remove -y docker.io docker-doc docker-compose podman-docker containerd runc
        sudo apt-get install -y ca-certificates curl gnupg
    else
        echo "Docker 已安装，跳过安装步骤，直接配置仓库。"
    fi

    # 添加 Docker GPG 密钥并配置 Docker 仓库
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # 添加 Docker 源
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # 安装 Docker（如果尚未安装）
    sudo apt update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "Docker 配置完成，版本为: $(docker --version)"
}

# 获取用户自定义的用户名和密码
get_user_credentials() {
    read -p "请输入 CUSTOM_USER: " CUSTOM_USER
    if [ -z "$CUSTOM_USER" ]; then
        echo "CUSTOM_USER 不能为空。"
        exit 1
    fi

    read -sp "请输入 PASSWORD: " PASSWORD
    echo
    if [ -z "$PASSWORD" ]; then
        echo "PASSWORD 不能为空。"
        exit 1
    fi
}

# 创建 docker-compose.yaml 文件
create_docker_compose() {
    cat <<EOF > docker-compose.yaml
version: '3'
services:
  chromium:
    image: lscr.io/linuxserver/chromium:latest
    container_name: chromium
    environment:
      - CUSTOM_USER=$CUSTOM_USER
      - PASSWORD=$PASSWORD
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
    volumes:
      - $HOME/chromium/config:/config
    ports:
      - "3010:3000"
      - "3011:3001"
    shm_size: "2gb"  # 增加共享内存大小，防止浏览器崩溃
    command: --no-sandbox  # 使用无沙盒模式，避免权限问题
    restart: unless-stopped
EOF
    echo "docker-compose.yaml 文件已创建。"
}

# 启动 Docker Compose
start_docker_compose() {
    if ! docker compose up -d; then
        echo "Docker Compose 启动失败。"
        exit 1
    fi

    SERVER_IP=$(hostname -I | awk '{print $1}')
    echo "Docker Compose 已启动。"
    echo "您可以通过以下链接访问服务："
    echo "http://$SERVER_IP:3010/"
    echo "或"
    echo "http://$SERVER_IP:3011/"
}

# 主函数
main() {
    configure_docker
    mkdir -p $HOME/chromium && cd $HOME/chromium
    get_user_credentials
    create_docker_compose
    start_docker_compose
}

main
