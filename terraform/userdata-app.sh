#!/bin/bash
set -eux
apt-get update -y
apt-get install -y docker.io docker-compose-v2 nginx
systemctl enable --now docker
usermod -aG docker ubuntu
