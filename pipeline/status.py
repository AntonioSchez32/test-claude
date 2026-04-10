from enum import Enum

class TaskStatus(str, Enum):
    """
    Estados permitidos para las tareas del sistema.

    Es 'str, Enum' para que:

    - se serialice sin problemas entre procesos (multiprocessing usa pickle)
    - se guarde correctamente dentro de Manager().dict() sin generar objetos complejos
    - se envíe por JSON sin cambiar nada (porque su value es una cadena normal)
    - los estados sigan siendo exactamente cadenas, sin transformar tipos
    """

    EN_COLA = "en cola"
    EXTRAYENDO = "extrayendo"
    CONVIRTIENDO = "convirtiendo"
    COMPROBANDO_CSV = "comprobando_csv"
    GENERANDO_CTL = "generando ctl"
    LANZANDO_CTL = "lanzando ctl"
    FINALIZADA = "finalizada"

    CANCELADA = "cancelada"
    ERROR = "error"

    DESCONOCIDO = "desconocido"




