@echo off

set ORA_USER=PADRONONLINE
set ORA_PASS=PADRONONLINE
set ORA_SERVICE=PADRONONLINE
set ORA_DIR=PADRONONLINE_DUMP
set DUMPFILE=padrononline_snapshot.dmp
set LOGFILE=padrononline_snapshot.log

echo ============================================
echo Configurando directorio y permisos en Oracle
echo ============================================

sqlplus -s -L system/muyfacilmuylarga@%ORA_SERVICE% @setup_dump_dir.sql

echo ============================================
echo Realizando DUMP DEL ESQUEMA (SOLO DATOS)
echo ============================================

expdp "%ORA_USER%/%ORA_PASS%@%ORA_SERVICE%" ^
  directory=%ORA_DIR% ^
  dumpfile=%DUMPFILE% ^
  logfile=%LOGFILE% ^
  SCHEMAS=%ORA_USER% ^
  CONTENT=DATA_ONLY

echo DUMP completado.
pause
