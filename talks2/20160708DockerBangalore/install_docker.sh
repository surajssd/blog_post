#!/bin/bash

set -x

echo "Install docker"
curl -fsSL https://experimental.docker.com/  | sh
sudo groupadd docker
sudo usermod -aG docker vagrant

sudo systemctl start docker
sudo systemctl enable docker
logout

