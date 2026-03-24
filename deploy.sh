#!/bin/bash
# Script deploy ChoDoCu backend lên VPS Ubuntu 20.04
# Chạy với: bash deploy.sh

set -e

echo "=== Cài Docker ==="
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release git
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

echo "=== Cài Nginx ==="
apt-get install -y nginx certbot python3-certbot-nginx

echo "=== Copy nginx config ==="
cp /root/chodocu/nginx.conf /etc/nginx/sites-available/chodocu
ln -sf /etc/nginx/sites-available/chodocu /etc/nginx/sites-enabled/chodocu
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

echo "=== Cấp SSL ==="
certbot --nginx -d berlinmmo.site -d www.berlinmmo.site --non-interactive --agree-tos -m admin@berlinmmo.site

echo "=== Build & chạy Docker ==="
cd /root/chodocu
docker compose up -d --build

echo "=== Xong! Backend chạy tại https://berlinmmo.site ==="
