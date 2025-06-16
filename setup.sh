#!/bin/bash

# Renk tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Log fonksiyonu
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Root kontrolü
if [ "$EUID" -eq 0 ]; then 
    error "Bu script root olarak çalıştırılmamalıdır."
fi

# Sistem güncellemeleri
log "Sistem güncellemeleri yapılıyor..."
sudo apt update && sudo apt upgrade -y || error "Sistem güncellemesi başarısız oldu"

# Temel araçların kurulumu
log "Temel araçlar kuruluyor..."
sudo apt install -y curl wget git unzip build-essential libssl-dev libffi-dev python3-dev python3-pip python3-venv || error "Temel araçların kurulumu başarısız oldu"

# Node.js kurulumu
log "Node.js kuruluyor..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - || error "Node.js repository eklenemedi"
sudo apt install -y nodejs || error "Node.js kurulumu başarısız oldu"

# PM2 kurulumu
log "PM2 kuruluyor..."
sudo npm install -g pm2 || error "PM2 kurulumu başarısız oldu"

# Nginx kurulumu
log "Nginx kuruluyor..."
sudo apt install -y nginx || error "Nginx kurulumu başarısız oldu"

# Certbot kurulumu
log "Certbot kuruluyor..."
sudo apt install -y certbot python3-certbot-nginx || error "Certbot kurulumu başarısız oldu"

# PostgreSQL kurulumu
log "PostgreSQL kuruluyor..."
sudo apt install -y postgresql postgresql-contrib || error "PostgreSQL kurulumu başarısız oldu"

# Python bağımlılıkları
log "Python bağımlılıkları kuruluyor..."
sudo apt install -y python3-pandas python3-numpy python3-scipy python3-sklearn || error "Python bağımlılıkları kurulumu başarısız oldu"

# Python paketleri
log "Python paketleri kuruluyor..."
pip3 install --user telethon python-dotenv scikit-learn pandas numpy || error "Python paketleri kurulumu başarısız oldu"

# Proje dizini oluşturma
log "Proje dizini oluşturuluyor..."
mkdir -p ~/shadoweye
cd ~/shadoweye

# Projeyi klonlama
log "Proje klonlanıyor..."
git clone https://github.com/smhzsy/shadoweye-web.git web || error "Web projesi klonlanamadı"

# Web projesi kurulumu
log "Web projesi kuruluyor..."
cd ~/shadoweye/web
npm install || error "Web projesi bağımlılıkları kurulamadı"

# PostgreSQL veritabanı kurulumu
log "PostgreSQL veritabanı kuruluyor..."
sudo -u postgres psql << EOF
CREATE DATABASE shadoweye;
CREATE USER shadoweye WITH ENCRYPTED PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE shadoweye TO shadoweye;
\c shadoweye
GRANT ALL ON SCHEMA public TO shadoweye;
EOF

# Nginx konfigürasyonu
log "Nginx konfigürasyonu yapılıyor..."
sudo tee /etc/nginx/sites-available/shadoweye.xyz << EOF
server {
    server_name shadoweye.xyz www.shadoweye.xyz;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF


# Güvenlik ayarları
log "Güvenlik ayarları yapılıyor..."
sudo apt install -y fail2ban
sudo tee /etc/fail2ban/jail.local << EOF
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
EOF

sudo systemctl restart fail2ban

# Firewall ayarları
log "Firewall ayarları yapılıyor..."
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw --force enable

log "Kurulum tamamlandı!"
log "Web uygulaması: https://shadoweye.xyz"
log "Model uygulaması: PM2 ile arka planda çalışıyor" 
