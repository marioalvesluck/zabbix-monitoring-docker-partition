#!/bin/bash

# Função de log para registrar data e hora em cada etapa
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Início do script
log "Início da execução do script."

# Definindo caminhos para Zabbix Proxy e Zabbix Server
PROXY_PATH="/var/lib/zabbix/zabbix-proxy/enc"

# Arquivos PSK
PROXY_PSK_FILE="${PROXY_PATH}/zabbix_proxy.psk"

# Criação das pastas, se ainda não existirem
log "Criando estrutura de diretórios..."
mkdir -p "$PROXY_PATH"

# Função para gerar chave de criptografia
generate_psk() {
    openssl rand -hex 32
}

log "Gerando chaves de criptografia..."

PROXY_PSK=$(generate_psk)

# Salvando as chaves nos arquivos correspondentes
log "Salvando chaves de criptografia..."
echo "$PROXY_PSK" | tee "$PROXY_PSK_FILE"

# Ajuste de permissões
log "Ajustando permissões dos arquivos PSK..."
chmod 775 "$PROXY_PSK_FILE"

log "Configuração de PSK concluída."
log "Zabbix Proxy PSK salvo em: $PROXY_PSK_FILE"

# Término do script
log "Término da execução do script."