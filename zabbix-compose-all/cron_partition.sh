#!/bin/bash

LOG_FILE="/var/log/zabbix_partition_maintenance.log"
MAX_SIZE=10485760  # 10 MB em bytes

# Rotacionar o log se ele ultrapassar o tamanho máximo
if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE") -ge $MAX_SIZE ]; then
    mv "$LOG_FILE" "${LOG_FILE}.$(date +'%Y%m%d%H%M%S')"
    echo "Arquivo de log rotacionado em $(date)" > "$LOG_FILE"
fi

# Registrar a execução com data e hora
echo "Script executado em: $(date)" >> "$LOG_FILE"

# Executar a manutenção de partição
MYSQL_PWD="Serverzabbix!" mysql -h "zabbix-db" -u "zabbix" "zabbix" -e "CALL partition_maintenance_all('zabbix');" >> "$LOG_FILE" 2>&1

# Verificar o status das tabelas após a manutenção
echo "Status da tabela 'history':" >> "$LOG_FILE"
MYSQL_PWD="Serverzabbix!" mysql -h "zabbix-db" -u "zabbix" "zabbix" -e "SHOW CREATE TABLE history\G" >> "$LOG_FILE" 2>&1

echo "Status da tabela 'trends':" >> "$LOG_FILE"
MYSQL_PWD="Serverzabbix!" mysql -h "zabbix-db" -u "zabbix" "zabbix" -e "SHOW CREATE TABLE trends\G" >> "$LOG_FILE" 2>&1
