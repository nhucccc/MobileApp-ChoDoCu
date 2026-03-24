#!/bin/bash
set -e

echo ">>> Cai Docker..."
apt-get update -y
apt-get install -y ca-certificates curl gnupg git
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu focal stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

echo ">>> Cai Nginx + Certbot..."
apt-get install -y nginx certbot python3-certbot-nginx

echo ">>> Config Nginx..."
cat > /etc/nginx/sites-available/chodocu << 'EOF'
server {
    listen 80;
    server_name berlinmmo.site www.berlinmmo.site;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400;
    }
}
EOF

ln -sf /etc/nginx/sites-available/chodocu /etc/nginx/sites-enabled/chodocu
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

echo ">>> Cap SSL..."
certbot --nginx -d berlinmmo.site -d www.berlinmmo.site --non-interactive --agree-tos -m admin@berlinmmo.site

echo ">>> Build va chay backend..."
cd /root/chodocu
docker compose up -d --build

echo ""
echo "=== XONG! ==="
echo "Backend dang chay tai: https://berlinmmo.site/api"
echo "Kiem tra log: docker compose logs -f backend"
