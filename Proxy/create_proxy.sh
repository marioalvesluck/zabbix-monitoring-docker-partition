#!/bin/bash

# Função de log para registrar mensagens com data e hora
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Variáveis
LOG_FILE="/var/log/zabbix_proxy_setup.log"
DB_ROOT_USER="root"
DB_ROOT_PASSWORD="Zabbix@2024@@"
DB_NAME="zabbix_proxy"
DB_USER="zabbix"
DB_SERVER="192.168.0.51"
DB_USER_PASSWORD="Zabbix@2024@@"
SQL_SCRIPT="/usr/share/zabbix-sql-scripts/mysql/proxy.sql"
ZABBIX_PROXY_SERVICE="zabbix-proxy"
ZABBIX_PROXY_PSK="zabbix-proxy"
PROXY_PSK_FILE="/var/lib/zabbix/zabbix-proxy/enc/zabbix_proxy.psk"
ZABBIX_CONF="/etc/zabbix/zabbix_proxy.conf"

# Início do script
log "Início da configuração do Zabbix Proxy."

# Verificar se o cliente MySQL está instalado
if ! command -v mysql &> /dev/null; then
    log "Cliente MySQL não encontrado. Instalando..."
    dnf install -y mysql
    if ! command -v mysql &> /dev/null; then
        log "Erro ao instalar o cliente MySQL. Verifique os logs e tente novamente."
        exit 1
    fi
    log "Cliente MySQL instalado com sucesso."
else
    log "Cliente MySQL já está instalado."
fi

# Instalar pacotes do Zabbix Proxy
log "Instalando pacotes do Zabbix Proxy..."
rpm -Uvh https://repo.zabbix.com/zabbix/7.0/oracle/9/x86_64/zabbix-release-latest.el9.noarch.rpm
dnf install -y zabbix-proxy-mysql zabbix-sql-scripts zabbix-selinux-policy

if [ $? -eq 0 ]; then
    log "Pacotes instalados com sucesso."
else
    log "Erro ao instalar pacotes do Zabbix Proxy. Verifique os logs."
    exit 1
fi

# Parar o serviço do Zabbix Proxy
log "Parando o serviço Zabbix Proxy..."
systemctl stop "$ZABBIX_PROXY_SERVICE"

# Configurar banco de dados
log "Configurando banco de dados $DB_NAME..."
mysql -u "$DB_ROOT_USER" -p"$DB_ROOT_PASSWORD" <<EOF
DROP USER IF EXISTS '$DB_USER'@'localhost';
DROP DATABASE IF EXISTS $DB_NAME;
CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_USER_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
SET GLOBAL log_bin_trust_function_creators = 1;
EOF

if [ $? -eq 0 ]; then
    log "Banco de dados configurado com sucesso."
else
    log "Erro ao configurar banco de dados."
    exit 1
fi

# Importar script SQL
log "Importando script SQL do Zabbix Proxy..."
cat "$SQL_SCRIPT" | mysql --default-character-set=utf8mb4 -u"$DB_USER" -p"$DB_USER_PASSWORD" "$DB_NAME"

if [ $? -eq 0 ]; then
    log "Script SQL importado com sucesso."
else
    log "Erro ao importar script SQL."
    exit 1
fi

# Desabilitar log_bin_trust_function_creators
log "Desabilitando log_bin_trust_function_creators..."
mysql -u "$DB_ROOT_USER" -p"$DB_ROOT_PASSWORD" <<EOF
SET GLOBAL log_bin_trust_function_creators = 0;
EOF

# Gerar chave PSK
log "Gerando chave PSK..."
mkdir -p "$(dirname "$PROXY_PSK_FILE")"
PROXY_PSK=$(openssl rand -hex 32)
echo "$PROXY_PSK" > "$PROXY_PSK_FILE"
chmod 775 "$PROXY_PSK_FILE"

log "Chave PSK gerada e salva em: $PROXY_PSK_FILE"

# Configurar parâmetros no arquivo zabbix_proxy.conf
log "Configurando parâmetros no arquivo zabbix_proxy.conf..."
sed -i "s/^ProxyMode=.*/ProxyMode=0/" "$ZABBIX_CONF"
sed -i "s|^Server=.*|Server=${DB_SERVER}|" "$ZABBIX_CONF"
sed -i "s/^Hostname=.*/Hostname=${ZABBIX_PROXY_PSK}/" "$ZABBIX_CONF"
sed -i "s|^LogFile=.*|LogFile=/var/log/zabbix/zabbix_proxy.log|" "$ZABBIX_CONF"
sed -i "s/^LogFileSize=.*/LogFileSize=0/" "$ZABBIX_CONF"
sed -i "s/^EnableRemoteCommands=.*/EnableRemoteCommands=1/" "$ZABBIX_CONF"
sed -i "s|^PidFile=.*|PidFile=/run/zabbix/zabbix_proxy.pid|" "$ZABBIX_CONF"
sed -i "s|^SocketDir=.*|SocketDir=/run/zabbix|" "$ZABBIX_CONF"
sed -i "s/^DBName=.*/DBName=${DB_NAME}/" "$ZABBIX_CONF"
sed -i "s/^DBUser=.*/DBUser=${DB_USER}/" "$ZABBIX_CONF"
sed -i "s/^DBPassword=.*/DBPassword=${DB_USER_PASSWORD}/" "$ZABBIX_CONF"
sed -i "s/^TLSConnect=.*/TLSConnect=psk/" "$ZABBIX_CONF"
sed -i "s/^TLSAccept=.*/TLSAccept=psk/" "$ZABBIX_CONF"
sed -i "s/^TLSPSKIdentity=.*/TLSPSKIdentity=${ZABBIX_PROXY_PSK}/" "$ZABBIX_CONF"
sed -i "s|^TLSPSKFile=.*|TLSPSKFile=${PROXY_PSK_FILE}|" "$ZABBIX_CONF"

if [ $? -eq 0 ]; then
    log "Parâmetros configurados com sucesso no arquivo zabbix_proxy.conf."
else
    log "Erro ao configurar o arquivo zabbix_proxy.conf. Verifique os logs."
    exit 1
fi

# Reiniciar o serviço do Zabbix Proxy
log "Reiniciando o serviço Zabbix Proxy..."
systemctl start "$ZABBIX_PROXY_SERVICE"

if [ $? -eq 0 ]; then
    log "Zabbix Proxy configurado e iniciado com sucesso!"
else
    log "Erro ao iniciar o Zabbix Proxy."
    exit 1
fi

# Fim do script
log "Configuração concluída com sucesso."
