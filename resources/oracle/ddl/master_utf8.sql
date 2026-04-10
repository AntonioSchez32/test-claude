-- =========================================================================
-- master_utf8.sql: Script maestro PADRONONLINE con UTF-8
-- =========================================================================

-- Configuración de SQL*Plus
SET TERMOUT ON
SET ECHO ON
SET FEEDBACK ON
SET VERIFY ON
SET SERVEROUTPUT ON

-- ================================
-- Control de errores: detener al fallar
-- ================================
WHENEVER SQLERROR EXIT SQL.SQLCODE

-- Mensaje inicial
PROMPT ================================
PROMPT Ejecutando scripts PADRONONLINE (UTF-8)
PROMPT ================================

-- ================================
-- Conectarse como SYSDBA (opcional)
-- ================================
-- PROMPT Conectando como SYSDBA...
-- CONNECT SYS/muyfacilmuylarga@localhost:1521/XE AS SYSDBA

-- Se abre la base de datos
-- ALTER DATABASE OPEN;

-- ================================
-- Ejecutar scripts en orden
-- ================================
PROMPT Ejecutando 01_crear_pdb_y_tablespace.sql
@01_crear_pdb_y_tablespace.sql

PROMPT Ejecutando 02-ddl-estructura.sql
@02-ddl-estructura.sql

PROMPT Ejecutando 03-ddl-permisos.sql
@03-ddl-permisos.sql

-- PROMPT Ejecutando 04-insertar-datos.sql
@04-insertar-datos.sql

PROMPT Ejecutando 05-ddl-indices.sql
@05-ddl-indices.sql

-- ================================
-- Mensaje final (solo se muestra si todo salió bien)
-- ================================
PROMPT ================================
PROMPT Todos los scripts se ejecutaron correctamente
PROMPT ================================

-- Restaurar configuración
SET TERMOUT ON
SET ECHO ON
SET FEEDBACK ON
SET VERIFY ON
SET SERVEROUTPUT ON

EXIT
