#!/bin/bash

# Caminho para o arquivo .env no diretório anterior
ENV_FILE="../.env"

# Carregar variáveis de ambiente do arquivo .env, ignorando linhas comentadas
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
else
    echo "Arquivo .env não encontrado em $ENV_FILE! Certifique-se de que as credenciais do banco estão no diretório correto."
    exit 1
fi

# Nome do contêiner do banco de dados
CONTAINER_NAME="zabbix-monitoring-docker-partition-zabbix-db-1"
BACKUP_DIR="./backups/$(date +%Y%m%d)"
LOG_DIR="/var/log/backup_mysql"
LOG_FILE="${LOG_DIR}/$(date +%Y-%m-%d-%H-%M-%S)-backup_log.txt"

# Criar diretório de backup e de log se não existirem
mkdir -p "${BACKUP_DIR}"
mkdir -p "${LOG_DIR}"

# Configuração para logar a saída e erros em um arquivo de log detalhado
exec > >(tee -i "${LOG_FILE}") 2>&1

# Função para mostrar ajuda
mostrar_ajuda() {
    echo "Uso: $0 [opção]"
    echo ""
    echo "Opções:"
    echo "  --create       Cria um backup completo do banco de dados e o compacta."
    echo "  --conf         Faz backup apenas das configurações (hosts, etc.) do Zabbix."
    echo "  --help         Exibe esta mensagem de ajuda."
    echo ""
    echo "Exemplo para backup completo:"
    echo "  $0 --create"
    echo ""
    echo "Exemplo para backup apenas das configurações:"
    echo "  $0 --conf"
    echo ""
    echo "Para restaurar um backup:"
    echo "  docker exec -i ${CONTAINER_NAME} mysql -u root -p'[SENHA]' ${MYSQL_DATABASE} < caminho_do_arquivo.sql"
    exit 0
}

# Função para criar um backup completo
criar_backup_completo() {
    BACKUP_FILENAME="zabbix_backup_full_$(date +%Y%m%d_%H%M%S).sql"
    ZIP_FILENAME="${BACKUP_FILENAME}.zip"

    echo "Iniciando o backup completo do banco de dados '${MYSQL_DATABASE}' no contêiner '${CONTAINER_NAME}'..."

    docker exec -i "${CONTAINER_NAME}" mysqldump -u root -p"${MYSQL_ROOT_PASSWORD}" "${MYSQL_DATABASE}" > "${BACKUP_DIR}/${BACKUP_FILENAME}" 2>/dev/null

    if [ $? -eq 0 ]; then
        zip "${BACKUP_DIR}/${ZIP_FILENAME}" "${BACKUP_DIR}/${BACKUP_FILENAME}" && rm "${BACKUP_DIR}/${BACKUP_FILENAME}"
        echo "Backup completo concluído e salvo como '${BACKUP_DIR}/${ZIP_FILENAME}'."
    else
        echo "Erro ao criar o backup completo do banco de dados."
        exit 1
    fi
}

# Função para criar backup apenas das configurações
criar_backup_configuracao() {
    BACKUP_FILENAME="zabbix_config_backup_$(date +%Y%m%d_%H%M%S).sql"
    ZIP_FILENAME="${BACKUP_FILENAME}.zip"

    echo "Listando tabelas de configuração do banco de dados '${MYSQL_DATABASE}' no contêiner '${CONTAINER_NAME}'..."

    # Lista tabelas que contenham "hosts" no nome
    TABELAS_HOSTS=$(docker exec -i "${CONTAINER_NAME}" mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW TABLES FROM ${MYSQL_DATABASE} LIKE '%hosts%';" | tail -n +2 2>/dev/null)

    if [ -z "$TABELAS_HOSTS" ]; then
        echo "Nenhuma tabela correspondente encontrada para backup de configuração."
        exit 1
    fi

    echo "Tabelas de configuração encontradas: $TABELAS_HOSTS"
    
    echo "Iniciando o backup das configurações do banco de dados '${MYSQL_DATABASE}' no contêiner '${CONTAINER_NAME}'..."

    docker exec -i "${CONTAINER_NAME}" mysqldump -u root -p"${MYSQL_ROOT_PASSWORD}" "${MYSQL_DATABASE}" \
        --no-data --tables $TABELAS_HOSTS > "${BACKUP_DIR}/${BACKUP_FILENAME}" 2>/dev/null

    if [ $? -eq 0 ]; then
        zip "${BACKUP_DIR}/${ZIP_FILENAME}" "${BACKUP_DIR}/${BACKUP_FILENAME}" && rm "${BACKUP_DIR}/${BACKUP_FILENAME}"
        echo "Backup das configurações concluído e salvo como '${BACKUP_DIR}/${ZIP_FILENAME}'."
    else
        echo "Erro ao criar o backup de configuração do banco de dados."
        exit 1
    fi
}

# Verifica o argumento passado ou exibe ajuda se nenhum argumento for fornecido
if [ $# -eq 0 ]; then
    mostrar_ajuda
fi

case "$1" in
    --create)
        criar_backup_completo
        ;;
    --conf)
        criar_backup_configuracao
        ;;
    --help)
        mostrar_ajuda
        ;;
    *)
        echo "Opção inválida: $1"
        mostrar_ajuda
        ;;
esac
