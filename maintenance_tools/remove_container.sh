#!/bin/bash

# Função para exibir mensagens com data e hora
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Iniciando limpeza completa do ambiente Docker e pastas específicas..."

# Remover todos os contêineres
log "Removendo todos os contêineres..."
docker ps -aq | xargs -r docker rm -f

# Remover todas as imagens
log "Removendo todas as imagens..."
docker images -q | xargs -r docker rmi -f

# Remover todos os volumes
log "Removendo todos os volumes..."
docker volume ls -q | xargs -r docker volume rm

# Remover todas as redes personalizadas, ignorando redes predefinidas
log "Removendo todas as redes personalizadas..."
docker network ls --filter "type=custom" -q | xargs -r docker network rm

# Realizar uma limpeza geral usando docker system prune
log "Executando docker system prune para limpeza geral..."
docker system prune -af --volumes

# Limpar pastas específicas (opcional)
log "Removendo pastas em /var/lib/zabbix/*..."
rm -rf /var/lib/zabbix/* || log "Nenhuma pasta encontrada para remover em /var/lib/zabbix/"

log "Limpeza completa do Docker e do ambiente concluída com sucesso!"