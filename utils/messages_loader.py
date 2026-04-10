import config
from utils.message_catalog import MessageCatalog

# Carga única del fichero messages.ini
MESSAGES = MessageCatalog(config.BASE_DIR / "messages.ini")
