#!/bin/bash

echo "Iniciando configuração do Beezap2..."

# Opções disponíveis
echo "Escolha uma ação:"
echo "1) Ler QRCode"
echo "2) Mostrar Grupos e IDs do WhatsApp"
echo "3) Iniciar API Principal com PM2"
echo "4) Sair"

read -p "Digite o número da opção desejada: " OPTION

case $OPTION in
  1)
    echo "Executando leitura de QRCode..."
    node /opt/beezap2/index.js
    ;;
  2)
    echo "Mostrando grupos e IDs do WhatsApp..."
    node /opt/beezap2/beeid3.js
    ;;
  3)
    echo "Configurando API principal com PM2..."
    pm2 start /opt/beezap2/beezap2.js --name beezap2-api
    pm2 startup
    pm2 save
    echo "API configurada com sucesso para iniciar com PM2."
    ;;
  4)
    echo "Saindo do script."
    exit 0
    ;;
  *)
    echo "Opção inválida. Tente novamente."
    ;;
esac
