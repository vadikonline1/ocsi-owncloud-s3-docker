# ocsi-owncloud-s3-docker


### 1️⃣ Clone repository-ul și fă scripturile executabile

```bash
# Clonăm repository-ul care conține toate scripturile
git clone https://github.com/utilizator/ocis-scripts.git ~/ocis-scripts
cd ~/ocis-scripts

# Facem toate scripturile din home executabile
chmod +x ~/*.sh
```

---

### 2️⃣ Instalare OCIS

```bash
# Rulăm scriptul principal de instalare
sudo ~/install-core.sh
```
```
# Inițializare OCIS cu suprascriere forțată
docker run --rm -it \
  -v /opt/ocis/ocis-config:/etc/ocis \
  -v /opt/ocis/ocis-data:/var/lib/ocis \
  owncloud/ocis:latest init --force-overwrite
```

---

### 3️⃣ Creare script backup

```bash
# Creăm scriptul pentru backup automat
nano ~/create-install-backup.sh
```

**Exemplu minimal pentru `create-install-backup.sh`:**

```bash
#!/bin/bash
sudo /usr/local/bin/ocis-backup.sh
```

Facem executabil și rulăm:

```bash
chmod +x ~/create-install-backup.sh
sudo ~/create-install-backup.sh
```

---

### 4️⃣ Restaurare backup

```bash
# Facem scriptul de restaurare executabil
sudo chmod +x /usr/local/bin/ocis-restore.sh

# Restaurăm ultimele date
sudo /usr/local/bin/ocis-restore.sh
```
