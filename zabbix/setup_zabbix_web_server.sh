#!/bin/bash

# Função de log para registrar data e hora em cada etapa
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Início do script
log "Início da execução do script."

# Definindo caminhos para Zabbix Proxy e Zabbix Server
SERVER_PATH="/var/lib/zabbix/zabbix-server/enc"

# Arquivos PSK
SERVER_PSK_FILE="${SERVER_PATH}/zabbix_server.psk"

# Criação das pastas, se ainda não existirem
log "Criando estrutura de diretórios..."
mkdir -p "$SERVER_PATH"

# Função para gerar chave de criptografia
generate_psk() {
    openssl rand -hex 32
}

log "Gerando chaves de criptografia..."

SERVER_PSK=$(generate_psk)

# Salvando as chaves nos arquivos correspondentes
log "Salvando chaves de criptografia..."
echo "$SERVER_PSK" | tee "$SERVER_PSK_FILE"

# Ajuste de permissões
log "Ajustando permissões dos arquivos PSK..."
chmod 775  "$SERVER_PSK_FILE"

log "Configuração de PSK concluída."
log "Zabbix Server PSK salvo em: $SERVER_PSK_FILE"

# Construindo imagens personalizadas e inicializando o docker-compose
log "Construindo imagens Docker personalizadas..."
docker-compose --env-file ../configs/.env -f docker-compose.yml  build

log "Iniciando containers Docker..."
docker-compose --env-file ../configs/.env -f docker-compose.yml up -d

log "Iniciando containers Docker dos Agentes..."
docker compose -f docker-compose-agent2.yml up -d

log "Containers Docker iniciados com sucesso."

# Término do script
log "Término da execução do script."
