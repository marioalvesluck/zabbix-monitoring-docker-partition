#!/bin/bash

# Variáveis de Configuração
ZABBIX_VERSION=7.0
POSTGRESQL_VERSION=13
DATABASE_PASSWORD="zabbix"
PRODUCT_VERSION=$(rpm -E %{rhel})

# Arquivo de Log e Tempo Inicial
LOG_FILE="/var/log/zabbix_install.log"
START_TIME=$(date +%s)

# Função para log com marcação de tempo
log() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

# Início do Script
log "###############################################################"
log " INICIO DA INSTALAÇÃO DO ZABBIX NO SISTEMA RHEL-LIKE"
log "###############################################################"

# Desabilita SELinux
log "Desabilitando SELinux..."
sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config
setenforce 0

# Configura o firewall
log "Configurando o firewall..."
systemctl start firewalld.service
firewall-cmd --add-port=80/tcp --permanent
firewall-cmd --add-port=10051/tcp --permanent
firewall-cmd --add-port=162/udp --permanent
firewall-cmd --reload

# Instalação dos Locales en_US e pt_BR
log "Instalando e configurando locales en_US.UTF-8 e pt_BR.UTF-8..."
dnf -y install glibc-langpack-en glibc-langpack-pt
localectl set-locale LANG=pt_BR.UTF-8
localectl set-locale LC_ALL=en_US.UTF-8
source /etc/locale.conf

# Instalação do PostgreSQL
log "Instalando repositório PostgreSQL..."
dnf -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-$PRODUCT_VERSION-x86_64/pgdg-redhat-repo-latest.noarch.rpm
dnf -y module disable postgresql
dnf -y install postgresql$POSTGRESQL_VERSION postgresql$POSTGRESQL_VERSION-server

log "Inicializando banco de dados PostgreSQL..."
/usr/pgsql-$POSTGRESQL_VERSION/bin/postgresql-$POSTGRESQL_VERSION-setup initdb
sed -i "s/ident/md5/g" /var/lib/pgsql/$POSTGRESQL_VERSION/data/pg_hba.conf
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /var/lib/pgsql/$POSTGRESQL_VERSION/data/postgresql.conf
systemctl enable --now postgresql-$POSTGRESQL_VERSION

log "Criando usuário e banco de dados para o Zabbix..."
sudo -u postgres psql -c "CREATE USER zabbix WITH ENCRYPTED PASSWORD '$DATABASE_PASSWORD'" 2>/dev/null
sudo -u postgres createdb -O zabbix -E Unicode -T template0 zabbix 2>/dev/null

# Instalação e Configuração do Zabbix Server
log "Instalando repositório Zabbix..."
rpm -Uvh https://repo.zabbix.com/zabbix/$ZABBIX_VERSION/rhel/$PRODUCT_VERSION/x86_64/zabbix-release-$ZABBIX_VERSION-4.el$PRODUCT_VERSION.noarch.rpm
dnf -y install zabbix-server-pgsql zabbix-sql-scripts

log "Configurando schema do banco de dados Zabbix..."
zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u zabbix PGPASSWORD=$DATABASE_PASSWORD psql -hlocalhost -Uzabbix zabbix 2>/dev/null

log "Configurando o Zabbix Server..."
sudo sed -i "s/# DBHost=localhost/DBHost=localhost/" /etc/zabbix/zabbix_server.conf
sudo sed -i "s/# DBPassword=/DBPassword=$DATABASE_PASSWORD/" /etc/zabbix/zabbix_server.conf
systemctl enable --now zabbix-server

# Configuração do Zabbix Frontend com NGINX
log "Instalando pacotes Zabbix Frontend..."
dnf -y install zabbix-web-pgsql zabbix-nginx-conf

log "Configurando PHP para o Zabbix Frontend..."
echo "php_value[date.timezone] = America/Sao_Paulo" >> /etc/php-fpm.d/zabbix.conf

log "Configurando setup web para o Zabbix Frontend..."
sudo tee /etc/zabbix/web/zabbix.conf.php <<EOL
<?php
    \$DB["TYPE"] = "POSTGRESQL";
    \$DB["SERVER"] = "localhost";
    \$DB["PORT"] = "5432";
    \$DB["DATABASE"] = "zabbix";
    \$DB["USER"] = "zabbix";
    \$DB["PASSWORD"] = "$DATABASE_PASSWORD";
    \$DB["SCHEMA"] = "";
    \$DB["ENCRYPTION"] = false;
    \$DB["KEY_FILE"] = "";
    \$DB["CERT_FILE"] = "";
    \$DB["CA_FILE"] = "";
    \$DB["VERIFY_HOST"] = false;
    \$DB["CIPHER_LIST"] = "";
    \$DB["VAULT_URL"] = "";
    \$DB["VAULT_DB_PATH"] = "";
    \$DB["VAULT_TOKEN"] = "";
    \$DB["DOUBLE_IEEE754"] = true;
    \$ZBX_SERVER = "localhost";
    \$ZBX_SERVER_PORT = "10051";
    \$ZBX_SERVER_NAME = "zabbix";
    \$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
EOL

log "Configurando nginx para o Zabbix Frontend..."
sed -i "s/#        listen          8080;/        listen 80 default_server;\\n        listen [::]:80 default_server;/" /etc/nginx/conf.d/zabbix.conf
sed -i "s/#        server_name     example.com;/        server_name _;/" /etc/nginx/conf.d/zabbix.conf
sed -i "/.*listen.*/d" /etc/nginx/nginx.conf
sed -i "/.*server_name.*/d" /etc/nginx/nginx.conf

systemctl enable --now php-fpm
systemctl enable --now nginx

# Instalação do Zabbix Agent 2
log "Instalando Zabbix Agent 2 para monitoramento do servidor..."
dnf -y install zabbix-agent2
systemctl enable --now zabbix-agent2

# Reinício dos serviços php-fpm e nginx para aplicar todas as configurações
log "Reiniciando serviços PHP-FPM e NGINX..."
systemctl restart php-fpm
systemctl restart nginx

# Tempo total de execução e resumo
END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))
log "###############################################################"
log " INSTALAÇÃO COMPLETA DO ZABBIX"
log " TEMPO TOTAL: $((TOTAL_TIME / 60)) minutos e $((TOTAL_TIME % 60)) segundos."
log " Logs detalhados disponíveis em: $LOG_FILE"
log "###############################################################"
