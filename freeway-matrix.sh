#!/usr/bin/env bash

trap 'tput cnorm; clear; exit' INT
tput civis
clear

C=$(tput cols)
R=$(tput lines)
W="FreeWay"
N=${#W}

if [ "$N" -gt "$C" ]; then
  SX=0
  G=1
else
  TG=$((C - N))
  SX=$((TG/2))
  G=2
fi

declare -A H
for (( i=0; i<N; i++ )); do
  H[$i]=0
done

f() {
  printf "\033[35m%s\033[0m" "$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c1)"
}

FR=$((R/2))

while true; do
  doneflag=true
  for (( i=0; i<N; i++ )); do
    c=${H[$i]}
    if [ "$c" -ge "$FR" ]; then
      continue
    fi
    X=$((SX + i*G))
    if [ "$X" -ge 0 ] && [ "$X" -lt "$C" ]; then
      tput cup "$c" "$X"
      f
    fi
    H[$i]=$((c+1))
    doneflag=false
  done
  if $doneflag; then
    break
  fi
  sleep 0.03
done

for (( y=0; y<FR; y++ )); do
  tput cup "$y" 0
  printf "%${C}s" " "
done

ASCII_FREEWAY="
░▒▓████████▓▒░▒▓███████▓▒░░▒▓████████▓▒░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░
░▒▓██████▓▒░ ░▒▓███████▓▒░░▒▓██████▓▒░ ░▒▓██████▓▒░ ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓████████▓▒░░▒▓██████▓▒░
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░  ░▒▓█▓▒░
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░  ░▒▓█▓▒░
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓████████▓▒░▒▓████████▓▒░░▒▓█████████████▓▒░░▒▓█▓▒░░▒▓█▓▒░  ░▒▓█▓▒░
"

tput cup "$FR" 0
echo -e "\033[35m$ASCII_FREEWAY\033[0m"

sleep 2
tput cnorm
echo
echo "Created by Kenig01"
sleep 2
clear

set -e
echo "=== Установка необходимых пакетов: Docker, Docker Compose, ufw, certbot ==="
sudo apt-get update
sudo apt-get install -y docker.io docker-compose ufw certbot

echo
read -rp "Введите домен (пример: matrix.example.com): " DOMAIN
if [ -z "$DOMAIN" ]; then
  echo "Домен не может быть пустым!"
  exit 1
fi

read -rp "Введите e-mail (пример: mail@example.com): " EMAIL
if [ -z "$EMAIL" ]; then
  echo "E-mail не может быть пустым!"
  exit 1
fi

echo
echo "Открываем порты 22, 80, 443, 8008, 8448"
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8008/tcp
sudo ufw allow 8448/tcp

UF=$(sudo ufw status | head -n1)
if [[ "$UF" == "Status: inactive" ]]; then
  sudo ufw enable
fi

echo
echo "Убедитесь, что никакой другой сервис не слушает порт 80"
read -rp "Нажмите Enter для продолжения..."

sudo certbot certonly --standalone -m "$EMAIL" --agree-tos -d "$DOMAIN"

echo
mkdir -p ~/matrix-nginx
cd ~/matrix-nginx

echo "=== Создаём docker-compose.yml ==="
cat > docker-compose.yml <<EOF
version: '3.7'
services:
  synapse:
    image: matrixdotorg/synapse:latest
    container_name: synapse
    volumes:
      - ./synapse-data:/data
    environment:
      - SYNAPSE_SERVER_NAME=${DOMAIN}
      - SYNAPSE_REPORT_STATS=no
    command: generate
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    container_name: nginx-reverse-proxy
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - /etc/letsencrypt/live/${DOMAIN}:/etc/letsencrypt/live/${DOMAIN}:ro
      - /etc/letsencrypt/archive/${DOMAIN}:/etc/letsencrypt/archive/${DOMAIN}:ro
    depends_on:
      - synapse
    restart: unless-stopped
EOF

echo
echo "=== Создаём nginx.conf ==="
cat > nginx.conf <<EOF
worker_processes  1;
events {
    worker_connections 1024;
}
http {
    server {
        listen 443 ssl;
        server_name ${DOMAIN};
        ssl_certificate     /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
        location / {
            proxy_pass http://synapse:8008;
            proxy_http_version 1.1;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
    server {
        listen 80;
        server_name ${DOMAIN};
        location / {
            return 301 https://\$host\$request_uri;
        }
    }
}
EOF

echo "=== Генерация homeserver.yaml ==="
docker-compose run --rm synapse
sed -i '/command: generate/d' docker-compose.yml
docker-compose up -d

echo
echo "============================================================="
echo "FreeWay Matrix завершён"
echo "Домен: $DOMAIN"
echo "E-mail: $EMAIL"
echo "Проверка: https://$DOMAIN/_matrix/client/versions"
echo "============================================================="
