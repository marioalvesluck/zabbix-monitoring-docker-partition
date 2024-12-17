#!/bin/bash

# Função de log para registrar data e hora em cada etapa
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Início do script
log "Início da execução do script."

# Definindo caminhos para Zabbix Proxy e Zabbix Server
PROXY_PATH="/var/lib/zabbix/zabbix-proxy/enc"
SERVER_PATH="/var/lib/zabbix/zabbix-server/enc"

# Arquivos PSK
PROXY_PSK_FILE="${PROXY_PATH}/zabbix_proxy.psk"
SERVER_PSK_FILE="${SERVER_PATH}/zabbix_server.psk"

# Criação das pastas, se ainda não existirem
log "Criando estrutura de diretórios..."
mkdir -p "$PROXY_PATH" "$SERVER_PATH"

# Função para gerar chave de criptografia
generate_psk() {
    openssl rand -hex 32
}

log "Gerando chaves de criptografia..."

PROXY_PSK=$(generate_psk)
SERVER_PSK=$(generate_psk)

# Salvando as chaves nos arquivos correspondentes
log "Salvando chaves de criptografia..."
echo "$PROXY_PSK" | tee "$PROXY_PSK_FILE"
echo "$SERVER_PSK" | tee "$SERVER_PSK_FILE"

# Ajuste de permissões
log "Ajustando permissões dos arquivos PSK..."
chmod 775 "$PROXY_PSK_FILE" "$SERVER_PSK_FILE"

log "Configuração de PSK concluída."
log "Zabbix Proxy PSK salvo em: $PROXY_PSK_FILE"
log "Zabbix Server PSK salvo em: $SERVER_PSK_FILE"

# Construindo imagens personalizadas e inicializando o docker-compose
log "Construindo imagens Docker personalizadas..."
docker-compose --env-file ../../configs/.env  build

log "Iniciando containers Docker..."
docker-compose --env-file ../../configs/.env up -d

log "Containers Docker iniciados com sucesso."

# Término do script
log "Término da execução do script."
