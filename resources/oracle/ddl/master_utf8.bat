@ECHO OFF

:: Carga mediante SQL*Plus sqlplus: sys/<password>@localhost:1521/xe as sysdba < 00_ddl.sql

:: Consola UTF-8
echo Se cambia la página de códigos de la terminal de Windows a UTF-8...
chcp 65001
echo Aquí se puede comprobar que ha cambiado. (observa la tilde de la í)

echo.
echo =========================================
echo  Ejecutando SQL*Plus con scripts
echo =========================================

:: Para que SQL*Plus interprete correctamente acentos
set NLS_LANG=SPANISH_SPAIN.AL32UTF8

:: Se usa /nolog (opcional) para realizar la conexión desde dentro del script
:: sqlplus /nolog @master_utf8.sql
sqlplus sys/muyfacilmuylarga@localhost:1521/xe as sysdba @master_utf8.sql

echo.
echo =========================================
echo  Proceso finalizado
echo =========================================

@ECHO ON
pause

