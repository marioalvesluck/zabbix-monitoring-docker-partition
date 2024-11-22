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
DB_USER_PASSWORD="Zabbix@2024@@"
SQL_SCRIPT="/usr/share/zabbix-sql-scripts/mysql/proxy.sql"
ZABBIX_PROXY_SERVICE="zabbix-proxy"
PROXY_PSK_FILE="/var/lib/zabbix/zabbix-proxy/enc/zabbix_proxy.psk"

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
