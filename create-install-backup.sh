#!/bin/bash
set -e

INSTALL_SCRIPT="/usr/local/bin/install-ocis-backup.sh"

echo "📌 Creare $INSTALL_SCRIPT ..."

cat > "$INSTALL_SCRIPT" <<'EOL'
#!/bin/bash
set -e

BACKUP_SCRIPT="/usr/local/bin/ocis-backup.sh"
CRON_JOB="0 3 * * * /usr/local/bin/ocis-backup.sh >> /var/log/ocis-backup.log 2>&1"

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

# Citire AWS key/secret/endpoint din .env
AWS_ACCESS_KEY=$(grep AWS_ACCESS_KEY_ID "$ENV_FILE" | cut -d '=' -f2 | tr -d '"')
AWS_SECRET_KEY=$(grep AWS_SECRET_ACCESS_KEY "$ENV_FILE" | cut -d '=' -f2 | tr -d '"')
S3_BUCKET="owncloud"
S3_ENDPOINT="https://md1-s3.datahub.md"
S3_REGION="eu-central-1"

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
access_key_id = $AWS_ACCESS_KEY
secret_access_key = $AWS_SECRET_KEY
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

# Păstrăm doar ultimele 2 backup-uri
BACKUPS_LIST=$(rclone lsf "$RCLONE_REMOTE:$S3_BUCKET/" --files-only | grep '^ocis-backup-' | sort -r)
BACKUPS_COUNT=$(echo "$BACKUPS_LIST" | wc -l)

if [ "$BACKUPS_COUNT" -gt 2 ]; then
  TO_DELETE=$(echo "$BACKUPS_LIST" | tail -n +3)
  for f in $TO_DELETE; do
    echo "🗑️ Ștergere backup vechi: $f"
    rclone delete "$RCLONE_REMOTE:$S3_BUCKET/$f"
  done
fi
BACKUP_EOF

  chmod +x "$BACKUP_SCRIPT"
  echo "✅ Script creat și făcut executabil: $BACKUP_SCRIPT"
else
  echo "ℹ️ Scriptul $BACKUP_SCRIPT există deja, nu se suprascrie."
fi

# Adăugare job CRON dacă nu există
(crontab -l 2>/dev/null | grep -v -F "$BACKUP_SCRIPT"; echo "$CRON_JOB") | crontab -
echo "⏰ Job CRON adăugat pentru rulare zilnică la 03:00."
EOL

chmod +x "$INSTALL_SCRIPT"
echo "✅ Install script creat și executabil: $INSTALL_SCRIPT"

sudo /usr/local/bin/install-ocis-backup.sh


