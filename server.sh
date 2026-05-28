#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

D="$PWD/data"; COMPOSE="docker compose"; SUDO=""
[ "${EUID:-$(id -u)}" -ne 0 ] && SUDO="sudo"

server_ip(){ hostname -I 2>/dev/null | awk '{print $1}';}
rand(){ openssl rand -base64 24 | tr -d '=+/';}

mkfiles(){
  mkdir -p "$D"/{wg-easy,homeassistant,ollama,jellyfin/{config,cache},nextcloud/{html,data,db},minecraft,ntfy/{cache,etc}}
  [ -f .env ] || cat > .env <<EOF
TZ=Europe/London
SERVER_IP=$(server_ip)
WG_PORT=51820
WG_PORTAL_PORT=51821
WG_SERVER_VPN_IP=10.8.0.1
WG_SUBNET=10.8.0.0/24
MYSQL_DATABASE=nextcloud
MYSQL_USER=nextcloud
MYSQL_PASSWORD=$(rand)
MYSQL_ROOT_PASSWORD=$(rand)
MINECRAFT_EULA=TRUE
EOF

  grep -q '^SERVER_IP=' .env || echo "SERVER_IP=$(server_ip)" >> .env
  grep -q '^TZ=' .env || echo "TZ=Europe/London" >> .env
  grep -q '^WG_PORT=' .env || echo "WG_PORT=51820" >> .env
  grep -q '^WG_PORTAL_PORT=' .env || echo "WG_PORTAL_PORT=51821" >> .env
  grep -q '^WG_SERVER_VPN_IP=' .env || echo "WG_SERVER_VPN_IP=10.8.0.1" >> .env
  grep -q '^WG_SUBNET=' .env || echo "WG_SUBNET=10.8.0.0/24" >> .env

  [ -f "$D/homeassistant/configuration.yaml" ] || cat > "$D/homeassistant/configuration.yaml" <<'EOF'
default_config:
http:
  use_x_forwarded_for: false
EOF

  cat > docker-compose.yml <<'EOF'
services:
  wg-easy:
    image: ghcr.io/wg-easy/wg-easy:15
    container_name: wg-easy
    restart: unless-stopped
    ports:
      - "51820:51820/udp"
      - "51821:51821/tcp"
    volumes:
      - ./data/wg-easy:/etc/wireguard
      - /lib/modules:/lib/modules:ro
    cap_add: [NET_ADMIN, SYS_MODULE]
    sysctls:
      - net.ipv4.ip_forward=1
      - net.ipv4.conf.all.src_valid_mark=1
    networks: [server]

  homeassistant:
    image: ghcr.io/home-assistant/home-assistant:stable
    container_name: homeassistant
    restart: unless-stopped
    ports: ["8123:8123"]
    volumes: ["./data/homeassistant:/config"]
    environment: ["TZ=${TZ}"]
    networks: [server]

  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    restart: unless-stopped
    ports: ["11434:11434"]
    volumes: ["./data/ollama:/root/.ollama"]
    networks: [server]

  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    restart: unless-stopped
    ports: ["8096:8096"]
    volumes:
      - ./data/jellyfin/config:/config
      - ./data/jellyfin/cache:/cache
      - ./data/nextcloud/data:/media/nextcloud:ro
    networks: [server]

  nextcloud-db:
    image: mariadb:11
    container_name: nextcloud-db
    restart: unless-stopped
    command: --transaction-isolation=READ-COMMITTED --binlog-format=ROW
    volumes: ["./data/nextcloud/db:/var/lib/mysql"]
    environment:
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
    networks: [server]

  nextcloud:
    image: nextcloud:apache
    container_name: nextcloud
    restart: unless-stopped
    depends_on: [nextcloud-db]
    ports: ["8080:80"]
    volumes:
      - ./data/nextcloud/html:/var/www/html
      - ./data/nextcloud/data:/var/www/html/data
    environment:
      - MYSQL_HOST=nextcloud-db
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - NEXTCLOUD_TRUSTED_DOMAINS=${SERVER_IP} localhost
      - OVERWRITEHOST=${SERVER_IP}:8080
      - OVERWRITEPROTOCOL=http
    networks: [server]

  minecraft:
    image: itzg/minecraft-server:latest
    container_name: minecraft
    restart: unless-stopped
    ports: ["25565:25565"]
    volumes: ["./data/minecraft:/data"]
    environment:
      - EULA=${MINECRAFT_EULA}
      - TYPE=PAPER
      - MEMORY=4G
    networks: [server]

  ntfy:
    image: binwiederhier/ntfy:latest
    container_name: ntfy
    restart: unless-stopped
    command: serve
    ports: ["8081:80"]
    volumes:
      - ./data/ntfy/cache:/var/cache/ntfy
      - ./data/ntfy/etc:/etc/ntfy
    networks: [server]

networks:
  server:
    name: server
EOF
}

ubuntu_update(){ $SUDO apt update && $SUDO apt -y full-upgrade && $SUDO apt -y autoremove; pause}

install_stack(){
  $SUDO apt update
  $SUDO apt -y install ca-certificates curl gnupg lsb-release openssl acl
  if ! command -v docker >/dev/null; then
    $SUDO install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO tee /etc/apt/keyrings/docker.asc >/dev/null
    $SUDO chmod a+r /etc/apt/keyrings/docker.asc
    . /etc/os-release
    echo "Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${UBUNTU_CODENAME:-$VERSION_CODENAME}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc" | $SUDO tee /etc/apt/sources.list.d/docker.sources >/dev/null
  fi
  $SUDO apt update
  $SUDO apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  $SUDO systemctl enable --now docker
  getent group docker >/dev/null && $SUDO usermod -aG docker "$USER" || true
  mkfiles
  echo "Docker installed and files created. Edit .env, set MINECRAFT_EULA=TRUE, then start containers."
  pause
}

up(){ mkfiles; $SUDO systemctl enable --now docker >/dev/null 2>&1 || true; $COMPOSE up -d; urls; pause}
down(){ $COMPOSE down; pause}
restart(){ $COMPOSE down; $COMPOSE up -d; urls; pause}
info(){ $SUDO systemctl start docker >/dev/null 2>&1 || true; $COMPOSE ps || true; pause}

fixes(){
  $SUDO apt -y install acl
  mkdir -p "$D/nextcloud/data"
  $SUDO setfacl -R -m u:${USER}:rX "$D/nextcloud/data" || true
  $SUDO setfacl -R -d -m u:${USER}:rX "$D/nextcloud/data" || true
  $COMPOSE up -d jellyfin nextcloud || true
  echo "Nextcloud data is mounted read-only in Jellyfin at /media/nextcloud."
  pause
}

urls(){
  IP="$(server_ip)"
  [ -f .env ] && . ./.env 2>/dev/null || true
  IP="${SERVER_IP:-$IP}"
  WG_PORT="${WG_PORT:-51820}"
  WG_PORTAL_PORT="${WG_PORTAL_PORT:-51821}"
  WG_SERVER_VPN_IP="${WG_SERVER_VPN_IP:-10.8.0.1}"
  WG_SUBNET="${WG_SUBNET:-10.8.0.0/24}"

  cat <<EOF

Useful server information:

  Ubuntu Server LAN IP:     $IP
  WireGuard Server VPN IP:  $WG_SERVER_VPN_IP
  WireGuard VPN Subnet:     $WG_SUBNET

Local / VPN web links:

  WG-Easy Portal:           http://$IP:$WG_PORTAL_PORT
  Home Assistant:           http://$IP:8123
  Jellyfin:                 http://$IP:8096
  Nextcloud:                http://$IP:8080
  ntfy:                     http://$IP:8081
  Ollama API:               http://$IP:11434
  Minecraft Server:         $IP:25565

Phone / remote access:

  1. Connect your phone to WireGuard.
  2. Open the same private URLs above.
  3. SSH to the Ubuntu PC using either:

     ssh $USER@$IP
     ssh $USER@$WG_SERVER_VPN_IP

Router port forwarding:

  Forward this only:

    UDP $WG_PORT -> $IP:$WG_PORT

EOF
  pause
}

setupguide(){
  echo "TBD"
  pause
}

pause(){
  echo
  read -rp "Press Enter to return to the menu..."
  clear
}

menu(){
  while true; do
    printf 'Server Menu\n\n1. Update Ubuntu\n2. Install/Update Docker\n3. Start Containers\n4. Stop Containers\n5. Restart Containers\n6. Container Info\n7. Apply Container Fixes\n8. Show App URLs\n9. Setup Guide\n0 Exit\n> '
    read -r c
    case "$c" in
      1) ubuntu_update;;
      2) install_stack;;
      3) up;;
      4) down;;
      5) restart;;
      6) info;;
      7) fixes;;
      8) urls;;
	  9) setupguide;;
      0) exit;;
      *) echo "Invalid"; pause;;
    esac
  done
}

clear
menu
