## PadronOnline - Improved ETL (SQL*Loader)
TODO Introducir descripción...

Características:
- Interfaz web Bootstrap para subir múltiples ZIP.
- Worker pool con límite de concurrencia y gestión de cola.
- Extracción segura de ZIP por tarea en directorios temporales.
- Conversión de codificación a UTF-8 con chardet.
- Combinación de CSV usando chunks para evitar uso excesivo de RAM.
- Generación automática de .ctl y ejecución de sqlldr (SQL*Loader).
- Logs por tarea y posibilidad de descargar archivos de logging.
- Compatible con Windows y Linux (usa pathlib).

Ejecución rápida:
1. Crear virtualenv e instalar dependencias:
   python -m venv venv
   venv\Scripts\activate
   pip install -r requirements.txt

2. Configurar config.py con conexión Oracle y rutas.

3. Ejecutar:
   python app.py



### USO RECOMENDADO: 
Ejecutar con `python app.py` (no usar `flask run` para evitar problemas con multiprocessing en Windows).


### NOTAS SOBRE DATOS ANALIZADOS:

**HV21006I.024** y **HV21042I.024** no cumplen el formato de registros de hogar, desde el valor "PUERN" y antes de "CODIGO_EATIM" falta un 0 en cada registro.

Existen **columnas con diferencias de nombre en registros de hogares**:

|       Columna        |   Debería ser    |
|:--------------------:|:----------------:|
| CODIGO_ESTRUCTURA    |   CODIGO_EATIM   |
|  CODIGO_ESTRUCTURA   |   CODIGO_EATIM   |
|  NOMBRE_ESTRUCTURA   |   NOMBRE_EATIM   |
|        NUMER         |      NUMERN      |
|        NUMERS        |     NUMERSN      |    
|         KMT          |       KMTN       | 
|         HMT          |       HMTN       |       
|         BLOQ         |      BLOQN       |      
|         PORT         |      PORTN       |      
|         ESC          |      ESCAN       |            
|         PLAN         |      PLANN       |             
|         PUER         |    PUERN         |            
|      NUMERS_COH      | NUMERS_COHERENTE | 
|       KMT_COH        |  KMT_COHERENTE   |    
|       PLAN_COH       | PLANTA_COHERENTE | 
|      PUERTA_COH      | PUERTA_COHERENTE | 

Y existen **columnas con diferencias de nombre en registros de viviendas**:

|       Columna        |   Debería ser    |
|:--------------------:|:----------------:| 
|         PLAN         |     PLANTA       |
|         PUER         |      PUERTA      | 
|       HUSO_SRS       |       HUSO       | 
|      PUERTA_COH      | PUERTA_COHERENTE | 
