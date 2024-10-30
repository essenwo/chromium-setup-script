

#!/bin/bash

# 错误处理
trap 'echo "发生错误，正在清理..." && docker compose down' ERR

# 检查并配置 Docker
configure_docker() {
   if ! command -v docker &> /dev/null || ! docker info &> /dev/null; then
       echo "Docker 未安装或未启动，正在安装..."
       sudo apt update -y && sudo apt upgrade -y
       sudo apt-get remove -y docker.io docker-doc docker-compose podman-docker containerd runc
       sudo apt-get install -y ca-certificates curl gnupg
   else
       echo "Docker 已安装，跳过安装步骤，直接配置仓库。"
   fi

   sudo install -m 0755 -d /etc/apt/keyrings
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
   sudo chmod a+r /etc/apt/keyrings/docker.gpg

   echo \
   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
   $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

   sudo apt update -y
   sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
   echo "Docker 配置完成，版本为: $(docker --version)"
}

# 检查端口占用
check_ports() {
   local ports=(3010 3011)
   for port in "${ports[@]}"; do
       if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
           echo "错误: 端口 $port 已被占用"
           exit 1
       fi
   done
}

# 获取用户凭据
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

   read -sp "请再次输入 PASSWORD 确认: " PASSWORD2
   echo
   if [ "$PASSWORD" != "$PASSWORD2" ]; then
       echo "两次密码输入不一致"
       exit 1
   fi
}

# 创建 docker-compose.yaml
create_docker_compose() {
   cat <<EOF > docker-compose.yaml
version: '3'

networks:
 chromium_net:
   driver: bridge

services:
 chromium:
   image: lscr.io/linuxserver/chromium:latest
   container_name: chromium
   environment:
     - CUSTOM_USER=$CUSTOM_USER
     - PASSWORD=$PASSWORD
     - PUID=1000
     - PGID=1000
     - TZ=Asia/Shanghai
     - DISPLAY=:1
   volumes:
     - $HOME/chromium/config:/config
   ports:
     - "3010:3000"
     - "3011:3001"
   shm_size: "2gb"
   security_opt:
     - seccomp=unconfined
   networks:
     - chromium_net
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
   echo "用户名: $CUSTOM_USER"
}

# 主函数
main() {
   configure_docker
   mkdir -p $HOME/chromium && cd $HOME/chromium
   check_ports
   get_user_credentials
   create_docker_compose
   start_docker_compose
}

main
