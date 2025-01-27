#!/usr/bin/env bash

set -euo pipefail

trap 'tput cnorm; clear; exit' INT
tput civis
clear

COLUMNS=$(tput cols)
ROWS=$(tput lines)
WORD="FreeWay"
WORD_LENGTH=${#WORD}

if [ "$WORD_LENGTH" -gt "$COLUMNS" ]; then
  START_X=0
  GAP=1
else
  TOTAL_GAP=$((COLUMNS - WORD_LENGTH))
  START_X=$((TOTAL_GAP / 2))
  GAP=2
fi

declare -A HEIGHT
for (( i=0; i<WORD_LENGTH; i++ )); do
  HEIGHT[$i]=0
done

random_char() {
  printf "\033[35m%s\033[0m" "$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c1)"
}

HALF_ROWS=$((ROWS / 2))

while true; do
  done_flag=true
  for (( i=0; i<WORD_LENGTH; i++ )); do
    current_height=${HEIGHT[$i]}
    if [ "$current_height" -ge "$HALF_ROWS" ]; then
      continue
    fi
    X=$((START_X + i * GAP))
    if [ "$X" -ge 0 ] && [ "$X" -lt "$COLUMNS" ]; then
      tput cup "$current_height" "$X"
      random_char
    fi
    HEIGHT[$i]=$((current_height + 1))
    done_flag=false
  done
  if $done_flag; then
    break
  fi
  sleep 0.03
done

for (( y=0; y<HALF_ROWS; y++ )); do
  tput cup "$y" 0
  printf "%${COLUMNS}s" " "
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

tput cup "$HALF_ROWS" 0
echo -e "\033[35m$ASCII_FREEWAY\033[0m"

sleep 2
tput cnorm
echo
echo "Created by Kenig001"
sleep 2
clear

echo "=== Installing necessary packages: Docker, Docker Compose, ufw, certbot ==="
sudo apt-get update
sudo apt-get install -y docker.io docker-compose ufw certbot

echo
read -rp "Enter domain (example: matrix.example.com): " DOMAIN
if [ -z "$DOMAIN" ]; then
  echo "Domain cannot be empty!"
  exit 1
fi

read -rp "Enter e-mail (example: mail@example.com): " EMAIL
if [ -z "$EMAIL" ]; then
  echo "E-mail cannot be empty!"
  exit 1
fi

echo
echo "Opening ports 22, 80, 443, 8008, 8448"
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8008/tcp
sudo ufw allow 8448/tcp

UFW_STATUS=$(sudo ufw status | head -n1)
if [[ "$UFW_STATUS" == "Status: inactive" ]]; then
  sudo ufw enable
fi

echo
echo "Ensure no other service is listening on port 80"
read -rp "Press Enter to continue..."

sudo certbot certonly --standalone -m "$EMAIL" --agree-tos -d "$DOMAIN"

echo "=== Setting permissions for certificates ==="
sudo chmod -R 755 "/etc/letsencrypt/live/$DOMAIN"
sudo chmod -R 755 "/etc/letsencrypt/archive/$DOMAIN"
sudo chmod 755 /etc/letsencrypt

echo "=== Installing Nginx ==="
sudo apt-get install -y nginx

echo "=== Creating Nginx configuration ==="
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

sudo ln -s "/etc/nginx/sites-available/$DOMAIN" /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx

echo "=== Creating docker-compose.yml ==="
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

docker-compose down
docker-compose up -d

echo "=== Generating base configuration file homeserver.yaml ==="
docker-compose exec synapse generate

echo "=== Configuring homeserver.yaml ==="
HOMESERVER_YAML="./data/homeserver.yaml"
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

echo "============================================================="
echo "Matrix Synapse has been successfully installed!"
echo "Domain: $DOMAIN"
echo "Check: https://$DOMAIN/_matrix/client/versions"
echo "============================================================="
