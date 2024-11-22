-- Criar usuário administrativo com privilégios completos
CREATE USER 'db_admin'@'%' IDENTIFIED BY 'AdminStrongPass123!';
GRANT ALL PRIVILEGES ON *.* TO 'db_admin'@'%' WITH GRANT OPTION;

-- Criar usuário para o Grafana com privilégios somente de leitura
CREATE USER 'grafana_user'@'%' IDENTIFIED BY 'GrafanaReadOnlyPass!';
GRANT SELECT ON zabbix.* TO 'grafana_user'@'%';

-- Aplicar mudanças de privilégios
FLUSH PRIVILEGES;
