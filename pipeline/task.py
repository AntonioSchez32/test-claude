# pipeline/task.py
import csv
import logging.config
import re

import unicodedata

from exceptions import NoCSVFilesFound
from pipeline.status import TaskStatus
from utils.comunes import ValidadorFicheros
from utils.text_codec import leer_o_convertir_a_utf8

logging.config.fileConfig("logging.conf", disable_existing_loggers=False)
logger = logging.getLogger("pipeline")

import zipfile, shutil, os, traceback
from pathlib import Path
import subprocess
import config

from utils.messages_loader import MESSAGES


def extraer_zip(task_id, zip_path, task_dir, tasks_shared):
    logger.info(f"[{task_id}] INICIO de procesamiento ZIP: {zip_path}")

    t = tasks_shared[task_id]
    t['status'] = TaskStatus.EXTRAYENDO.value
    t['detail'] = ''
    tasks_shared[task_id] = t
    logger.info(f"[{task_id}] Estado: extrayendo zip")
    work_tmp = Path(task_dir) / 'work'
    if work_tmp.exists():
        shutil.rmtree(work_tmp)
    work_tmp.mkdir(parents=True, exist_ok=True)
    safe_extract_zip(zip_path, work_tmp)

    logger.info(f"[{task_id}] ZIP extraído correctamente")


def safe_extract_zip(zip_path, dest_dir):
    # Prevent Zip Slip by validating file names
    with zipfile.ZipFile(zip_path, 'r') as z:
        for member in z.infolist():
            member_path = Path(dest_dir) / member.filename
            if not Path(dest_dir) in member_path.parents and Path(dest_dir) != member_path:
                raise Exception('Unsafe file path in zip: ' + member.filename)
        z.extractall(dest_dir)


def conversion_utf8(task_id, task_dir, tasks_shared):

    logger.info(f"[{task_id}] Estado: convirtiendo archivos a UTF-8")

    t = tasks_shared[task_id]
    t['status'] = TaskStatus.CONVIRTIENDO.value
    t['detail'] = ''
    tasks_shared[task_id] = t

    # Se crea la carpeta converted para almacenar los ficheros de texto/csv convertidos a utf-8
    work_tmp = (Path(task_dir) / 'work').resolve()
    converted = (Path(work_tmp) / 'converted').resolve()
    converted.mkdir(parents=True, exist_ok=True)

    # Se recorren recursivamente directorios y archivos del directorio de trabajo para convertirlos a utf-8
    for p in work_tmp.rglob('*'):
        if p.is_file() and p.parent.name != "converted":
            # Los ficheros convertidos se almacenan en el directorio "converted" del de trabajo "work"
            dst = converted / p.name
            convert_file_to_utf8(p, dst)

    logger.info(f"[{task_id}] Conversión finalizada")


def convert_file_to_utf8(src_path: Path, dst_path: Path):
    """
    Convierte un fichero de texto a UTF-8.
    Prioriza Windows-1252 porque es el origen real confirmado.
    Si falla, prueba otros encodings comunes en sistemas IBM/DOS.
    """

    raw = src_path.read_bytes()

    # Si contiene bytes nulos, lo tratamos como binario
    if b"\x00" in raw:
        shutil.copy(src_path, dst_path)
        return

    # Orden DEFINITIVO (óptimo):
    # 1) utf-8   -> por si ya estaba convertido
    # 2) cp1252  -> encoding esperado windows-1252
    # 3) cp850   -> IBM Europa
    # 4) cp437   -> IBM OEM
    # 5) latin-1 -> fallback
    encodings = ["cp1252", "cp850", "cp437", "latin-1", "utf-8"]

    text = None

    for enc in encodings:
        try:
            text = raw.decode(enc)
            break
        except UnicodeDecodeError:
            continue

    # Último recurso
    if text is None:
        text = raw.decode("latin-1", errors="replace")

    # Normalización unicode recomendada
    text = unicodedata.normalize("NFC", text)

    # Guardar SIEMPRE como UTF-8
    dst_path.write_text(text, encoding="utf-8", newline="\n")


def comprobar_txt_csv(task_id, task_dir, tasks_shared):
    """
    Recorre todos los archivos del directorio de conversión,
    filtra los que cumplen el patrón de nombres de ficheros
    y verifica si existe su equivalente con extensión .CSV.
    Si no existe, se crea el fichero CSV asociado.
    """

    msg = MESSAGES.info("task_comprobar_csv_inicio", task_id=task_id)
    logger.info(msg)

    t = tasks_shared[task_id]
    t['status'] = TaskStatus.COMPROBANDO_CSV.value
    t['detail'] = ''
    tasks_shared[task_id] = t

    work_tmp = (Path(task_dir) / 'work').resolve()
    converted_dir = (work_tmp / 'converted').resolve()

    # patrón para nombres tipo: VCppmmmI, A1HSppmmmA etc. donde ppmmm son 5 dígitos
    patron = re.compile(r"([A-Za-z1-9]{1,4})(\d{5})([IA]*)")

    if not converted_dir.exists():
        msg = MESSAGES.errors("task_comprobar_csv_no_dir", task_id=task_id, dir=converted_dir)
        logger.error(msg)
        return

    for file in converted_dir.iterdir():
        if not file.is_file():
            continue  # ignorar subdirectorios

        nombre = file.stem  # nombre sin extensión

        match = patron.fullmatch(nombre)
        if not match:
            continue  # no cumple el patrón
        prefijo, numeros, sufijo = match.groups()
        nombre_formato = f"{prefijo}ppmmm{sufijo}"

        # Construimos la ruta esperada del .CSV
        csv_file = file.with_name(file.name + ".CSV")

        if csv_file.exists():
            msg = MESSAGES.info("task_comprobar_csv_encontrado", task_id=task_id, nombre=csv_file.name)
            logger.info(msg)
        else:
            msg = MESSAGES.warning("task_comprobar_csv_falta", task_id=task_id, nombre=file.name)
            logger.warning(msg)

            # Se crea el CSV utilizando el fichero asociado de formato

            # Buscar formato asociado (case-insensitive)
            formato = next(
                (f for f in config.FMT_DIR.iterdir()
                 if f.stem.lower() == nombre_formato.lower() and f.suffix.lower() == ".csv"),
                None
            )

            if not formato:
                msg = MESSAGES.errors("task_comprobar_csv_no_fmt", task_id=task_id, nombre=file.name)
                logger.error(msg)
                raise Exception(msg)

            # CSV de salida: p.e. HC21001A.024.csv
            salida = file.with_suffix(file.suffix + ".csv")

            msg = MESSAGES.info("task_comprobar_csv_gen", task_id=task_id, nombre_csv=salida.name, nombre_fmt=formato.name)
            logger.info(msg)

            generar_csv_desde_texto(file, formato, salida)

            msg = MESSAGES.info("task_comprobar_csv_fin", task_id=task_id, nombre_csv=csv_file)
            logger.info(msg)

    msg = MESSAGES.info("task_comprobar_csv_fin", task_id=task_id)
    logger.info(msg)


def generar_csv_desde_texto(text_path: Path, formato_path: Path, salida_path: Path):
    """
        Genera un fichero CSV a partir de un fichero de texto fijo (txt, .025, etc.)
        usando un fichero de formato asociado que define:
            - nombre del campo
            - posición inicial
            - posición final

        El CSV generado siempre será UTF-8.
        El fichero de texto se leerá con detección de codificación robusta.
        """

    # ---------------------------------------------------------------
    # 1) LEER SIEMPRE UTF-8 (ya convertido)
    # ---------------------------------------------------------------
    contenido = text_path.read_text(encoding="utf-8")

    # ---------------------------------------------------------------
    # 2) CARGAR EL FICHERO DE FORMATO (plantilla):
    # ---------------------------------------------------------------
    # cargar_formato() devuelve:
    #   - cabeceras: lista de nombres de columnas para el CSV
    #   - especificaciones: lista de dicts con:
    #         campo, ini, fin
    #
    # Ejemplo de formato:
    #   CAMPO;DESCRIPCION;TIPO;LONGITUD;POSICION INICIAL;POSICION FINAL
    #   CODMUN;Código Municipio;N;3;1;3
    #   NOMBRE;Nombre Entidad;A;40;4;43
    #
    cabeceras, especificaciones = cargar_formato(formato_path)
    registros = []

    # ---------------------------------------------------------------
    # 3) PROCESAR LÍNEA A LÍNEA DEL FICHERO TEXTO
    # ---------------------------------------------------------------
    # Como el fichero ya está en memoria en Unicode, simplemente
    # partimos en líneas. Esto evita problemas de encoding y
    # garantiza que los slices sobre posiciones funcionan bien.
    #
    for linea in contenido.splitlines():
        registro = {}

        # -----------------------------------------------------------
        # 4) PARA CADA CAMPO DEL FORMATO, EXTRAER SUBCADENA
        # -----------------------------------------------------------
        # Las posiciones vienen dadas en “formato fijo” clásico:
        #   - ini y fin son 1-based (comienzan en 1, no en 0)
        # Por eso hacemos: ini-1 : fin
        #
        for spec in especificaciones:
            sub = linea[spec["ini"] - 1: spec["fin"]]
            registro[spec["campo"]] = sub

        # Añadir el registro extraído a la tabla en memoria
        registros.append(registro)

    # ---------------------------------------------------------------
    # 5) ESCRIBIR CSV EN UTF-8 SIEMPRE
    # ---------------------------------------------------------------
    # Se usa csv.DictWriter porque:
    #  - respeta el orden de las cabeceras
    #  - maneja campos con comillas
    #  - escribe delimitadores correctos
    #  - evita problemas con saltos de línea
    #
    # newline="" → evita que Python duplique líneas en Windows.
    #
    with salida_path.open("w", encoding="utf-8", newline="") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=cabeceras, delimiter=";")
        writer.writeheader()
        writer.writerows(registros)


def cargar_formato(formato_path: Path):
    """
    Carga el fichero de formato:
    - Primera línea: cabecera completa (CAMPO;DESCRIPCION;TIPO;LONGITUD;INICIO;FIN)
    - Resto: cada línea sigue ese esquema.

    Para generar el CSV final, necesitamos:
      - Los nombres de campo (CAMPO)
      - Sus posiciones inicial y final

    Devuelve:
      - cabeceras (lista de nombres de campo)
      - especificaciones (lista de dicts con campo, ini, fin)
    """
    with formato_path.open("r", encoding="utf-8") as f:
        lines = [line.strip() for line in f if line.strip()]

    # ignoramos la cabecera original del fichero de formato
    data_lines = lines[1:]

    cabeceras = []
    especificaciones = []

    for line in data_lines:
        partes = line.split(";")
        if len(partes) != 6:
            msg = MESSAGES.info("wrong_line_format", nombre_fmt=formato_path.name, linea=line)
            logger.error(msg)
            raise ValueError(msg)

        campo, descripcion, tipo, longitud, ini, fin = partes

        cabeceras.append(campo)

        especificaciones.append({
            "campo": campo,
            "descripcion": descripcion,
            "tipo" : tipo,
            "longitud" : longitud,
            "ini": int(ini),
            "fin": int(fin),
        })

    return cabeceras, especificaciones


def generar_ctls(task_id, task_dir, tasks_shared):

    msg = MESSAGES.info("task_generar_ctls_inicio", task_id=task_id)
    logger.info(msg)

    # Estado inicial
    tasks_shared[task_id] = {
        **tasks_shared[task_id],
        'status': TaskStatus.GENERANDO_CTL.value,
        'detail': ''
    }

    work_tmp = Path(task_dir) / 'work'
    converted = work_tmp / 'converted'

    # 1) Buscar todos los CSV (*.csv o *.CSV)
    csv_files = list(converted.rglob("*.[cC][sS][vV]"))

    # 2) Si no hay CSV → error AJAX
    if not csv_files:
        msg = MESSAGES.errors("task_ctl_no_csv_files", task_id=task_id)
        logger.error(msg)

        t = tasks_shared[task_id]
        t['status'] = TaskStatus.ERROR.value
        t['detail'] = msg
        tasks_shared[task_id] = t

        raise NoCSVFilesFound(msg)

    # 3) Procesar cada CSV normalmente
    for csv_file in csv_files:

        nombre_fichero = csv_file.name

        if (ValidadorFicheros.es_csv(nombre_fichero) and
                (info := ValidadorFicheros.parsear(nombre_fichero))):

            nombre_tabla = info["prefijo"]

            msg = MESSAGES.info("task_generar_ctls_prefix",task_id=task_id, filename=nombre_fichero, table=nombre_tabla)
            logger.info(msg)

            ctl_path = csv_file.with_suffix(".ctl")

            # Actualizar estado
            t = tasks_shared[task_id]
            t['status'] = TaskStatus.GENERANDO_CTL.value
            t['detail'] = str(ctl_path)
            tasks_shared[task_id] = t

            try:
                ctl_generado = generate_ctl_from_csv(
                    str(csv_file),
                    str(ctl_path),
                    nombre_tabla
                )

                if ctl_generado:
                    msg = MESSAGES.info("task_generar_ctls_ok", task_id=task_id, nombre=ctl_path.name)
                    logger.info(msg)

            except Exception as e:
                msg = MESSAGES.errors("task_generar_ctls_creation_error", task_id=task_id,
                                      nombre=csv_file.name, error=str(e))
                logger.error(msg)

        else:
            msg = MESSAGES.errors("task_generar_ctls_not_valid_file", task_id=task_id, nombre=nombre_fichero)
            logger.error(msg)


def generate_ctl_from_csv(csv_file, ctl_file, table_name):
    with open(csv_file, 'r', encoding='utf-8') as f:
        header = f.readline().strip()
        first_data = f.readline().strip()

    # Detectar CSV vacío de datos
    if not first_data:
        msg = MESSAGES.info('task_generar_ctls_no_heading', nombre=csv_file)
        logger.info(msg)
        return True

    # Columnas con diferencias de nombre en registros de hogares
    rename_map_h = {
        'CODIGO_ESTRUCTURA': 'CODIGO_EATIM',
        'NOMBRE_ESTRUCTURA': 'NOMBRE_EATIM',
        'NUMER': 'NUMERN',
        'NUMERS': 'NUMERSN',
        'KMT': 'KMTN',
        'HMT': 'HMTN',
        'BLOQ': 'BLOQN',
        'PORT': 'PORTN',
        'ESC': 'ESCAN',
        'PLAN': 'PLANN',
        'PUER': 'PUERN',
        'NUMERS_COH': 'NUMERS_COHERENTE',
        'KMT_COH': 'KMT_COHERENTE',
        'PLAN_COH': 'PLANTA_COHERENTE',
        'PUERTA_COH': 'PUERTA_COHERENTE'
    }

    # Columnas con diferencias de nombre en registros de viviendas
    rename_map_v = {
        'PLAN': 'PLANTA',
        'PUER': 'PUERTA',
        'HUSO_SRS': 'HUSO',
        'PUERTA_COH': 'PUERTA_COHERENTE'
    }

    # Campos de tablas de hogar que no coinciden
    if table_name.startswith("H"):
        columns = [
            rename_map_h.get(c.strip(), c.strip())
            for c in header.split(';')
            if c.strip()
        ]
    # Campos de tablas de viviendas que no coinciden
    elif table_name.startswith("V"):
        columns = [
            rename_map_v.get(c.strip(), c.strip())
            for c in header.split(';')
            if c.strip()
        ]
    else:
        columns = [
            c.strip()
            for c in header.split(';')
            if c.strip()
        ]

    # TODO : Borrar fields = ',\n'.join(columns)
    fields_list = []
    for c in columns:
        if c in ('COOR_X', 'COOR_Y'):
            # Convertimos a número
            fields_list.append(f"{c} \"CASE WHEN TRIM(:{c}) IS NULL THEN NULL ELSE REPLACE(TRIM(:{c}), \'.\', \',\') END\"")
        else:
            # Guardamos el resto tal cual
            fields_list.append(c)

    # Finalmente unimos la lista como antes
    fields = ',\n'.join(fields_list)

    ctl_content = f"""LOAD DATA
        CHARACTERSET UTF8
        INFILE '{csv_file}'
        INTO TABLE {table_name}
        APPEND
        FIELDS TERMINATED BY ';'
        OPTIONALLY ENCLOSED BY '"'
        TRAILING NULLCOLS
        (
        {fields}
        )
    """

    with open(ctl_file, 'w', encoding='utf-8') as f:
        f.write(ctl_content)

    return True


def ejecutar_ctls(task_id, task_dir, tasks_shared):

    msg = MESSAGES.process("process_ejecutar_ctls", task_id=task_id)
    logger.info(msg)

    t = tasks_shared[task_id]
    t['status'] = TaskStatus.LANZANDO_CTL.value
    t['detail'] = ''
    tasks_shared[task_id] = t

    work_tmp = Path(task_dir) / 'work'
    converted = work_tmp / 'converted'
    for ctl_file in converted.rglob("*.ctl"):

        # Log y bad derivados del CSV (ya existen por nuestro generate_ctl)
        log_file = ctl_file.with_suffix(".csv.log")
        bad_file = ctl_file.with_suffix(".csv.bad")
        dsc_file = ctl_file.with_suffix(".csv.dsc")

        msg = MESSAGES.info("task_ejecutar_ctls_ctl", task_id=task_id, nombre=ctl_file.name)
        logger.info(msg)

        rc, out, err = run_sqlldr(
            str(ctl_file),
            str(log_file),
            str(bad_file),
            str(dsc_file)
        )

        if rc != 0:
            msg = MESSAGES.errors("task_ejecutar_ctl_err", task_id=task_id, nombre=ctl_file.name)
            logger.error(msg)
            logger.error(err)

            msg = MESSAGES.errors("task_ejecutar_ctl_err_web", nombre=ctl_file.name)

            t = tasks_shared[task_id]
            t['status'] = TaskStatus.ERROR.value
            t['detail'] = msg
            t['trace'] = err
            tasks_shared[task_id] = t
            break  # para el procesamiento total
        else:
            msg = MESSAGES.info("task_ejecutar_ctls_end", task_id=task_id, nombre=ctl_file.name)
            logger.info(msg)

    # si todos los ctl se han cargado bien (no hubo ningún break)
    else:
        msg = MESSAGES.info("task_ejecutar_ctls_end_web")

        t = tasks_shared[task_id]
        t['status'] = TaskStatus.FINALIZADA.value
        t['output'] = msg
        tasks_shared[task_id] = t

        msg = MESSAGES.info("task_ejecutar_ctls_end_log", task_id=task_id)
        logger.info(msg)


def run_sqlldr(ctl_file, log_file, bad_file, dsc_file):
    cmd = [
        config.SQLLDR_CMD,
        f"{config.ORACLE_USER}/{config.ORACLE_PASSWORD}@{config.ORACLE_DSN}",
        f"control={ctl_file}",
        f"log={log_file}",
        f"bad={bad_file}",
        f"discard={dsc_file}", # para que funcione se necesita direct=true
        "skip=1",           # salta la cabecera
        "errors=1000000",   # nunca para por errores de datos
        "direct=false",     # evita ORA-26002, respeta constraints
        "parallel=false"    # asegura carga convencional (NO activa DIRECT)
    ]
    #TODO - anterior - proc = subprocess.run(cmd, capture_output=True, text=True, encoding='utf-8')
    proc = subprocess.run(cmd, capture_output=True, text=True, encoding='cp1252')
    return proc.returncode, proc.stdout, proc.stderr


def process_task(task_id, zip_path, task_dir, tasks_shared):
    """
    Ejecuta el pipeline completo del procesamiento de un ZIP.
    Controla:
    - Cancelación antes y después de cada fase
    - Limpieza segura al cancelar
    - Actualización del estado
    - Marcado de tarea terminada (finished=True)
    """

    # ------------------------------------------------------------------------
    # 🔍 FUNCIÓN INTERNA: ¿Está cancelada?
    # ------------------------------------------------------------------------
    def is_cancelled(task_id, tasks_shared):
        t = tasks_shared.get(task_id)
        return t and t.get("cancelled")


    def cancelled():
        """Comprueba cancelación y realiza cleanup en caso necesario."""
        if is_cancelled(task_id, tasks_shared):
            t_aux = tasks_shared.get(task_id)
            if t_aux:
                t_aux["status"] = TaskStatus.CANCELADA.value
                tasks_shared[task_id] = t_aux

            safe_cleanup(task_id, zip_path, task_dir, tasks_shared)
            return True
        return False

    # ------------------------------------------------------------------------
    # 🔍 FUNCIÓN INTERNA: Ejecutar una fase con cancelación antes/después
    # ------------------------------------------------------------------------
    def run_phase(phase_param):
        """Ejecuta una fase con cancelación integrada."""

        # Antes de ejecutar la fase
        if cancelled():  # antes
            return False

        # Ejecutar la fase real
        if phase_param is extraer_zip:
            phase_param(task_id, zip_path, task_dir, tasks_shared)
        else:
            phase_param(task_id, task_dir, tasks_shared)

        # Después de ejecutar la fase
        return not cancelled()  # después

    # ------------------------------------------------------------------------
    # 📌 LISTA DE FASES EN ORDEN
    # ------------------------------------------------------------------------
    phases = [
        extraer_zip,       # FASE 1: Extraer ZIP
        conversion_utf8,   # FASE 2: Convertir a UTF-8
        comprobar_txt_csv, # FASE 3: Comprobar CSV, generar si no existe
        generar_ctls,      # FASE 4: Generar CTLs
        ejecutar_ctls,     # FASE 5: Ejecutar SQL*Loader
    ]

    try:
        # --------------------------------------------------------------------
        # 🚀 EJECUTAR TODAS LAS FASES DEL PIPELINE
        # --------------------------------------------------------------------
        for phase in phases:
            if not run_phase(phase):   # si hay cancelación → parar pipeline
                return

    except Exception as e:
        # --------------------------------------------------------------------
        # ❌ GESTIÓN DE ERRORES
        # --------------------------------------------------------------------
        msg = MESSAGES.errors('task_error', task_id=task_id, error=e)
        logger.error(msg)

        trace = traceback.format_exc()
        msg = MESSAGES.errors('task_traceback', task_id=task_id, trace=trace)
        logger.error(msg)

        t = tasks_shared.get(task_id)
        if t:
            t["status"] = TaskStatus.ERROR.value
            t["detail"] = str(e)
            t["trace"] = traceback.format_exc()
            tasks_shared[task_id] = t
        else:
            msg = MESSAGES.warning('task_missing', task_id=task_id)
            logger.warning(msg)

    finally:
        # --------------------------------------------------------------------
        # 🟩 MARCAR ESTADO FINAL DE LA TAREA (solo si corresponde)
        # --------------------------------------------------------------------
        t = tasks_shared.get(task_id)
        if t:

            estado_actual = t.get("status")

            # ✔ Si NO está cancelada ni en error → ha terminado correctamente
            if estado_actual not in (TaskStatus.CANCELADA.value, TaskStatus.ERROR.value):
                t["status"] = TaskStatus.FINALIZADA.value
                t["finished"] = True  # esto permite cleanup en el manager

            # ❌ Si está en error → NO poner finished=True
            #    así NO se borrará automáticamente y cleanup NO se ejecutará
            elif estado_actual == TaskStatus.ERROR.value:
                t["finished"] = False  # la tarea queda accesible

            # ✔ Si está cancelada → permitir cleanup y eliminación automática
            elif estado_actual == TaskStatus.CANCELADA.value:
                t["finished"] = True

            tasks_shared[task_id] = t

        estado = tasks_shared.get(task_id)
        msg = MESSAGES.info('task_final_state', task_id=task_id, state=estado)
        logger.info(msg)


def safe_cleanup(task_id, zip_path, task_dir, tasks_shared):
    """
    Limpieza segura de todos los ficheros creados por una tarea.
    - Borra el ZIP original si existe
    - Borra el directorio de trabajo processing/<task_id>
    - Actualiza estado si la tarea sigue existiendo
    - Evita fallos por archivos en uso
    """

    msg = MESSAGES.info("safe_clean_up_starting", task_id=task_id)
    logger.info(msg)

    # ---------------------------------------------------------
    # 1) BORRAR ZIP ORIGINAL (si existe)
    # ---------------------------------------------------------
    try:
        if zip_path and os.path.exists(zip_path):
            os.remove(zip_path)
            msg = MESSAGES.info("safe_clean_up_removed_zip", task_id=task_id, zip_path=zip_path)
            logger.info(msg)
    except Exception as e:
        msg = MESSAGES.errors("safe_clean_up_zip_err", task_id=task_id, error=e)
        logger.error(msg)

    # ---------------------------------------------------------
    # 2) BORRAR DIRECTORIO DE TRABAJO processing/<task_id>
    # ---------------------------------------------------------
    try:
        if task_dir and task_dir.exists():
            shutil.rmtree(task_dir, ignore_errors=True)
            msg = MESSAGES.info("safe_clean_up_removed_dir", task_id=task_id, task_dir=task_dir)
            logger.info(msg)
    except Exception as e:
        msg = MESSAGES.errors("safe_clean_up_dir_err", task_id=task_id, error=e)
        logger.error(msg)

    # ---------------------------------------------------------
    # 3) ACTUALIZAR METADATA SI LA TAREA SIGUE EXISTIENDO
    # ---------------------------------------------------------
    t = tasks_shared.get(task_id)
    if t:
        t["status"] = TaskStatus.CANCELADA.value
        t["finished"] = True
        tasks_shared[task_id] = t

    msg = MESSAGES.info("safe_clean_up_done", task_id=task_id)
    logger.info(msg)
