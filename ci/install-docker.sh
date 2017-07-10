#!/usr/bin/env bash

sudo apt-get clean
sudo apt-get update
sudo apt-get -y -o Dpkg::Options::="--force-confnew" install docker-ce
docker --version
sudo rm /usr/local/bin/docker-compose || true
curl -L https://github.com/docker/compose/releases/download/1.6.2/docker-compose-`uname -s`-`uname -m` > docker-compose
chmod +x docker-compose
sudo mv docker-compose /usr/local/bin
docker-compose --version
