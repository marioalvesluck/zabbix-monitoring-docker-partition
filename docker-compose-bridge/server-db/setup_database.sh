#!/bin/bash

# Função de log para registrar data e hora em cada etapa
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "Iniciando configuração do banco de dados."

# Caminho do arquivo docker-compose para o banco de dados
DB_COMPOSE="docker-compose-db.yml"

log "Construindo imagem Docker para $DB_COMPOSE..."

docker-compose --env-file ../../configs/.env -f "$DB_COMPOSE" build

log "Iniciando contêiner Docker para $DB_COMPOSE..."
docker-compose --env-file ../../configs/.env -f "$DB_COMPOSE" up -d

log "Configuração do banco de dados concluída."
