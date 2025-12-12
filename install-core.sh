#!/bin/bash
set -e

# -----------------------------
# 1️⃣ Configurare variabile
# -----------------------------
OCIS_DOMAIN=$(hostname -I | awk '{print $1}')

# Amazon S3 (driver s3ng)
STORAGE_USERS_DRIVER="s3ng"
STORAGE_USERS_S3NG_BUCKET="owncloud"
STORAGE_USERS_S3NG_REGION="eu-central-1"
STORAGE_USERS_S3NG_ACCESS_KEY="bbbbbbbbbbbbbbbbbbbb"
STORAGE_USERS_S3NG_SECRET_KEY="aaaaaaaaaaaaaaaaaaa"
STORAGE_USERS_S3NG_ENDPOINT="https://md1-s3.datahub.md"
STORAGE_USERS_S3NG_PROPAGATOR="sync"
STORAGE_USERS_S3NG_PUT_OBJECT_DISABLE_MULTIPART=false
STORAGE_USERS_S3NG_PUT_OBJECT_NUM_THREADS=4

# SMTP Configurație
SMTP_HOST="smtp.yourdomain.com"
SMTP_PORT="587"
SMTP_SENDER="ocis <noreply@yourdomain.com>"
SMTP_USERNAME="smtp_user"
SMTP_PASSWORD="smtp_password"
SMTP_AUTHENTICATION="login"
SMTP_SECURITY="secure"

# -----------------------------
# 2️⃣ Instalare Docker, Docker Compose, mc dacă lipsesc
# -----------------------------
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release fuse mc

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor \
    --yes --output /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin


# -----------------------------
# 3️⃣ Creare directoare
# -----------------------------
echo "Creare directoare..."
mkdir -p /opt/ocis
cd /opt/ocis
mkdir -p ./ocis-config
mkdir -p ./ocis-data

sudo chown -R 1000:1000 /opt/ocis/
sudo chmod -R 770 /opt/ocis

# -----------------------------
# 4️⃣ Creare .env
# -----------------------------
echo "Creare .env..."
cat > .env <<EOL
OCIS_DOMAIN=${OCIS_DOMAIN}
STORAGE_USERS_DRIVER=${STORAGE_USERS_DRIVER}
STORAGE_USERS_S3NG_BUCKET=${STORAGE_USERS_S3NG_BUCKET}
STORAGE_USERS_S3NG_REGION=${STORAGE_USERS_S3NG_REGION}
STORAGE_USERS_S3NG_ACCESS_KEY=${STORAGE_USERS_S3NG_ACCESS_KEY}
STORAGE_USERS_S3NG_SECRET_KEY=${STORAGE_USERS_S3NG_SECRET_KEY}
STORAGE_USERS_S3NG_ENDPOINT=${STORAGE_USERS_S3NG_ENDPOINT}
STORAGE_USERS_S3NG_PROPAGATOR=${STORAGE_USERS_S3NG_PROPAGATOR}
STORAGE_USERS_S3NG_PUT_OBJECT_DISABLE_MULTIPART=${STORAGE_USERS_S3NG_PUT_OBJECT_DISABLE_MULTIPART}
STORAGE_USERS_S3NG_PUT_OBJECT_NUM_THREADS=${STORAGE_USERS_S3NG_PUT_OBJECT_NUM_THREADS}
SMTP_HOST=${SMTP_HOST}
SMTP_PORT=${SMTP_PORT}
SMTP_SENDER=${SMTP_SENDER}
SMTP_USERNAME=${SMTP_USERNAME}
SMTP_PASSWORD=${SMTP_PASSWORD}
SMTP_AUTHENTICATION=${SMTP_AUTHENTICATION}
SMTP_SECURITY=${SMTP_SECURITY}
EOL

# -----------------------------
# 5️⃣ Creare docker-compose.yml
# -----------------------------
echo "Creare docker-compose.yml..."
cat > docker-compose.yml <<EOL
services:
  ocis:
    image: owncloud/ocis:latest
    container_name: ocis
    restart: unless-stopped
    env_file:
      - .env
    environment:
      OCIS_INSECURE: "true"
      OCIS_URL: "https://\${OCIS_DOMAIN}:9200"
      OCIS_LOG_LEVEL: info
      PROXY_HTTP_ADDR: "0.0.0.0:9200"
      PROXY_TLS: "true"
      IDP_ISSUER: "https://\${OCIS_DOMAIN}:9200"
    ports:
      - "9200:9200"
    volumes:
      - ./ocis-config:/etc/ocis
      - ./ocis-data:/var/lib/ocis
EOL

echo "✅ Script finalizat!"
echo "Directoarele, .env și docker-compose.yml au fost create."
echo "Inițializare OCIS (doar prima dată sau forțare):"
echo "docker run --rm -it -v /opt/ocis/ocis-config:/etc/ocis -v /opt/ocis/ocis-data:/var/lib/ocis owncloud/ocis:latest init --force-overwrite"
echo "Pentru a porni OCIS cu Amazon S3, rulează manual: cd /opt/ocis && docker compose up -d"
