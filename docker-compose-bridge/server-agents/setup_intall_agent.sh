#!/bin/bash

# Função de log
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "Iniciando configuração do Zabbix Agent."

# Variáveis configuráveis
DOCKER_COMPOSE_FILE="docker-compose-agents.yml"
ENV_FILE="../configs/.env"

# Construindo a imagem do Docker
log "Construindo imagem Docker do Zabbix Agent..."
docker compose --env-file "$ENV_FILE" -f "$DOCKER_COMPOSE_FILE" build

# Iniciando o contêiner
log "Iniciando contêiner do Zabbix Agent..."
docker compose --env-file "$ENV_FILE" -f "$DOCKER_COMPOSE_FILE" up -d

log "Configuração do Zabbix Agent concluída."