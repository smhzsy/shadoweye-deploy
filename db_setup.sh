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

# PostgreSQL servisinin çalışıp çalışmadığını kontrol et
if ! systemctl is-active --quiet postgresql; then
    error "PostgreSQL servisi çalışmıyor. Lütfen önce PostgreSQL'i kurun."
fi

# Veritabanı ve kullanıcı bilgileri
DB_NAME="shadoweye"
DB_USER="shadoweye"
DB_PASSWORD="your_secure_password"  # Güvenli bir şifre belirleyin

# Veritabanı oluşturma
log "Veritabanı oluşturuluyor..."
sudo -u postgres psql << EOF
CREATE DATABASE $DB_NAME;
EOF

# Kullanıcı oluşturma ve yetkilendirme
log "Kullanıcı oluşturuluyor ve yetkilendiriliyor..."
sudo -u postgres psql << EOF
CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
\c $DB_NAME
GRANT ALL ON SCHEMA public TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $DB_USER;
EOF

# Veritabanı bağlantısını test et
log "Veritabanı bağlantısı test ediliyor..."
PGPASSWORD=$DB_PASSWORD psql -h localhost -U $DB_USER -d $DB_NAME -c "SELECT 1" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    log "Veritabanı bağlantısı başarılı!"
else
    error "Veritabanı bağlantısı başarısız!"
fi

# Bağlantı bilgilerini göster
log "Veritabanı bağlantı bilgileri:"
echo "Database: $DB_NAME"
echo "User: $DB_USER"
echo "Password: $DB_PASSWORD"
echo "Host: localhost"
echo "Port: 5432"
echo "Connection String: postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME"

log "Veritabanı kurulumu tamamlandı!" 