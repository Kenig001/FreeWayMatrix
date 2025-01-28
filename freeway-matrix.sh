#!/usr/bin/env bash
set -euo pipefail
trap 'tput cnorm; clear; exit' INT
tput civis
clear

# Variables for animation and ASCII art
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

# Animation loop
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

# Clear half of the screen
for (( y=0; y<HALF_ROWS; y++ )); do
  tput cup "$y" 0
  printf "%${COLUMNS}s" " "
done

# ASCII FreeWay Art
ASCII_FREEWAY="
░▒▓████████▓▒░▒▓███████▓▒░░▒▓████████▓▒░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░
░▒▓██████▓▒░ ░▒▓███████▓▒░░▒▓██████▓▒░ ░▒▓██████▓▒░ ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓████████▓▒░░▒▓██████▓▒░
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░  ░▒▓█▓▒░
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░  ░▒▓█▓▒░
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓████████▓▒░▒▓████████▓▒░░▒▓█████████████▓▒░░▒▓█▓▒░░▒▓█▓▒░  ░▒▓█▓▒░
"

# Display ASCII FreeWay Art
tput cup "$HALF_ROWS" 0
echo -e "\033[35m$ASCII_FREEWAY\033[0m"
sleep 2
tput cnorm
echo
echo "Created by Kenig001"
sleep 2
clear

# Проверка прав администратора
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Installation steps
echo "=== Installing necessary packages: Docker, Docker Compose, ufw, certbot ==="
sudo apt-get update
sudo apt-get install -y docker.io docker-compose ufw certbot

# Domain and email input
read -rp "Enter domain (example: matrix.example.com): " DOMAIN
if [ -z "$DOMAIN" ]; then
  echo "Domain cannot be empty!"
  exit 1
fi
read -rp "Enter e-mail (example: mail@example.com): " EMAIL
if [ -z "$EMAIL" ]; then
  echo "E-mail cannot be empty!"
  exit 1
elif ! [[ "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
  echo "Invalid email format!"
  exit 1
fi

# Firewall setup
echo "Opening ports 22, 80, 443, 8008, 8448"
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8008/tcp
sudo ufw allow 8448/tcp
UFW_STATUS=$(sudo ufw status | head -n1)
if [[ "$UFW_STATUS" == "Status: inactive" ]]; then
  sudo ufw enable
else
  echo "UFW is already active."
fi

# Ensure no service is using port 80
echo "Ensuring port 80 is free for certbot"
sudo systemctl stop nginx || true
sudo fuser -k 80/tcp || true

# Obtain SSL certificate using certbot
sudo certbot certonly --standalone -m "$EMAIL" --agree-tos -d "$DOMAIN"
if [ $? -ne 0 ]; then
  echo "Certbot failed to obtain a certificate."
  exit 1
fi

# Setting permissions for certificates
echo "=== Setting permissions for certificates ==="
sudo chmod -R 755 "/etc/letsencrypt/live/$DOMAIN"
sudo chmod -R 755 "/etc/letsencrypt/archive/$DOMAIN"
sudo chmod 755 /etc/letsencrypt

# Install and configure Nginx
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
if [ $? -ne 0 ]; then
  echo "Nginx configuration test failed."
  exit 1
fi

# Create folder for Synapse
SYNAPSE_DIR="synapse"
mkdir -p "$SYNAPSE_DIR"
cd "$SYNAPSE_DIR"
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

# Start Synapse
sudo docker-compose down
sudo docker-compose up -d
if [ $? -ne 0 ]; then
  echo "Failed to start Synapse container."
  exit 1
fi

# Generate base configuration
echo "Generating base configuration..."
sudo docker-compose exec synapse python3 -m synapse.app.homeserver --generate-config --server-name=${DOMAIN} -c homeserver.yaml.template
if [ $? -ne 0 ]; then
  echo "Failed to generate base configuration."
  exit 1
fi

# Copy and modify the generated configuration
echo "Copying and modifying the generated configuration..."
sudo docker cp synapse:/data/homeserver.yaml ./data/homeserver.yaml
if [ $? -ne 0 ]; then
  echo "Failed to copy the generated configuration."
  exit 1
fi

# Configure homeserver.yaml
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

# Restart Synapse to apply changes
echo "Restarting Synapse to apply changes..."
sudo docker-compose restart synapse
if [ $? -ne 0 ]; then
  echo "Failed to restart Synapse container."
  exit 1
fi

# Completion message
echo "============================================================="
echo "Matrix Synapse has been successfully installed!"
echo "Files are in the '$SYNAPSE_DIR' directory."
echo "Domain: $DOMAIN"
echo "Check: https://$DOMAIN/_matrix/client/versions"
echo "============================================================="
