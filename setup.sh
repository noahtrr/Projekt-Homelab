#!/bin/bash

echo "Home server setup script v1.1"
echo "-----------------------------"
echo ""

echo "Installing system updates."
echo ""

sudo apt update
sudo apt upgrade -y
sudo do-release-upgrade
echo ""

echo "Install needed packages."
echo ""
sudo apt install curl git fail2ban ca-certificates -y
echo ""

echo "Change timezone to Europe/Berlin."
sudo timedatectl set-timezone Europe/Berlin
echo ""

echo "Installing docker engine."
echo ""
echo "Adding dockers GPG key."
echo ""
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo ""
echo "Adding the repo to apt sources."
echo ""
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
echo ""
echo "Installing the docker packages."
echo ""
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
echo ""

echo "Creating directory in /opt"
mkdir /opt/docker
echo ""

echo "Setting up docker volumes."
docker volume create portainer_data
echo ""
