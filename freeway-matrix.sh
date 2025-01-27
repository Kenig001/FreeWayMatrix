#!/usr/bin/env bash

set -e
trap 'tput cnorm; clear; exit' INT
tput civis
clear

echo "=== Установка Matrix Synapse с Nginx ==="

# Установка необходимых пакетов
echo "=== Установка необходимых пакетов: Docker, Docker Compose, Nginx, ufw, certbot ==="
sudo apt-get update
sudo apt-get install -y docker.io docker-compose nginx ufw certbot

# Ввод домена и электронной почты
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

# Настройка брандмауэра (UFW)
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

# Получение SSL-сертификатов
echo
echo "Убедитесь, что никакой другой сервис не слушает порт 80"
read -rp "Нажмите Enter для продолжения..."
sudo certbot certonly --standalone -m "$EMAIL" --agree-tos -d "$DOMAIN"

# Настройка прав доступа к сертификатам
echo "=== Настройка прав доступа для сертификатов ==="
sudo chmod -R 755 /etc/letsencrypt/live/$DOMAIN
sudo chmod -R 755 /etc/letsencrypt/archive/$DOMAIN
sudo chmod 755 /etc/letsencrypt

# Настройка Nginx
echo "=== Создаём конфигурацию Nginx ==="
sudo bash -c "cat > /etc/nginx/sites-available/$DOMAIN" <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers HIGH:!aNULL:!MD5;

    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";

    location / {
        proxy_pass http://127.0.0.1:8008;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx

# Создание docker-compose.yml
echo "=== Создаём docker-compose.yml ==="
cat > docker-compose.yml <<EOF
version: '3.7'
services:
  synapse:
    image: matrixdotorg/synapse:latest
    container_name: synapse
    ports:
      - "8008:8008"
    volumes:
      - ./data:/data
      - /etc/letsencrypt:/etc/letsencrypt:ro
    environment:
      - SYNAPSE_SERVER_NAME=${DOMAIN}
      - SYNAPSE_REPORT_STATS=no
    restart: always
EOF

# Запуск Synapse
echo "=== Запуск Synapse ==="
docker-compose down
docker-compose up -d

# Генерация homeserver.yaml
echo "=== Генерация конфигурации Synapse (homeserver.yaml) ==="
docker-compose exec synapse generate
HOMESERVER_YAML="./data/homeserver.yaml"
if [ -f "$HOMESERVER_YAML" ]; then
  echo "Обновление $HOMESERVER_YAML"
  cat > "$HOMESERVER_YAML" <<EOF
listeners:
  - port: 8008
    tls: false
    type: http
    x_forwarded: true
    resources:
      - names: [client, federation, media]
        compress: false

  - port: 8448
    tls: true
    type: http
    x_forwarded: true
    resources:
      - names: [client, federation, media]
        compress: false

database:
  name: sqlite3
  args:
    database: /data/homeserver.db

log_config: "/data/$DOMAIN.log.config"

media_store_path: /data/media_store
enable_media_repo: true
max_upload_size: 1G

registration_shared_secret: "$(openssl rand -base64 32)"
macaroon_secret_key: "$(openssl rand -base64 32)"
form_secret: "$(openssl rand -base64 32)"
signing_key_path: "/data/$DOMAIN.signing.key"

trusted_key_servers:
  - server_name: "matrix.org"

report_stats: false
enable_registration: true
registration_requires_approval: false
enable_registration_without_verification: true

tls_certificate_path: "/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
tls_private_key_path: "/etc/letsencrypt/live/$DOMAIN/privkey.pem"
EOF
else
  echo "Ошибка: файл $HOMESERVER_YAML не найден!"
fi

echo "============================================================="
echo "Matrix Synapse успешно установлен!"
echo "Домен: $DOMAIN"
echo "Проверка: https://$DOMAIN/_matrix/client/versions"
echo "============================================================="
