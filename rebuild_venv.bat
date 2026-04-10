REM Encoding UTF-8
chcp 65001 > nul

@echo off
REM ===============================
REM Script para limpiar y reconstruir el venv
REM ===============================

SET VENV_DIR=.venv

echo ===============================
echo 1️⃣ Eliminando venv viejo
echo ===============================
if exist %VENV_DIR% (
    rmdir /s /q %VENV_DIR%
    echo venv eliminado.
) else (
    echo No existia venv previo.
)

echo ===============================
echo 2️⃣ Creando nuevo venv
echo ===============================
python -m venv %VENV_DIR%
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: No se pudo crear el virtualenv.
    exit /b 1
)

echo ===============================
echo 3️⃣ Activando venv
echo ===============================
call %VENV_DIR%\Scripts\activate.bat
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: No se pudo activar el virtualenv.
    exit /b 1
)

echo ===============================
echo 4️⃣ Actualizando pip
echo ===============================
python -m pip install --upgrade pip

echo ===============================
echo 5️⃣ Instalando requirements.txt
echo ===============================
pip install --upgrade -r requirements.txt
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: No se pudieron instalar todas las librerías.
    exit /b 1
)

echo ===============================
echo ✅ Entorno reconstruido correctamente
echo ===============================
echo Para usarlo: activate con:
echo %VENV_DIR%\Scripts\activate.bat
pause
