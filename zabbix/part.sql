DELIMITER $$

-- Procedimento para criar partição
CREATE PROCEDURE `partition_create`(
    IN SCHEMANAME VARCHAR(64),
    IN TABLENAME VARCHAR(64),
    IN PARTITIONNAME VARCHAR(64),
    IN CLOCK INT
)
BEGIN
    DECLARE RETROWS INT;

    -- Verifica se a partição já existe
    SELECT COUNT(1) INTO RETROWS
    FROM information_schema.partitions
    WHERE table_schema = SCHEMANAME
      AND table_name = TABLENAME
      AND partition_description >= CLOCK;

    -- Cria a partição se não existir
    IF RETROWS = 0 THEN
        SET @sql = CONCAT(
            'ALTER TABLE ', SCHEMANAME, '.', TABLENAME,
            ' ADD PARTITION (PARTITION ', PARTITIONNAME,
            ' VALUES LESS THAN (', CLOCK, '));'
        );
        PREPARE STMT FROM @sql;
        EXECUTE STMT;
        DEALLOCATE PREPARE STMT;

        -- Exibe mensagem de sucesso
        SELECT CONCAT("Partição criada: ", PARTITIONNAME) AS msg;
    END IF;
END$$

-- Procedimento para remover partições antigas
CREATE PROCEDURE `partition_drop`(
    IN SCHEMANAME VARCHAR(64),
    IN TABLENAME VARCHAR(64),
    IN DELETE_BELOW_PARTITION_DATE BIGINT
)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE drop_part_name VARCHAR(16);
    DECLARE myCursor CURSOR FOR
        SELECT partition_name
        FROM information_schema.partitions
        WHERE table_schema = SCHEMANAME
          AND table_name = TABLENAME
          AND CAST(SUBSTRING(partition_name FROM 2) AS UNSIGNED) < DELETE_BELOW_PARTITION_DATE;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    SET @alter_header = CONCAT("ALTER TABLE ", SCHEMANAME, ".", TABLENAME, " DROP PARTITION ");
    SET @drop_partitions = "";

    -- Loop para coletar partições a serem excluídas
    OPEN myCursor;
    read_loop: LOOP
        FETCH myCursor INTO drop_part_name;
        IF done THEN
            LEAVE read_loop;
        END IF;
        SET @drop_partitions = IF(@drop_partitions = "", drop_part_name, CONCAT(@drop_partitions, ",", drop_part_name));
    END LOOP;

    -- Executa a exclusão das partições antigas
    IF @drop_partitions != "" THEN
        SET @full_sql = CONCAT(@alter_header, @drop_partitions, ";");
        PREPARE STMT FROM @full_sql;
        EXECUTE STMT;
        DEALLOCATE PREPARE STMT;

        SELECT CONCAT(SCHEMANAME, ".", TABLENAME) AS `table`, @drop_partitions AS `partitions_deleted`;
    ELSE
        SELECT CONCAT(SCHEMANAME, ".", TABLENAME) AS `table`, "N/A" AS `partitions_deleted`;
    END IF;
END$$

-- Procedimento para verificar e criar partição inicial
CREATE PROCEDURE `partition_verify`(
    IN SCHEMANAME VARCHAR(64),
    IN TABLENAME VARCHAR(64),
    IN HOURLYINTERVAL INT
)
BEGIN
    DECLARE PARTITION_NAME VARCHAR(16);
    DECLARE RETROWS INT;
    DECLARE FUTURE_TIMESTAMP TIMESTAMP;

    SELECT COUNT(1) INTO RETROWS
    FROM information_schema.partitions
    WHERE table_schema = SCHEMANAME AND table_name = TABLENAME AND partition_name IS NULL;

    IF RETROWS = 1 THEN
        SET FUTURE_TIMESTAMP = TIMESTAMPADD(HOUR, HOURLYINTERVAL, CONCAT(CURDATE(), " 00:00:00"));
        SET PARTITION_NAME = DATE_FORMAT(CURDATE(), 'p%Y%m%d%H00');

        SET @__PARTITION_SQL = CONCAT(
            "ALTER TABLE ", SCHEMANAME, ".", TABLENAME,
            " PARTITION BY RANGE(`clock`) (PARTITION ",
            PARTITION_NAME, " VALUES LESS THAN (", UNIX_TIMESTAMP(FUTURE_TIMESTAMP), "));"
        );

        PREPARE STMT FROM @__PARTITION_SQL;
        EXECUTE STMT;
        DEALLOCATE PREPARE STMT;
    END IF;
END$$

-- Procedimento para manutenção de partições (criação e exclusão)
CREATE PROCEDURE `partition_maintenance`(
    IN SCHEMA_NAME VARCHAR(32),
    IN TABLE_NAME VARCHAR(32),
    IN KEEP_DATA_DAYS INT,
    IN HOURLY_INTERVAL INT,
    IN CREATE_NEXT_INTERVALS INT
)
BEGIN
    DECLARE OLDER_THAN_PARTITION_DATE VARCHAR(16);
    DECLARE PARTITION_NAME VARCHAR(16);
    DECLARE OLD_PARTITION_NAME VARCHAR(16);
    DECLARE LESS_THAN_TIMESTAMP INT;
    DECLARE CUR_TIME INT;

    CALL partition_verify(SCHEMA_NAME, TABLE_NAME, HOURLY_INTERVAL);
    SET CUR_TIME = UNIX_TIMESTAMP(DATE_FORMAT(NOW(), '%Y-%m-%d 00:00:00'));

    SET @__interval = 1;
    create_loop: LOOP
        IF @__interval > CREATE_NEXT_INTERVALS THEN
            LEAVE create_loop;
        END IF;

        SET LESS_THAN_TIMESTAMP = CUR_TIME + (HOURLY_INTERVAL * @__interval * 3600);
        SET PARTITION_NAME = FROM_UNIXTIME(CUR_TIME + HOURLY_INTERVAL * (@__interval - 1) * 3600, 'p%Y%m%d%H00');

        IF(PARTITION_NAME != OLD_PARTITION_NAME) THEN
            CALL partition_create(SCHEMA_NAME, TABLE_NAME, PARTITION_NAME, LESS_THAN_TIMESTAMP);
        END IF;

        SET @__interval=@__interval+1;
        SET OLD_PARTITION_NAME = PARTITION_NAME;
    END LOOP;

    SET OLDER_THAN_PARTITION_DATE = DATE_FORMAT(DATE_SUB(NOW(), INTERVAL KEEP_DATA_DAYS DAY), '%Y%m%d0000');
    CALL partition_drop(SCHEMA_NAME, TABLE_NAME, OLDER_THAN_PARTITION_DATE);
END$$

-- Procedimento para manutenção de partições para múltiplas tabelas
CREATE PROCEDURE `partition_maintenance_all`(
    IN SCHEMA_NAME VARCHAR(32)
)
BEGIN
    -- Retenção de dados personalizada para tabelas de histórico e tendências
    CALL partition_maintenance(SCHEMA_NAME, 'history', 14, 24, 14);      --24 partições diárias, mantendo dados por 14 dias
    CALL partition_maintenance(SCHEMA_NAME, 'history_log', 14, 24, 14);
    CALL partition_maintenance(SCHEMA_NAME, 'history_str', 14, 24, 14);
    CALL partition_maintenance(SCHEMA_NAME, 'history_text', 14, 24, 14);
    CALL partition_maintenance(SCHEMA_NAME, 'history_uint', 14, 24, 14);

    -- Para tabelas de trends (dados agregados e menos volumosos)
    CALL partition_maintenance(SCHEMA_NAME, 'trends', 365, 720, 12);     -- 12 partições mensais, mantendo dados por 365 dias
    CALL partition_maintenance(SCHEMA_NAME, 'trends_uint', 365, 720, 12); -- 12 partições mensais, mantendo dados por 365 dias
END$$

DELIMITER ;