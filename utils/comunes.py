import shutil
import re
import csv
from io import StringIO
from pathlib import Path
from typing import Dict

from utils.valoracion_tareas import ContadoresTareasDict


# ------------------------------------------------------------
# Definición de tipos para la validación de ficheros
# ------------------------------------------------------------
class ValidadorFicheros:
    """
    Validador de nombres INE/municipales:
    - Validación estática
    - Detección texto/csv
    - Singleton opcional para generación de CSV
    """

    # -------------------------
    # PREFIJOS
    # -------------------------
    prefijos_ine = ("HC", "HD", "HH", "HS", "HV", "PP", "VC", "VV")
    prefijos_municipales = (
        "A1HS", "A1VA", "A2HD", "A2VA", "A3VC",
        "A4HV", "A5HA", "A6HM", "A6VM", "BVA", "CHC"
    )

    prefijos_ficheros = prefijos_ine + prefijos_municipales
    prefijos_regex = "|".join(prefijos_ficheros)

    # -------------------------
    # REGEX
    # -------------------------

    # Ficheros de texto
    patron_texto = re.compile(
        rf"^({prefijos_regex})(\d{{5}})([IA])\.(\d{{3}})$"
    )

    # Ficheros CSV
    patron_csv = re.compile(
        rf"^({prefijos_regex})(\d{{5}})([IA])\.(\d{{3}})\.(csv|CSV)$"
    )

    # Cualquier fichero válido (texto o CSV)
    patron_general = re.compile(
        rf"^({prefijos_regex})(\d{{5}})([IA])\.(\d{{3}})(?:\.(csv|CSV))?$"
    )

    # -------------------------
    # SINGLETON
    # -------------------------
    _instance = None

    def __init__(self, fmt_dir: Path):
        self.fmt_dir = Path(fmt_dir)

    @classmethod
    def get_instance(cls, fmt_dir: Path):
        if cls._instance is None:
            cls._instance = cls(fmt_dir)
        return cls._instance

    # -------------------------
    #  MÉTODOS ESTÁTICOS: VALIDACIÓN
    # -------------------------
    @staticmethod
    def es_valido(nombre: str | Path) -> bool:
        """Devuelve True si es fichero válido (texto o CSV)."""
        nombre = Path(nombre).name
        return ValidadorFicheros.patron_general.match(nombre) is not None

    @staticmethod
    def es_texto(nombre: str | Path) -> bool:
        """Devuelve True si es un fichero de texto válido."""
        nombre = Path(nombre).name
        return ValidadorFicheros.patron_texto.match(nombre) is not None

    @staticmethod
    def es_csv(nombre: str | Path) -> bool:
        """Devuelve True si es un fichero CSV válido."""
        nombre = Path(nombre).name
        return ValidadorFicheros.patron_csv.match(nombre) is not None

    @staticmethod
    def parsear(nombre: str | Path):
        """Devuelve las partes del nombre (prefijo, código, letra, extensión)."""
        nombre = Path(nombre).name
        m = ValidadorFicheros.patron_general.match(nombre)
        if not m:
            return None

        return {
            "prefijo": m.group(1),
            "codigo": m.group(2),
            "letra_final": m.group(3),
            "extension": m.group(4),
            "es_csv": m.group(5) is not None,
        }

    @staticmethod
    def csv_destino(nombre: str | Path, work_dir: Path) -> Path:
        """Devuelve el CSV asociado al nombre (si es texto)."""
        nombre = Path(nombre).name
        return Path(work_dir) / f"{nombre}.csv"

    # -------------------------
    #  MÉTODOS DE INSTANCIA: GENERAR CSV
    # -------------------------
    @staticmethod
    def buscar_plantilla(codigo: str, fmt_dir: Path) -> Path | None:
        for plantilla in Path(fmt_dir).glob("*.csv"):
            if codigo in plantilla.stem:
                return plantilla
        return None

    def generar_csv_si_falta(self, fichero_path: Path, work_dir: Path):
        nombre = fichero_path.name

        # Solo actuamos sobre ficheros de texto
        if not self.es_texto(nombre):
            return False  # ignorar CSV existentes

        info = self.parsear(nombre)
        codigo = info["codigo"]

        csv_dest = self.csv_destino(nombre, work_dir)

        if csv_dest.exists():
            return False

        plantilla = self.buscar_plantilla(codigo, self.fmt_dir)
        if not plantilla:
            print(f"[WARN] No existe plantilla para {nombre} (código {codigo})")
            return False

        print(f"[OK] Generando {csv_dest.name} desde {plantilla.name}")
        shutil.copy(plantilla, csv_dest)
        return True

def data_to_csv(data: Dict[int, ContadoresTareasDict]) -> str:
    """ Retorna un cadena CSV a partir de los datos recibidos"""

    output = StringIO()
    writer = csv.writer(output, delimiter=';', quoting=csv.QUOTE_MINIMAL)

    # Encabezado en el orden EXACTO del TypedDict
    columnas = ["CMUN"] + list(ContadoresTareasDict.__annotations__.keys())
    writer.writerow(columnas)

    # Filas ordenadas según 'columnas'
    for cmun, tareas in data.items():
        fila = [f"{cmun:03d}"] + [tareas.get(col, 0) for col in columnas[1:]]
        writer.writerow(fila)

    return output.getvalue()


def data_totales_to_csv(val: ContadoresTareasDict) -> str:
    """
    Retorna una cadena CSV a partir de un único ContadoresTareasDict,
    sin incluir CMUN.
    """

    output = StringIO()
    writer = csv.writer(output, delimiter=';', quoting=csv.QUOTE_MINIMAL)

    # Encabezado (todas las claves del TypedDict)
    columnas = list(ContadoresTareasDict.__annotations__.keys())
    writer.writerow(columnas)

    # Única fila
    fila = [val.get(col, 0) for col in columnas]
    writer.writerow(fila)

    return output.getvalue()
