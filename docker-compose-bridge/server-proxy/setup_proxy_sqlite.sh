#!/bin/bash

# Função de log
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "Iniciando configuração do Zabbix Proxy."

PROXY_NAME="proxy-boston"
DOCKER_COMPOSE_FILE="docker-compose-proxy-boston.yml"


ENV_FILE="../configs/.env"

# Caminho para o PSK do proxy
PROXY_PATH="/var/lib/zabbix/zabbix-proxy/enc"
PROXY_PSK_FILE="${PROXY_PATH}/${PROXY_NAME}.psk"

# Criando diretórios e gerando PSK
log "Criando diretório para PSK do proxy..."
mkdir -p "$PROXY_PATH"

log "Gerando chave PSK para o proxy..."
PROXY_PSK=$(openssl rand -hex 32)
echo "$PROXY_PSK" > "$PROXY_PSK_FILE"

log "Ajustando permissões do arquivo PSK..."
chmod 775 "$PROXY_PSK_FILE"

# Construindo a imagem do Docker
log "Construindo imagem Docker do Zabbix Proxy..."
docker compose --env-file "$ENV_FILE" -f "$DOCKER_COMPOSE_FILE" build

# Iniciando o contêiner
log "Iniciando contêiner do Zabbix Proxy..."
docker compose --env-file "$ENV_FILE" -f "$DOCKER_COMPOSE_FILE" up -d

log "Configuração do Zabbix Proxy concluída."

# Exibindo as informações de configuração
echo ""
echo "=== Configuração do Proxy ==="
echo "ZBX_PROXY_BALTIMORE_HOSTNAME=${PROXY_NAME}"
echo "ZBX_PROXY_BALTIMORE_TLSPSKIDENTITY=${PROXY_NAME}"
echo "PSK Criada: ${PROXY_PSK}"
echo "================================"