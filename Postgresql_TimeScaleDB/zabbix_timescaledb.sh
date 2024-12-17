#!/bin/bash

# Configuração de Variáveis
POSTGRESQL_VERSION=16
TIMESCALEDB_VERSION=2.15.3
DATABASE_NAME="zabbix"
DATABASE_USER="zabbix"tail
DATABASE_PASSWORD="zabbix"
PRODUCT_VERSION=$(rpm -E %{rhel})

# Ajustes para o ambiente de homologação
RETENTION_HISTORY=86400        # 1 dia em segundos
RETENTION_TRENDS=604800        # 7 dias em segundos
COMPRESSION_HISTORY=259200     # 3 dias em segundos

PG_DATA_DIR="/var/lib/pgsql/$POSTGRESQL_VERSION/data"
TIMESCALEDB_REPO_FILE="/etc/yum.repos.d/timescale-timescaledb.repo"
CRON_JOB_FILE="/etc/cron.d/cleanup_zabbix_data"
LOG_FILE="/var/log/zabbix_timescaledb_install.log"

# Função para log com marcação de tempo
log() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

# Função para verificar erros e interromper o script
check_error() {
    if [ $? -ne 0 ]; then
        log "Erro detectado: $1"
        exit 1
    fi
}


log "INSTALAÇÃO DO TIMESCALEDB - Configurando repositório"

sudo tee "$TIMESCALEDB_REPO_FILE" > /dev/null <<EOL
[timescale_timescaledb]
name=timescale_timescaledb
baseurl=https://packagecloud.io/timescale/timescaledb/el/$PRODUCT_VERSION/\$basearch
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/timescale/timescaledb/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300
EOL
check_error "Falha ao configurar o repositório do TimescaleDB."


log "INSTALAÇÃO DO TIMESCALEDB - Instalando pacotes"

dnf -y install timescaledb-2-postgresql-$POSTGRESQL_VERSION-$TIMESCALEDB_VERSION timescaledb-2-loader-postgresql-$POSTGRESQL_VERSION-$TIMESCALEDB_VERSION
check_error "Falha na instalação dos pacotes do TimescaleDB."


log "PARANDO O ZABBIX SERVER"

systemctl stop zabbix-server
check_error "Falha ao parar o serviço Zabbix Server."


log "CONFIGURAÇÃO DO POSTGRESQL - Ajustes no arquivo postgresql.conf"

{
    echo "shared_preload_libraries = 'timescaledb'"
    echo "timescaledb.license=timescale"
} >> "$PG_DATA_DIR/postgresql.conf"
sudo sed -i "s/max_connections = 20/max_connections = 50/" "$PG_DATA_DIR/postgresql.conf"
check_error "Falha ao configurar o arquivo postgresql.conf."


log "TIMESCALEDB - Inicializando configurações do PostgreSQL"

sudo systemctl restart postgresql-$POSTGRESQL_VERSION
check_error "Falha ao reiniciar o PostgreSQL."


log "TIMESCALEDB - Executando timescaledb-tune para ajuste de configurações"

sudo -u postgres timescaledb-tune --quiet --yes --pg-config="/usr/pgsql-$POSTGRESQL_VERSION/bin/pg_config"
check_error "Falha ao executar o timescaledb-tune."


log "HABILITAÇÃO DO TIMESCALEDB - Ativando extensão TimescaleDB no banco de dados $DATABASE_NAME"

echo "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;" | sudo -u postgres psql "$DATABASE_NAME"
check_error "Falha ao criar a extensão TimescaleDB."


log "TIMESCALEDB - Migrando schema do Zabbix para TimescaleDB"
# Versao do zabbix 6
#sudo -u zabbix psql "$DATABASE_NAME" < /usr/share/zabbix-sql-scripts/postgresql/timescaledb/schema.sql
# Versao do zabbix 7 
sudo -u zabbix psql "$DATABASE_NAME" < /usr/share/zabbix/sql-scripts/postgresql/timescaledb/schema.sql
check_error "Falha ao migrar o schema do Zabbix para o TimescaleDB."


log "PARTICIONAMENTO - Criando hypertables para tabelas 'history' e 'trends'"

sudo -u postgres psql "$DATABASE_NAME" <<EOF
SELECT create_hypertable('history', 'clock', if_not_exists => TRUE);
SELECT create_hypertable('trends', 'clock', if_not_exists => TRUE);
EOF
check_error "Falha ao criar hypertables para as tabelas 'history' e 'trends'."


log "CONFIGURAÇÃO MANUAL DE POLÍTICA DE RETENÇÃO - Criando função e cron job para limpar dados antigos"

sudo -u postgres psql "$DATABASE_NAME" <<EOF
CREATE OR REPLACE FUNCTION cleanup_old_data() RETURNS void AS \$\$
BEGIN
    DELETE FROM history WHERE clock < EXTRACT(EPOCH FROM now() - INTERVAL '1 day');
    DELETE FROM trends WHERE clock < EXTRACT(EPOCH FROM now() - INTERVAL '7 days');
END;
\$\$ LANGUAGE plpgsql;
EOF
check_error "Falha ao criar a função de limpeza de dados antigos."

echo "0 0 * * * postgres psql -d zabbix -c 'SELECT cleanup_old_data();' >> /var/log/cleanup_zabbix_data.log 2>&1" | sudo tee "$CRON_JOB_FILE" > /dev/null
check_error "Falha ao criar o cron job para limpeza de dados."


log "CONFIGURANDO POLÍTICA DE COMPRESSÃO PARA HISTORY"

sudo -u postgres psql "$DATABASE_NAME" <<EOF
ALTER TABLE history SET (timescaledb.compress, timescaledb.compress_segmentby = 'itemid');
SELECT add_compression_policy('history', compress_after => $COMPRESSION_HISTORY);
EOF
check_error "Falha ao configurar a política de compressão para 'history'."


log "INICIALIZANDO O ZABBIX SERVER"

systemctl start zabbix-server
check_error "Falha ao iniciar o serviço Zabbix Server."


log "CONFIGURAÇÃO COMPLETA DO TIMESCALEDB PARA O ZABBIX"

log "TimescaleDB configurado com sucesso para o banco de dados $DATABASE_NAME!"
