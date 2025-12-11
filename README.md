# ocsi-owncloud-s3-docker

Create ocis config:
```
nano ~/install-core.sh
```
```
chmod +x ~/install-core.sh
sudo ~/install-core.sh
```
```
docker run --rm -it -v /opt/ocis/ocis-config:/etc/ocis -v /opt/ocis/ocis-data:/var/lib/ocis owncloud/ocis:latest init --force-overwrite
```

Create ~/create-install-backup.sh:

```
nano ~/create-install-backup.sh
```
```
chmod +x ~/create-install-backup.sh
sudo ~/create-install-backup.sh
```

Restore:
```
sudo nano /usr/local/bin/ocis-restore.sh
````
```
sudo chmod +x /usr/local/bin/ocis-restore.sh
sudo /usr/local/bin/ocis-restore.sh
```
