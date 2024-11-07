#!/bin/bash

# Remover todos os contêineres
echo "Removendo todos os contêineres..."
docker rm -f $(docker ps -aq)

# Remover todas as imagens
echo "Removendo todas as imagens..."
docker rmi -f $(docker images -q)

# Remover todos os volumes
echo "Removendo todos os volumes..."
docker volume rm $(docker volume ls -q)

# Remover todas as redes personalizadas, ignorando redes predefinidas
echo "Removendo todas as redes personalizadas..."
docker network rm $(docker network ls --filter "type=custom" -q)

# Remover pastas em /var/lib/zabbix/*
#echo "Removendo pastas em /var/lib/zabbix/*..."
#rm -rf /var/lib/zabbix/*

echo "Limpeza do Docker e das pastas do Zabbix concluída com sucesso."
