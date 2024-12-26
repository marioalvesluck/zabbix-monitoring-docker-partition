#!/bin/bash

# Função de log
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "Iniciando configuração do Zabbix Proxy com MySQL."

# Configurações do proxy
PROXY_NAME="proxy-mysql"
DOCKER_COMPOSE_FILE="docker-compose-proxy-mysql.yml"

# Caminho para o PSK do proxy
PROXY_PATH="/var/lib/zabbix/zabbix-proxy-mysql/enc"
PROXY_PSK_FILE="${PROXY_PATH}/${PROXY_NAME}.psk"

# Criando diretórios e gerando PSK
log "Criando diretório para PSK do proxy..."
mkdir -p "$PROXY_PATH"

log "Gerando chave PSK para o proxy..."
PROXY_PSK=$(openssl rand -hex 32)
echo "$PROXY_PSK" > "$PROXY_PSK_FILE"

log "Ajustando permissões do arquivo PSK..."
chmod 775 "$PROXY_PSK_FILE"

# Subindo os serviços
log "Iniciando contêiner do Zabbix Proxy com MySQL..."
docker compose -f "$DOCKER_COMPOSE_FILE" --env-file ../configs/.env up -d

log "Configuração do Zabbix Proxy com MySQL concluída."

# Exibindo as informações de configuração
echo ""
echo "=== Configuração do Proxy ==="
echo "Proxy Hostname: ${PROXY_NAME}"
echo "TLS PSK Identity: ${PROXY_NAME}"
echo "PSK Criada: ${PROXY_PSK}"
echo "================================"
