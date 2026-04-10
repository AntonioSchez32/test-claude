from pathlib import Path

# Directorio base del proyecto (independiente del de trabajo)
BASE_DIR = Path(__file__).resolve().parent

# Oracle connection used only for reference; SQL*Loader will be invoked externally
#ORACLE_USER = "SYSTEM"
#ORACLE_PASSWORD = "muyfacilmuylarga"
#ORACLE_DSN = "localhost/XEPDB1"
ORACLE_USER = "PADRONONLINE"
ORACLE_PASSWORD = "PADRONONLINE"
ORACLE_DSN = "localhost/PADRONONLINE"
ORACLE_PORT = 1521
ORACLE_HOST, ORACLE_SERVICE = ORACLE_DSN.split("/")

DB_CONFIG = {
    "db.host": ORACLE_HOST,
    "db.port": ORACLE_PORT,
    "db.service": ORACLE_SERVICE,
    "db.user": ORACLE_USER,
    "db.password": ORACLE_PASSWORD,
}

# Directorios siempre absolutos
LOG_DIR = (BASE_DIR / "logs").resolve()
RSC_DIR = (BASE_DIR / "resources").resolve()
FMT_DIR = (RSC_DIR / "formatting").resolve()
PROCESSING_DIR = (BASE_DIR / "processing").resolve()
UPLOAD_DIR = (BASE_DIR / "uploads").resolve()

# Limites de workers y cola
MAX_CONCURRENT_WORKERS = 10
MAX_QUEUE_SIZE = 80

# Nombre externo del ejecutable SQL*Loader
SQLLDR_CMD = "sqlldr"

# Marcas de ficheros zips válidos
MARCA_ZIP_INE = "IAPO"
MARCA_ZIP_MUN = "ENTREGA"

# Indica si se desea activar autenticación por LDAP
AUTH_LDAP = True