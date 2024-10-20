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

echo "Installing telegraf for monitoring purposes."
curl --silent --location -O \
https://repos.influxdata.com/influxdata-archive.key \
&& echo "943666881a1b8d9b849b74caebf02d3465d6beb716510d86a39f6c8e8dac7515  influxdata-archive.key" \
| sha256sum -c - && cat influxdata-archive.key \
| gpg --dearmor \
| sudo tee /etc/apt/trusted.gpg.d/influxdata-archive.gpg > /dev/null \
&& echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive.gpg] https://repos.influxdata.com/debian stable main' \
| sudo tee /etc/apt/sources.list.d/influxdata.list
sudo apt-get update && sudo apt-get install telegraf
echo ""

echo "Add telegraf to video user group."
sudo usermod -G video telegraf
echo ""

echo "Add raspberry pi specific config to telegraf."
echo ""
echo [[inputs.net]]    [[inputs.netstat]]    [[inputs.file]]    files = ["/sys/class/thermal/thermal_zone0/temp"]    name_override = "cpu_temperature"    data_format = "value"    data_type = "integer"    [[inputs.exec]]    commands = ["/opt/vc/bin/vcgencmd measure_temp"]    name_override = "gpu_temperature"    data_format = "grok"    grok_patterns = ["%{NUMBER:value:float}"]  >> /etc/telegraf/telegraf.conf
echo ""

echo "Starting container."
echo ""
