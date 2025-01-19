-- Ajuste de configurações depreciadas
SET GLOBAL host_cache_size = 0;

-- Configuração de replicação e logs binários
SET GLOBAL binlog_expire_logs_seconds = 604800;

-- Ajuste de segurança para evitar erros futuros
SET GLOBAL sql_mode = 'STRICT_TRANS_TABLES';

-- Criar usuários adicionais
CREATE USER 'zabbix_server'@'%' IDENTIFIED BY 'ServerPassword!';
CREATE USER 'zabbix_grafana'@'%' IDENTIFIED BY 'GrafanaPassword!';

-- Conceder permissões ao usuário zabbix_server
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix_server'@'%';

-- Conceder permissões ao usuário zabbix_grafana
GRANT SELECT ON zabbix.* TO 'zabbix_grafana'@'%';

-- Aplicar as mudanças de privilégios
FLUSH PRIVILEGES;
