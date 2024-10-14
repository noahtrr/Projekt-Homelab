#!/bin/sh

echo "Homeserver Setup script v1.0"

# Update package list and upgrade packages

sudo apt upgrade && apt update -y

# Installing Prerequisites, Docker Engine & Portainer

sudo apt install curl -y

sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Create Docker Volume for portainer

docker volume create portainer_data

# Create and run different docker containers

# Portainer
docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ee

# Grafana
docker volume create grafana-storage
docker run -d -p 3000:3000 --name=grafana \
  --volume grafana-storage:/var/lib/grafana \
  grafana/grafana-enterprise

# Heimdall
docker run -d \
  --name=heimdall \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Europe/Berlin \
  -p 80:80 \
  -p 443:443 \
  -v /opt/heimdall-configuration:/config \
  --restart unless-stopped \
  lscr.io/linuxserver/heimdall:latest

# NetBox
docker volume create -d local netbox-media-files
docker volume create -d local netbox-postgres-data
docker volume create -d local netbox-redis-cache-data
docker volume create -d local netbox-redis-data
docker volume create -d local netbox-reports-files
docker volume create -d local netbox-scripts-files
docker run --env-file env/netbox.env -u unit:root --health-cmd "curl -f http://localhost:8080/login/ || exit 1" --health-interval 15s --health-start-period 90s --health-timeout 3s -v /opt/netbox-configuration:/etc/netbox/config:z,ro -v netbox-media-files:/opt/netbox/netbox/media:rw -v netbox-reports-files:/opt/netbox/netbox/reports:rw -v netbox-scripts-files:/opt/netbox/netbox/scripts:rw docker.io/netboxcommunity/netbox:${VERSION-v4.1-3.0.2}
docker run --health-cmd "ps -aux | grep -v grep | grep -q rqworker || exit 1" --health-interval 15s --health-start-period 20s --health-timeout 3s /opt/netbox/venv/bin/python,/opt/netbox/netbox/manage.py,rqworker
docker run --health-cmd "ps -aux | grep -v grep | grep -q housekeeping || exit 1" --health-interval 15s --health-start-period 20s --health-timeout 3s /opt/netbox/housekeeping.sh
docker run --health-cmd "pg_isready -q -t 2 -d $$POSTGRES_DB -U $$POSTGRES_USER" --health-interval 10s --health-retries 5 --health-start-period 20s --health-timeout 30s --env-file env/postgres.env -v netbox-postgres-data:/var/lib/postgresql/data docker.io/postgres:16-alpine
docker run --health-cmd "[ $$(valkey-cli --pass \"$${REDIS_PASSWORD}" ping) = 'PONG' ]" --health-interval 1s --health-retries 5 --health-start-period 5s --health-timeout 3s --env-file env/redis.env -v netbox-redis-data:/data docker.io/valkey/valkey:8.0-alpine sh,-c,valkey-server --appendonly yes --requirepass $$REDIS_PASSWORD
docker run --health-cmd "[ $$(valkey-cli --pass \"$${REDIS_PASSWORD}" ping) = 'PONG' ]" --health-interval 1s --health-retries 5 --health-start-period 5s --health-timeout 3s --env-file env/redis-cache.env -v netbox-redis-cache-data:/data docker.io/valkey/valkey:8.0-alpine sh,-c,valkey-server --requirepass $$REDIS_PASSWORD
  
