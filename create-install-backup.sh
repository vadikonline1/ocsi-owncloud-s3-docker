#!/bin/bash
set -e

INSTALL_SCRIPT="/usr/local/bin/install-ocis-backup.sh"

# -----------------------------
# 1️⃣ Creare install script
# -----------------------------
echo "📌 Creare $INSTALL_SCRIPT ..."

cat > "$INSTALL_SCRIPT" <<'EOL'
#!/bin/bash
set -e

BACKUP_SCRIPT="/usr/local/bin/ocis-backup.sh"
CRON_JOB="0 3 * * * $BACKUP_SCRIPT >> /var/log/ocis-backup.log 2>&1"

# -----------------------------
# 1️⃣ Creare backup script dacă nu există
# -----------------------------
if [ ! -f "$BACKUP_SCRIPT" ]; then
  echo "📌 Creare $BACKUP_SCRIPT ..."
  cat > "$BACKUP_SCRIPT" <<'BACKUP_EOF'
#!/bin/bash
set -e

OCIS_DIR="/opt/ocis"
BACKUP_TMP="/tmp"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M")
BACKUP_FILE="$BACKUP_TMP/ocis-backup-$TIMESTAMP.tar.gz"
ENV_FILE="$OCIS_DIR/.env"
RCLONE_REMOTE="ocisbackup"

# Citire variabile S3 din .env
export $(grep -v '^#' "$ENV_FILE" | xargs)

S3_BUCKET="$STORAGE_USERS_S3NG_BUCKET"
S3_ACCESS_KEY="$STORAGE_USERS_S3NG_ACCESS_KEY"
S3_SECRET_KEY="$STORAGE_USERS_S3NG_SECRET_KEY"
S3_ENDPOINT="$STORAGE_USERS_S3NG_ENDPOINT"
S3_REGION="$STORAGE_USERS_S3NG_REGION"

# Instalare rclone dacă lipsește
if ! command -v rclone &> /dev/null; then
  curl https://rclone.org/install.sh | bash
fi

# Configurare rclone remote dacă nu există
RCLONE_CONFIG="$HOME/.config/rclone/rclone.conf"
mkdir -p "$(dirname "$RCLONE_CONFIG")"
if ! rclone listremotes | grep -q "^$RCLONE_REMOTE:"; then
  cat > "$RCLONE_CONFIG" <<RCLONE_EOF
[$RCLONE_REMOTE]
type = s3
provider = Other
env_auth = false
access_key_id = $S3_ACCESS_KEY
secret_access_key = $S3_SECRET_KEY
endpoint = $S3_ENDPOINT
region = $S3_REGION
acl = private
path_style = true
RCLONE_EOF
fi

# Backup OCIS
docker stop ocis || true
tar -czf "$BACKUP_FILE" -C "$OCIS_DIR" .
rclone copy "$BACKUP_FILE" "$RCLONE_REMOTE:$S3_BUCKET/" --progress || echo "⚠️ Upload eșuat!"
docker start ocis || true

echo "✅ Backup finalizat: $BACKUP_FILE"
BACKUP_EOF

  chmod +x "$BACKUP_SCRIPT"
  echo "✅ Script creat și făcut executabil: $BACKUP_SCRIPT"
else
  echo "ℹ️ Scriptul $BACKUP_SCRIPT există deja, nu se suprascrie."
fi

# -----------------------------
# 2️⃣ Adaugare job cron dacă nu există
# -----------------------------
# Extrage crontab existent, evită duplicarea
(crontab -l 2>/dev/null | grep -v -F "$BACKUP_SCRIPT"; echo "$CRON_JOB") | crontab -
echo "⏰ Job CRON adăugat pentru rulare zilnică la 03:00."
EOL

# -----------------------------
# 2️⃣ Fă-l executabil
# -----------------------------
chmod +x "$INSTALL_SCRIPT"
echo "✅ Install script creat și executabil: $INSTALL_SCRIPT"
echo "Poți rula acum: sudo $INSTALL_SCRIPT"

/usr/local/bin/install-ocis-backup.sh
