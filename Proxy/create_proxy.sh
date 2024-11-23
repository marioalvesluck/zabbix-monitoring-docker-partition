#!/bin/bash

# Função de log para registrar mensagens com data e hora
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
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
log "Início da configuração do Zabbix Proxy." | tee -a "$LOG_FILE"

# Instalar pacotes necessários
log "Instalando pacotes do Zabbix Proxy..." | tee -a "$LOG_FILE"
rpm -Uvh https://repo.zabbix.com/zabbix/7.0/oracle/9/x86_64/zabbix-release-latest.el9.noarch.rpm
dnf install -y zabbix-proxy-mysql zabbix-sql-scripts zabbix-selinux-policy | tee -a "$LOG_FILE"

if [ $? -eq 0 ]; then
    log "Pacotes instalados com sucesso." | tee -a "$LOG_FILE"
else
    log "Erro ao instalar pacotes. Verifique os logs." | tee -a "$LOG_FILE"
    exit 1
fi

# Parar o serviço do Zabbix Proxy
log "Parando o serviço Zabbix Proxy..." | tee -a "$LOG_FILE"
systemctl stop "$ZABBIX_PROXY_SERVICE"

# Configurar o banco de dados
log "Configurando banco de dados $DB_NAME..." | tee -a "$LOG_FILE"
mysql -u "$DB_ROOT_USER" -p"$DB_ROOT_PASSWORD" <<EOF
DROP USER IF EXISTS '$DB_USER'@'localhost';
DROP DATABASE IF EXISTS $DB_NAME;
CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_USER_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
SET GLOBAL log_bin_trust_function_creators = 1;
EOF

if [ $? -eq 0 ]; then
    log "Banco de dados configurado com sucesso." | tee -a "$LOG_FILE"
else
    log "Erro ao configurar banco de dados." | tee -a "$LOG_FILE"
    exit 1
fi

# Importar script SQL
log "Importando script SQL do Zabbix Proxy..." | tee -a "$LOG_FILE"
cat "$SQL_SCRIPT" | mysql --default-character-set=utf8mb4 -u"$DB_USER" -p"$DB_USER_PASSWORD" "$DB_NAME"

if [ $? -eq 0 ]; then
    log "Script SQL importado com sucesso." | tee -a "$LOG_FILE"
else
    log "Erro ao importar script SQL." | tee -a "$LOG_FILE"
    exit 1
fi

# Desabilitar log_bin_trust_function_creators
log "Desabilitando log_bin_trust_function_creators..." | tee -a "$LOG_FILE"
mysql -u "$DB_ROOT_USER" -p"$DB_ROOT_PASSWORD" <<EOF
SET GLOBAL log_bin_trust_function_creators = 0;
EOF

# Gerar chave PSK
log "Gerando chave PSK..." | tee -a "$LOG_FILE"
mkdir -p "$(dirname "$PROXY_PSK_FILE")"
PROXY_PSK=$(openssl rand -hex 32)
echo "$PROXY_PSK" > "$PROXY_PSK_FILE"
chmod 775 "$PROXY_PSK_FILE"

log "Chave PSK gerada e salva em: $PROXY_PSK_FILE" | tee -a "$LOG_FILE"

# Configurar parâmetros no arquivo zabbix_proxy.conf
log "Configurando parâmetros no arquivo zabbix_proxy.conf..." | tee -a "$LOG_FILE"
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
sed -i "s/^ProxyBufferMode=.*/ProxyBufferMode=hybrid/" "$ZABBIX_CONF"
sed -i "s/^ProxyMemoryBufferSize=.*/ProxyMemoryBufferSize=512M/" "$ZABBIX_CONF"
sed -i "s/^StartPollers=.*/StartPollers=10/" "$ZABBIX_CONF"
sed -i "s/^StartPingers=.*/StartPingers=30/" "$ZABBIX_CONF"
sed -i "s|^SNMPTrapperFile=.*|SNMPTrapperFile=/var/log/snmptrap/snmptrap.log|" "$ZABBIX_CONF"
sed -i "s/^CacheSize=.*/CacheSize=512M/" "$ZABBIX_CONF"
sed -i "s/^HistoryCacheSize=.*/HistoryCacheSize=512M/" "$ZABBIX_CONF"
sed -i "s/^Timeout=.*/Timeout=30/" "$ZABBIX_CONF"
sed -i "s|^FpingLocation=.*|FpingLocation=/usr/bin/fping|" "$ZABBIX_CONF"
sed -i "s|^Fping6Location=.*|Fping6Location=/usr/bin/fping6|" "$ZABBIX_CONF"
sed -i "s/^LogSlowQueries=.*/LogSlowQueries=3000/" "$ZABBIX_CONF"
sed -i "s/^TLSConnect=.*/TLSConnect=psk/" "$ZABBIX_CONF"
sed -i "s/^TLSAccept=.*/TLSAccept=psk/" "$ZABBIX_CONF"
sed -i "s/^TLSPSKIdentity=.*/TLSPSKIdentity=${ZABBIX_PROXY_PSK}/" "$ZABBIX_CONF"
sed -i "s|^TLSPSKFile=.*|TLSPSKFile=${PROXY_PSK_FILE}|" "$ZABBIX_CONF"
sed -i "s/^StartBrowserPollers=.*/StartBrowserPollers=5/" "$ZABBIX_CONF"

if [ $? -eq 0 ]; then
    log "Parâmetros configurados com sucesso no arquivo zabbix_proxy.conf." | tee -a "$LOG_FILE"
else
    log "Erro ao configurar o arquivo zabbix_proxy.conf. Verifique os logs." | tee -a "$LOG_FILE"
    exit 1
fi

# Reiniciar o serviço do Zabbix Proxy
log "Reiniciando o serviço Zabbix Proxy..." | tee -a "$LOG_FILE"
systemctl start "$ZABBIX_PROXY_SERVICE"

if [ $? -eq 0 ]; then
    log "Zabbix Proxy configurado e iniciado com sucesso!" | tee -a "$LOG_FILE"
else
    log "Erro ao iniciar o Zabbix Proxy." | tee -a "$LOG_FILE"
    exit 1
fi

# Fim do script
log "Configuração concluída." | tee -a "$LOG_FILE"
