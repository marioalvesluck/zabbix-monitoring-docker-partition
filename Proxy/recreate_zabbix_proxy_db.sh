#!/bin/bash

# Configurações do script
LOG_FILE="/var/log/recreate_zabbix_proxy_db.log"
DB_ROOT_USER="root"
DB_ROOT_PASSWORD="Zabbix@2024@@"
DB_NAME="zabbix_proxy"
DB_USER="zabbix"
DB_USER_PASSWORD="Zabbix@2024@@"
SQL_SCRIPT="/usr/share/zabbix-sql-scripts/mysql/proxy.sql"
ZABBIX_PROXY_SERVICE="zabbix-proxy"

# Função para logar mensagens
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_message "Início do script para recriação do banco $DB_NAME."

# Parar o serviço Zabbix Proxy
log_message "Parando o serviço $ZABBIX_PROXY_SERVICE para manutenção."
systemctl stop "$ZABBIX_PROXY_SERVICE"

if [ $? -eq 0 ]; then
    log_message "Serviço $ZABBIX_PROXY_SERVICE parado com sucesso."
else
    log_message "Erro ao parar o serviço $ZABBIX_PROXY_SERVICE."
    exit 1
fi

# Acessando MySQL como root
log_message "Conectando ao MySQL como root."

# Remover usuários existentes com nome zabbix
log_message "Removendo usuários existentes com nome '$DB_USER'."
mysql -u "$DB_ROOT_USER" -p"$DB_ROOT_PASSWORD" <<EOF
DROP USER IF EXISTS '$DB_USER'@'localhost';
EOF

if [ $? -eq 0 ]; then
    log_message "Usuários com nome '$DB_USER' removidos com sucesso."
else
    log_message "Erro ao remover usuários com nome '$DB_USER'."
    exit 1
fi

# Removendo banco de dados
log_message "Removendo o banco de dados $DB_NAME, se existir."
mysql -u "$DB_ROOT_USER" -p"$DB_ROOT_PASSWORD" <<EOF
DROP DATABASE IF EXISTS $DB_NAME;
EOF

if [ $? -eq 0 ]; then
    log_message "Banco de dados $DB_NAME removido com sucesso."
else
    log_message "Erro ao remover o banco de dados $DB_NAME."
    exit 1
fi

# Criando novo banco de dados
log_message "Criando o banco de dados $DB_NAME com charset utf8mb4."
mysql -u "$DB_ROOT_USER" -p"$DB_ROOT_PASSWORD" <<EOF
CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
EOF

if [ $? -eq 0 ]; then
    log_message "Banco de dados $DB_NAME criado com sucesso."
else
    log_message "Erro ao criar o banco de dados $DB_NAME."
    exit 1
fi

# Criando usuário e concedendo permissões
log_message "Criando o usuário $DB_USER e concedendo permissões."
mysql -u "$DB_ROOT_USER" -p"$DB_ROOT_PASSWORD" <<EOF
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_USER_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
EOF

if [ $? -eq 0 ]; then
    log_message "Usuário $DB_USER criado e permissões concedidas com sucesso."
else
    log_message "Erro ao criar o usuário $DB_USER ou conceder permissões."
    exit 1
fi

# Configurando log_bin_trust_function_creators
log_message "Habilitando log_bin_trust_function_creators temporariamente."
mysql -u "$DB_ROOT_USER" -p"$DB_ROOT_PASSWORD" <<EOF
SET GLOBAL log_bin_trust_function_creators = 1;
EOF

if [ $? -eq 0 ]; then
    log_message "Configuração log_bin_trust_function_creators habilitada com sucesso."
else
    log_message "Erro ao habilitar log_bin_trust_function_creators."
    exit 1
fi

# Importando script SQL do Zabbix Proxy
log_message "Importando script SQL do Zabbix Proxy."
cat "$SQL_SCRIPT" | mysql --default-character-set=utf8mb4 -u"$DB_USER" -p"$DB_USER_PASSWORD" "$DB_NAME"

if [ $? -eq 0 ]; then
    log_message "Script SQL importado com sucesso no banco $DB_NAME."
else
    log_message "Erro ao importar o script SQL para o banco $DB_NAME."
    exit 1
fi

# Desabilitando log_bin_trust_function_creators
log_message "Desabilitando log_bin_trust_function_creators."
mysql -u "$DB_ROOT_USER" -p"$DB_ROOT_PASSWORD" <<EOF
SET GLOBAL log_bin_trust_function_creators = 0;
EOF

if [ $? -eq 0 ]; then
    log_message "Configuração log_bin_trust_function_creators desabilitada com sucesso."
else
    log_message "Erro ao desabilitar log_bin_trust_function_creators."
    exit 1
fi

# Reiniciando serviço do Zabbix Proxy
log_message "Reiniciando o serviço $ZABBIX_PROXY_SERVICE."
systemctl start "$ZABBIX_PROXY_SERVICE"

if [ $? -eq 0 ]; then
    log_message "Serviço $ZABBIX_PROXY_SERVICE iniciado com sucesso."
else
    log_message "Erro ao iniciar o serviço $ZABBIX_PROXY_SERVICE."
    exit 1
fi

log_message "Script concluído com sucesso."