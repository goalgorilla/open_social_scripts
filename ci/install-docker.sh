#!/usr/bin/env bash

# See: https://docs.travis-ci.com/user/docker/#using-docker-compose
# See: https://docs.travis-ci.com/user/docker/#installing-a-newer-docker-version
# See: https://docs.docker.com/engine/install/ubuntu/#next-steps
sudo apt-get clean
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get -y -o Dpkg::Options::="--force-confnew" install docker-ce docker-ce-cli containerd.io docker-compose-plugin
# Print docker and docker compose tool versions.
docker --version
docker compose version
