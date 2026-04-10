-- =========================================================================
-- Conectarse al contenedor raíz
-- =========================================================================
ALTER SESSION SET CONTAINER = CDB$ROOT;

-- =========================================================================
-- Bloque PL/SQL para limpiar y crear PDB
-- =========================================================================
DECLARE
    v_ruta_base VARCHAR2(200) := 'C:\desarrollo\oracle\product\21c\oradata\XE\';
    v_count NUMBER;
BEGIN
    -- ---------------------------------------------------------------------
    -- Cerrar y dropear PDB si existe
    -- ---------------------------------------------------------------------
    SELECT COUNT(*) INTO v_count
    FROM v$pdbs
    WHERE name = 'PADRONONLINE';

    IF v_count > 0 THEN
        EXECUTE IMMEDIATE 'ALTER PLUGGABLE DATABASE PADRONONLINE CLOSE IMMEDIATE';
        EXECUTE IMMEDIATE 'DROP PLUGGABLE DATABASE PADRONONLINE INCLUDING DATAFILES';
    END IF;

    -- ---------------------------------------------------------------------
    -- Crear PDB nueva usando ruta base
    -- ---------------------------------------------------------------------
    EXECUTE IMMEDIATE '
        CREATE PLUGGABLE DATABASE PADRONONLINE
        ADMIN USER pdb_admin IDENTIFIED BY admin_pwd
        FILE_NAME_CONVERT = (
            ''' || v_ruta_base || 'pdbseed'',
            ''' || v_ruta_base || 'padrononline''
        )';
END;
/

-- Abrir la nueva PDB
ALTER PLUGGABLE DATABASE PADRONONLINE OPEN;
ALTER PLUGGABLE DATABASE PADRONONLINE SAVE STATE;

-- =========================================================================
-- Conectarse a la nueva PDB
-- =========================================================================
ALTER SESSION SET CONTAINER = PADRONONLINE;

-- =========================================================================
-- Bloque PL/SQL para tablespace y usuario
-- =========================================================================
DECLARE
    v_ruta_base VARCHAR2(200) := 'C:\desarrollo\oracle\product\21c\oradata\XE\';
BEGIN
    -- ---------------------------------------------------------------------
    -- DROP TABLESPACE si existe
    -- ---------------------------------------------------------------------
    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLESPACE PADRONONLINE INCLUDING CONTENTS AND DATAFILES';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -959 THEN -- ORA-00959: tablespace no existe
                RAISE;
            END IF;
    END;

    -- ---------------------------------------------------------------------
    -- Crear TABLESPACE
    -- ---------------------------------------------------------------------
    EXECUTE IMMEDIATE '
        CREATE TABLESPACE PADRONONLINE
        DATAFILE ''' || v_ruta_base || 'padrononline\padrononline01.dbf''
        SIZE 100M
        AUTOEXTEND ON
        NEXT 10M
        MAXSIZE UNLIMITED';

    -- ---------------------------------------------------------------------
    -- Crear usuario PADRONONLINE
    -- ---------------------------------------------------------------------
    BEGIN
        EXECUTE IMMEDIATE 'DROP USER PADRONONLINE CASCADE';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -01918 THEN -- ORA-01918: usuario no existe
                RAISE;
            END IF;
    END;

    EXECUTE IMMEDIATE '
        CREATE USER PADRONONLINE IDENTIFIED BY PADRONONLINE
        DEFAULT TABLESPACE PADRONONLINE
        TEMPORARY TABLESPACE TEMP';

    EXECUTE IMMEDIATE 'GRANT CONNECT, RESOURCE, CREATE SESSION, CREATE TABLE, CREATE SEQUENCE TO PADRONONLINE';
END;
/

-- =========================================================================
-- Verificación
-- =========================================================================
-- SELECT name, open_mode FROM v$pdbs;
-- SELECT tablespace_name, status FROM dba_tablespaces WHERE tablespace_name='PADRONONLINE';
-- SELECT username, account_status FROM dba_users WHERE username='PADRONONLINE';