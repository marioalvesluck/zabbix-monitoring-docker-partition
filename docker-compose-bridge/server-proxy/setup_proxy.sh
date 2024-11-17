#!/bin/bash

# Função de log
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "Iniciando configuração do Zabbix Proxy."

# Caminho para o PSK do proxy
PROXY_PATH="/var/lib/zabbix/zabbix-proxy/enc"
PROXY_PSK_FILE="${PROXY_PATH}/zabbix_proxy.psk"

# Criando diretórios e gerando PSK
log "Criando diretório para PSK do proxy..."
mkdir -p "$PROXY_PATH"

log "Gerando chave PSK para o proxy..."
PROXY_PSK=$(openssl rand -hex 32)
echo "$PROXY_PSK" > "$PROXY_PSK_FILE"

log "Ajustando permissões do arquivo PSK..."
chmod 775 "$PROXY_PSK_FILE"

# Construindo e iniciando o contêiner do Zabbix Proxy
log "Construindo imagem Docker do Zabbix Proxy..."
docker-compose --env-file ../configs/.env -f docker-compose-proxy.yml build

log "Iniciando contêiner do Zabbix Proxy..."
docker-compose --env-file ../configs/.env -f docker-compose-proxy.yml up -d

log "Configuração do Zabbix Proxy concluída."
