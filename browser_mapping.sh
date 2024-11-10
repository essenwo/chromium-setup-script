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
      - ENABLE_OPENBOX=true
      - CUSTOM_PORT=3000
      - CUSTOM_HTTPS_PORT=3001
      - CHROME_CLI=--disable-dev-shm-usage --no-sandbox --disable-gpu --ignore-certificate-errors
      - VNC_RESIZE=scale
      - CUSTOM_RES_W=1920
      - CUSTOM_RES_H=1080
      - NOVNC_HEARTBEAT=30
      - VNC_VIEW_ONLY=0
      - CUSTOM_WEBRTC_FPS=30
      - BASE_URL=/
      - ENABLE_CLIPBOARD=true
      - ENABLE_SYNC_CLIPBOARD=true
      - KASMVNC_CLIPBOARD_LIMIT=268435456
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
