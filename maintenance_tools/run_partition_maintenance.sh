#!/bin/bash
{
    echo "Status das tabelas antes da execução do partition_maintenance:"
    docker exec -it zabbix_all-zabbix-db-1 mysql -u root -pServerzabbix! zabbix -e "SHOW CREATE TABLE history\G"
    docker exec -it zabbix_all-zabbix-db-1 mysql -u root -pServerzabbix! zabbix -e "SHOW CREATE TABLE trends\G"

    echo "Executando partition_maintenance em $(date):"
    docker exec -it zabbix_all-zabbix-db-1 bash /etc/cron.daily/partition_maintenance

} >> /var/log/zabbix_partition_maintenance.log 2>&1

