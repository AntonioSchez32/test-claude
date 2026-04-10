import csv
import logging
from functools import cache
from io import StringIO
import oracledb
from config import DB_CONFIG
from utils.valoracion_tareas import ContadoresTareasDict, ContadoresIneDict

logger = logging.getLogger(__name__)

# ----------------------------------------
# Inicializar pool de conexiones Oracle
# ----------------------------------------
_pool = None

def get_pool():
    """Inicializa el pool solo una vez."""
    global _pool
    if _pool is None:
        dsn = oracledb.makedsn(
            DB_CONFIG["db.host"],
            int(DB_CONFIG["db.port"]),
            service_name=DB_CONFIG["db.service"]
        )
        _pool = oracledb.create_pool(
            user=DB_CONFIG["db.user"],
            password=DB_CONFIG["db.password"],
            dsn=dsn,
            min=1,
            max=5,
            increment=1,
            timeout=60
        )
    return _pool


def get_db_connection():
    """Crea y devuelve una conexión desde el pool."""
    try:
        pool = get_pool()
        return pool.acquire()
    except Exception as e:
        raise Exception(f"Error conectando a la base de datos: {e}")


# ----------------------------------------
# CONSULTAS UTILITARIAS
# ----------------------------------------

def fetch_table_page(table_name, page=1, page_size=50):
    """
    Obtiene los datos de una tabla de forma paginada usando OFFSET/FETCH.
    Evita inyección validando el nombre de tabla.
    """
    table_name = table_name.upper()
    offset = (page - 1) * page_size

    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()

            # Total de filas
            cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
            total_rows = cursor.fetchone()[0]

            # Paginación moderna
            sql = f"""
                SELECT * FROM {table_name}
                OFFSET {offset} ROWS FETCH NEXT {page_size} ROWS ONLY
            """
            cursor.execute(sql)

            columns = [col[0] for col in cursor.description]
            rows = cursor.fetchall()

            return columns, rows, total_rows

    except oracledb.Error as e:
        raise Exception(f"Error consultando tabla {table_name}: {e}")


def get_tables():
    """Obtiene todas las tablas del usuario actual."""
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()

            cursor.execute("""
                SELECT table_name 
                FROM user_tables 
                ORDER BY table_name
            """)

            return [row[0] for row in cursor]

    except Exception as e:
        raise Exception(f"Error obteniendo tablas: {e}")


def get_views():
    """Obtiene todas las vistas del usuario actual."""
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()

            cursor.execute("""
                SELECT view_name 
                FROM user_views 
                ORDER BY view_name
            """)

            return [row[0] for row in cursor]

    except Exception as e:
        raise Exception(f"Error obteniendo vistas: {e}")


def municipio_menos_20000(cmun: int) -> bool:
    """
    Devuelve True si el municipio indicado tiene menos de 20.000 habitantes.
    """
    sql = """
        SELECT 1
        FROM MUNICIPIOS
        WHERE CMUN = :cmun
          AND NHAB <= 20000
    """

    try:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, {"cmun": cmun})
                return cur.fetchone() is not None

    except Exception as e:
        raise Exception(f"Error en municipio_mas_20000: {e}")


def municipio_mas_20000(cmun: int) -> bool:
    """
    Devuelve True si el municipio indicado tiene más de 20.000 habitantes.
    """
    sql = """
        SELECT 1
        FROM MUNICIPIOS
        WHERE CMUN = :cmun
          AND NHAB > 20000
    """

    try:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, {"cmun": cmun})
                return cur.fetchone() is not None

    except Exception as e:
        raise Exception(f"Error en municipio_mas_20000: {e}")


def load_municipios_grandes() -> tuple[int]:
    """
    Devuelve una lista con los códigos CMUN de municipios
    que tienen más de 20.000 habitantes.
    """
    sql = """
        SELECT CMUN
        FROM MUNICIPIOS
        WHERE NHAB > 20000
        ORDER BY CMUN
    """

    try:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                return tuple(row[0] for row in cur.execute(sql))


    except Exception as e:
        raise Exception(f"Error obteniendo municipios de más de 20000 habitantes: {e}")


def get_contadores_valoracion() -> dict[int, ContadoresTareasDict]:
    """Retorna Dict[int, ContadoresTareasDict] con la valoración de tareas de los municipios."""

    # Municipios esperados: 1..79 y 902
    municipios_esperados = list(range(1, 80)) + [902]

    # Claves de tareas
    tareas_keys = list(ContadoresTareasDict.__annotations__.keys())

    # Diccionarios de datos
    data_contadores: dict[int, ContadoresIneDict] = {}
    data_tareas: dict[int, ContadoresTareasDict] = {}

    # --- Tabla de mapeos automáticos ---
    # k_tarea: clave_contador
    contador_map = {
        'HS_1': 'HS',
        'HH_1': 'HH',
        'HD_2': 'HD',
        'HH_2': 'HH',
        'HD_3': 'HD',
        'HH_3': 'HH',
        'VC_3': 'VC',
        'VV_3': 'VV',
        'HV_4': 'HV',
        'HH_4': 'HH',
        'HH_5': 'HH',
        'HH_6': 'HH',
        'VV_6': 'VV',
        'HC_C': 'HC',
    }

    try:
        with get_db_connection() as conn:

            # ------------------------------
            # 1) LEER CONTADORES
            # ------------------------------
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM VW_CONTADORES_INE_POR_CMUN")

            columns = [col[0] for col in cursor.description]
            idx_cmun = columns.index("CMUN")

            for row in cursor:
                cmun = int(row[idx_cmun])
                cont: ContadoresIneDict = {
                    col: int(val) if val is not None else 0
                    for col, val in zip(columns, row)
                    if col != "CMUN"
                }
                data_contadores[cmun] = cont

            # ------------------------------
            # 2) LEER TAREAS YA CALCULADAS
            # ------------------------------
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM VW_CONTADORES_MUN_POR_CMUN")

            columns = [col[0] for col in cursor.description]
            idx_cmun = columns.index("CMUN")

            for row in cursor:
                cmun = int(row[idx_cmun])
                tareas: ContadoresTareasDict = {
                    col: int(val) if val is not None else 0
                    for col, val in zip(columns, row)
                    if col != "CMUN"
                }
                data_tareas[cmun] = tareas

        # ------------------------------
        # 3) COMPLETAR MUNICIPIOS Y CAMPOS
        # ------------------------------
        for cmun in municipios_esperados:

            # Asegurar estructura
            tareas = data_tareas.setdefault(cmun, {})
            contadores = data_contadores.get(cmun, {})

            for k in tareas_keys:

                if k in contador_map:
                    # Tarea depende de un contador
                    clave_cont = contador_map[k]
                    tareas[k] = contadores.get(clave_cont, 0)
                else:
                    # Valor fijo o ya existente
                    tareas.setdefault(k, 0)

        # Ordenar por CMUN antes de devolver
        return dict(sorted(data_tareas.items(), key=lambda x: x[0]))

    except oracledb.Error as e:
        raise Exception(f"Error en get_contadores_municipios: {e}")






def export_view_to_csv(view_name):
    """Exporta una vista Oracle a CSV en memoria."""
    view_name = view_name.upper()
    output = StringIO()

    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()

            cursor.execute(f"SELECT * FROM {view_name}")

            writer = csv.writer(output, delimiter=';')

            # Cabeceras
            writer.writerow([col[0] for col in cursor.description])

            # Datos
            for row in cursor:
                # TODO: anterior => writer.writerow([str(r) if r is not None else "" for r in row])
                row_values = [str(r) if r is not None else "" for r in row]
                logger.info(f"export_view_to_csv - Fila procesada: {row_values}")
                writer.writerow(row_values)


        return output.getvalue()

    except oracledb.Error as e:
        raise Exception(f"Error exportando vista {view_name}: {e}")
