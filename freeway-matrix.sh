#!/usr/bin/env bash

clear
for i in {1..10}; do
  line=""
  for (( j=1; j<=$((COLUMNS/2)); j++ )); do
    rand_char=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 1)
    line+="$rand_char"
  done
  echo -e "\033[35m$line\033[0m"
  sleep 0.05
done
sleep 1
echo -e "\033[35m"
cat << 'EOF'
   ______                               __      __
  /      \                             /  |    /  |
 /$$$$$$  |  ______   _____  ____      $$ |    $$ |
 $$ |  $$ | /      \ /     \/    \     $$ |    $$ |
 $$ |  $$ |/$$$$$$  |$$$$$$ $$$$  |    $$ |    $$ |
 $$ |  $$ |$$    $$ |$$ | $$ | $$ |    $$ |    $$ |
 $$ \__$$ |$$$$$$$$/ $$ | $$ | $$ |    $$ |____$$ |
 $$    $$/ $$       |$$ | $$ | $$ |    $$       |
  $$$$$$/   $$$$$$$/ $$/  $$/  $$/     $$$$$$$$/
EOF
echo -e "\033[0m"
echo -e "\033[35mCreated by Kenig01\033[0m"
sleep 2
set -e
echo "=== Установка необходимых пакетов: Docker, Docker Compose, ufw, certbot ==="
sudo apt-get update
sudo apt-get install -y docker.io docker-compose ufw certbot
echo
read -rp "Введите домен (например, matrix.example.com): " DOMAIN
if [ -z "$DOMAIN" ]; then
  echo "Домен не может быть пустым!"
  exit 1
fi
read -rp "Введите e-mail для Let's Encrypt (например, mail@example.com): " EMAIL
if [ -z "$EMAIL" ]; then
  echo "E-mail не может быть пустым!"
  exit 1
fi
echo
echo "=== Настройка UFW (firewall) ==="
echo "Открываем порты: 22, 80, 443, 8008, 8448."
echo "Если ufw не был ранее включён, включим его сейчас."
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8008/tcp
sudo ufw allow 8448/tcp
ufw_status=$(sudo ufw status | head -n1)
if [[ "$ufw_status" == "Status: inactive" ]]; then
  echo "UFW неактивен. Включаем ufw..."
  sudo ufw enable
fi
echo
echo "=== Проверка 80-го порта перед запуском certbot ==="
echo "Убедитесь, что никакой другой сервис (например, Apache/Nginx) не слушает 80 порт."
read -rp "Нажмите Enter для продолжения (или Ctrl+C для отмены)..."
echo
echo "=== Запрос сертификата Let’s Encrypt (standalone) для $DOMAIN ==="
sudo certbot certonly --standalone -m "$EMAIL" --agree-tos -d "$DOMAIN"
echo
echo "=== Создание директории ~/matrix-nginx ==="
mkdir -p ~/matrix-nginx
cd ~/matrix-nginx
echo
echo "=== Создаём docker-compose.yml: synapse + nginx ==="
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
echo
echo "=== Первый запуск: генерация homeserver.yaml ==="
docker-compose run --rm synapse
echo
echo "=== Убираем команду 'generate' из docker-compose.yml ==="
sed -i '/command: generate/d' docker-compose.yml
echo
echo "=== Запуск Synapse + Nginx ==="
docker-compose up -d
echo
echo "============================================================="
echo "Установка FreeWay Matrix завершена!"
echo "Домен: ${DOMAIN}"
echo "E-mail: ${EMAIL}"
echo "Открытые порты UFW: 22, 80, 443, 8008, 8448"
echo "Сертификаты: /etc/letsencrypt/live/${DOMAIN}"
echo "Synapse данные: ~/matrix-nginx/synapse-data"
echo "Проверка: https://${DOMAIN}/_matrix/client/versions"
echo "Спасибо за использование FreeWay Matrix! (by Kenig01)"
echo "============================================================="
