#!/bin/bash
set -e

# -----------------------------
# Configurare fixă
# -----------------------------
OCIS_CONTAINER="ocis"
OCIS_DIR="/opt/ocis"
BACKUP_DIR="/tmp"
S3_BUCKET="owncloud"
S3_ENDPOINT="https://md1-s3.datahub.md"
S3_REGION="eu-central-1"

# -----------------------------
# Configurare interactivă doar AWS
# -----------------------------
read -p "AWS Access Key ID: " AWS_ACCESS_KEY_ID
read -p "AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY

export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY

# -----------------------------
# Creează director OCIS dacă nu există
# -----------------------------
if [ ! -d "$OCIS_DIR" ]; then
    echo "📂 Directorul $OCIS_DIR nu există. Creare..."
    mkdir -p "$OCIS_DIR"
    sudo chown -R 1000:1000 "$OCIS_DIR"
    sudo chmod -R 770 "$OCIS_DIR"
fi

# -----------------------------
# 1️⃣ Oprește OCIS
# -----------------------------
if [ "$(docker ps -q -f name=${OCIS_CONTAINER})" ]; then
    echo "⏸ Oprire container OCIS..."
    docker stop ${OCIS_CONTAINER}
fi

# -----------------------------
# 2️⃣ Preia ultimul backup S3
# -----------------------------
echo "☁️ Căutare ultim backup în S3..."
LATEST_BACKUP=$(aws s3 ls s3://${S3_BUCKET}/ --recursive --endpoint-url ${S3_ENDPOINT} --region ${S3_REGION} | \
    grep 'ocis-backup-.*\.tar\.gz' | sort | tail -n1 | awk '{print $4}')

if [ -z "$LATEST_BACKUP" ]; then
    echo "❌ Nu am găsit niciun backup în S3!"
    exit 1
fi

echo "📥 Descărcare $LATEST_BACKUP..."
aws s3 cp s3://${S3_BUCKET}/${LATEST_BACKUP} ${BACKUP_DIR}/ --endpoint-url ${S3_ENDPOINT} --region ${S3_REGION}

BACKUP_FILE="${BACKUP_DIR}/$(basename ${LATEST_BACKUP})"
echo "✅ Backup descărcat: $BACKUP_FILE"

# -----------------------------
# 3️⃣ Dezarhivează backup-ul
# -----------------------------
echo "📦 Restaurare backup..."
tar -xzvf "$BACKUP_FILE" -C "$OCIS_DIR"

# -----------------------------
# 4️⃣ Setează permisiuni
# -----------------------------
echo "🔧 Setare permisiuni..."
sudo chown -R 1000:1000 "$OCIS_DIR"
sudo chmod -R 770 "$OCIS_DIR"

# -----------------------------
# 5️⃣ Pornește OCIS
# -----------------------------
echo "▶️ Pornire OCIS..."
docker start ${OCIS_CONTAINER} || echo "Containerul nu există. Pornește-l manual după restaurare."

echo "🎉 Restaurare completă!"
