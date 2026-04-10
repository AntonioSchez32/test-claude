@echo off

set ORA_USER=PADRONONLINE
set ORA_PASS=PADRONONLINE
set ORA_SERVICE=PADRONONLINE
set ORA_DIR=PADRONONLINE_DUMP
set DUMPFILE=padrononline_snapshot.dmp
set LOGFILE=padrononline_restore.log

echo ============================================
echo Restaurando SOLO datos en PADRONONLINE
echo ============================================

impdp "%ORA_USER%/%ORA_PASS%@%ORA_SERVICE%" ^
  directory=%ORA_DIR% ^
  dumpfile=%DUMPFILE% ^
  logfile=%LOGFILE% ^
  SCHEMAS=%ORA_USER% ^
  CONTENT=DATA_ONLY ^
  TABLE_EXISTS_ACTION=TRUNCATE

echo Restauración de datos completada.
pause
