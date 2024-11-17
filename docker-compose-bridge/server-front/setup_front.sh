#!/bin/bash

# Função de log para registrar data e hora em cada etapa
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "Iniciando configuração do frontend do Zabbix."

# Caminho do arquivo docker-compose para o frontend
FRONT_COMPOSE="docker-compose-front.yml"

log "Construindo imagem Docker para $FRONT_COMPOSE..."
docker-compose --env-file ../configs/.env -f "$FRONT_COMPOSE" build

log "Iniciando contêiner Docker para $FRONT_COMPOSE..."
docker-compose --env-file ../configs/.env -f "$FRONT_COMPOSE" up -d

log "Configuração do frontend do Zabbix concluída."
