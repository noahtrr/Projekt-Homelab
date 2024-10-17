#!/bin/sh
echo "Homeserver Setup script v1.0"
echo "----------------------------"
echo ""
echo "Installing System Updates."
echo ""

sudo apt update
sudo apt upgrade -y
sudo do-release-upgrade

echo "Installing needed apps and dependencies."

sudo apt install curl ca-certificates -y

echo "Adding dependencies for docker."

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Installing docker engine."

sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

echo "Creating docker volume for Portainer."

docker volume create portainer_data

docker run -d -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ee:latest

echo "Setting up file structure in /opt/ for docker."

mkdir /opt/Docker

echo "Creating docker Container for homepage."

docker run -d --name homepage \
  -e PUID=1000 \
  -e PGID=1000 \
  -p 80:3000 \
  -v /opt/Docker/homepage/config:/app/config \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  --restart unless-stopped \
  ghcr.io/gethomepage/homepage:latest

echo "Creating docker container for NetBox"

git clone -b release https://github.com/noahtrr/netbox-docker.git #Customized for restart policies, nothing else.
cd netbox-docker
tee docker-compose.override.yml <<EOF
services:
  netbox:
    ports:
      - 8000:8080
EOF
docker compose pull
docker compose up -d

echo "Return to previous directory."

cd ..