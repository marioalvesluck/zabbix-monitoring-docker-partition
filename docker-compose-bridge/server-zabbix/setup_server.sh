#!/bin/bash

# Função de log
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "Iniciando configuração do Zabbix Server."

# Caminho para o PSK do servidor
SERVER_PATH="/var/lib/zabbix/zabbix-server/enc"
SERVER_PSK_FILE="${SERVER_PATH}/zabbix_server.psk"

# Criando diretórios e gerando PSK
log "Criando diretório para PSK do servidor..."
mkdir -p "$SERVER_PATH"

log "Gerando chave PSK para o servidor..."
SERVER_PSK=$(openssl rand -hex 32)
echo "$SERVER_PSK" > "$SERVER_PSK_FILE"

log "Ajustando permissões do arquivo PSK..."
chmod 775 "$SERVER_PSK_FILE"

# Construindo e iniciando o contêiner do Zabbix Server
log "Construindo imagem Docker do Zabbix Server..."
docker-compose -f docker-compose-server.yml build

log "Iniciando contêiner do Zabbix Server..."
docker-compose -f docker-compose-server.yml up -d

log "Configuração do Zabbix Server concluída."
