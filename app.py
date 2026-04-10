import sys

from utils import db

# Se comprueba por seguridad que la versión de python utilizada es la 3.13.10 o superior
if sys.version_info < (3, 13, 10):
    raise RuntimeError("Este proyecto requiere Python 3.13.10 o superior")


import os
import re

from auth_ldap import LDAPAuthenticator
from utils.comunes import data_to_csv, ContadoresTareasDict, data_totales_to_csv
from utils.messages_loader import MESSAGES
from utils.valoracion_tareas import valoracion_tarea_a1, valoracion_tarea_a2, valoracion_tarea_a3, valoracion_tarea_a4, \
    valoracion_tareas_extra, totalizar_municipios_menores, totalizar_municipios_mayores, filtrar_municipios_menores, \
    valoracion_actuacion_2

# Se desactiva frame-eval en modo DEBUG porque afecta a la depuración en multiproceso
if os.environ.get("PYCHARM_HOSTED") == "1":
    os.environ["PYDEVD_USE_FRAME_EVAL"] = "NO"

import shutil
from pipeline.status import TaskStatus
from io import BytesIO
from pathlib import Path
from flask import Flask, render_template, request, redirect, url_for, session, flash, jsonify, send_file, Response, \
    abort, request
from functools import wraps

# --------------------------------------------------------------------
# LOGGING
# --------------------------------------------------------------------
# noinspection PyUnusedImports
import logging # No borrar, debe mantenerse
import logging.config
# noinspection PyUnusedImports
import concurrent_log_handler # No borrar, debe mantenerse
logging.config.fileConfig('logging.conf', disable_existing_loggers=False)
logger = logging.getLogger("pipeline")
logger.info("Logging inicializado correctamente")

from utils.db import get_views, fetch_table_page, get_tables, get_contadores_valoracion, export_view_to_csv, \
    load_municipios_grandes
import config
import uuid

# ⬇️ IMPORTAMOS EL TASK MANAGER
from workers import TaskManager, set_task_manager


# --------------------------------------------------------------------
# FLASK APP
# --------------------------------------------------------------------
app = Flask(
    __name__,
    template_folder="templates",
    static_folder="static"
)
app.secret_key = os.urandom(24)

# --------------------------------------------------------------------
# CONTEXTO GLOBAL PARA TEMPLATES (usuario en navbar)
# --------------------------------------------------------------------
@app.context_processor
def inject_user():
    return {
        "username": session.get("username"),
        "logged_in": session.get("logged_in", False),
        "full_name": session.get("full_name", "Invitado")
    }


# --------------------------------------------------------------------
# CREAR DIRECTORIOS SI NO EXISTEN
# --------------------------------------------------------------------

#LOGS
LOG_FOLDER = Path(config.LOG_DIR).resolve()
LOG_FOLDER.mkdir(parents=True, exist_ok=True)

#PROCESADO
PROCESSING_DIR = Path(config.PROCESSING_DIR).resolve()
PROCESSING_DIR.mkdir(parents=True, exist_ok=True)

#SUBIDAS
UPLOAD_FOLDER = Path(config.UPLOAD_DIR).resolve()
UPLOAD_FOLDER.mkdir(parents=True, exist_ok=True)

# --------------------------------------------------------------------
# INICIALIZAR EL TASK MANAGER (PERO NO ARRANCARLO AÚN)
# --------------------------------------------------------------------
task_manager = TaskManager()      # Crear instancia (solo objeto)
set_task_manager(task_manager)    # Registrar como global
# ❌ NO arrancar aquí -> rompe multiprocessing en Windows

# Decorador para requerir login en acceso a ruta
def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if config.AUTH_LDAP and not session.get("logged_in"):
            return redirect(url_for("login"))
        return f(*args, **kwargs)
    return decorated_function


@app.route("/")
@login_required
def index():
    return redirect(url_for("dashboard"))

ldap_auth = LDAPAuthenticator(
    server_url="ldaps://ldap.ine.es"
)

@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        user = request.form["username"]
        pwd = request.form["password"]

        info = ldap_auth.authenticate(user, pwd)

        if info["status"]:

            # Obtenemos los atributos de LDAP del usuario
            attrs = info.get("attributes", {})
            cn_list = attrs.get("cn", [user])  # devuelve lista o [user] si no existe

            # Tomamos el nombre completo del usuario
            full_name = cn_list[0]

            # Lo guardamos en sesión
            session["full_name"] = full_name or user

            session["logged_in"] = True       # marca de logado
            session["username"] = user        # nombre de usuario
            session["full_name"] = full_name  # nombre completo

            return redirect(url_for("dashboard"))
        else:
            error_msg = info["error"]
            if error_msg:
                flash(error_msg, "danger")
            else:
                flash("Usuario o contraseña incorrectos", "danger")
            return render_template("login.html")

    # GET → muestra la plantilla
    return render_template("login.html")

@app.route("/dashboard")
@login_required
def dashboard():
    breadcrumb = [{'name': 'Inicio', 'url': '/dashboard'}]
    return render_template("dashboard.html", breadcrumb=breadcrumb)
    # TODO - username - return render_template("dashboard.html", breadcrumb=breadcrumb, username=session["username"])

@app.route("/logout")
@login_required
def logout():

    ldap_logger = logging.getLogger("ldap_auth")

    # Se obtiene el nombre de usuario de la sesión
    username = session.get("username", "desconocido")

    # Registrar en el log
    ldap_logger.info(
        f"Logout de usuario {username} desde la IP {request.remote_addr}, User-Agent: {request.headers.get('User-Agent')}"
    )

    # Limpiar sesión
    session.clear()

    return redirect(url_for("login"))


@app.route("/carga_ficheros")
@login_required
def carga_ficheros():
    breadcrumb = [{'name': 'Inicio', 'url': '/dashboard'}, {'name': 'Carga de ficheros', 'url': '/carga_ficheros'}]
    return render_template("carga_ficheros.html", breadcrumb=breadcrumb)


@app.route("/consulta_tablas", methods=["GET", "POST"])
@login_required
def consulta_tablas():
    breadcrumb = [{'name': 'Inicio', 'url': '/dashboard'}, {'name': 'Consulta de tablas', 'url': '/consulta_tablas'}]
    tablas = get_tables()
    # TODO - borrar - selected_table = None
    columns = []
    rows = []
    total_pages = 0
    page = request.args.get("page", 1, type=int)

    if request.method == "POST":
        selected_table = request.form.get("db_table")
        page = 1
    else:
        selected_table = request.args.get("table")

    if selected_table:
        try:
            columns, rows, total_rows = fetch_table_page(selected_table, page=page, page_size=50)
            total_pages = (total_rows // 50) + (1 if total_rows % 50 > 0 else 0)
        except Exception as e:
            print(f"Error al obtener datos de {selected_table}: {e}")
            columns, rows, total_pages = [], [], 0

    return render_template(
        "consulta_tablas.html",
        tablas=tablas,
        selected_table=selected_table,
        columns=columns,
        rows=rows,
        page=page,
        total_pages=total_pages,
        breadcrumb=breadcrumb
    )


@app.route("/delete_data", methods=["DELETE"])
@login_required
def delete_data():
    """
        Borra todos los datos de todas las tablas del esquema PADRONONLINE.
        TRUNCATE + CASCADE CONSTRAINTS para evitar problemas con FK.
        """
    try:
        # Obtener todas las tablas del esquema
        tablas = db.get_tables()  # devuelve solo tablas del usuario actual (PADRONONLINE)

        with db.get_db_connection() as conn:
            cursor = conn.cursor()

            # 1. Desactivar FK
            cursor.execute("""
            BEGIN
               FOR c IN (
                  SELECT table_name, constraint_name
                  FROM all_constraints
                  WHERE owner = 'PADRONONLINE'
                  AND constraint_type = 'R'
               ) LOOP
                  EXECUTE IMMEDIATE 'ALTER TABLE PADRONONLINE.' || c.table_name ||
                                    ' DISABLE CONSTRAINT ' || c.constraint_name;
               END LOOP;
            END;
            """)

            # 2. Truncar tablas
            for tabla in tablas:
                if tabla.upper() == "MUNICIPIOS":
                    continue

                try:
                    cursor.execute(f"TRUNCATE TABLE PADRONONLINE.{tabla}")
                    db.logger.info(f"Tabla truncada: {tabla}")
                except Exception as e:
                    db.logger.error(f"Error truncando {tabla}: {e}")

            # 3. Activar FK
            cursor.execute("""
            BEGIN
               FOR c IN (
                  SELECT table_name, constraint_name
                  FROM all_constraints
                  WHERE owner = 'PADRONONLINE'
                  AND constraint_type = 'R'
               ) LOOP
                  EXECUTE IMMEDIATE 'ALTER TABLE PADRONONLINE.' || c.table_name ||
                                    ' ENABLE CONSTRAINT ' || c.constraint_name;
               END LOOP;
            END;
            """)

            conn.commit()

        return jsonify({"message": "Borrado de todas las tablas completado"}), 200

    except Exception as e:
        db.logger.error(f"Error borrando datos: {e}")
        return jsonify({"message": str(e)}), 500


@app.route("/delete/<task_id>", methods=["DELETE"])
@login_required
def delete_task(task_id):

    t = task_manager.tasks.get(task_id)
    if not t:
        msg = MESSAGES.errors("task_not_found")
        return jsonify({"error": msg}), 404

    estado = t.get("status")
    zip_path = t.get("zip_path")
    task_dir = (Path(config.PROCESSING_DIR) / task_id)

    # ============================================================
    # ⛔ 1) NO permitir borrar mientras se ejecuta
    # ============================================================
    if estado not in (
        TaskStatus.EN_COLA.value,
        TaskStatus.CANCELADA.value,
        TaskStatus.FINALIZADA.value,
        TaskStatus.ERROR.value
    ):
        return jsonify({"error": MESSAGES.errors("task_not_removable")}), 400

    # ============================================================
    # 🟩 MARCAR cancelación SIEMPRE
    # ============================================================
    t2 = dict(t) # type: dict[str, object]
    t2["cancelled"] = True
    t2["status"] = TaskStatus.CANCELADA.value
    t2["finished"] = True            # permite que el worker la elimine si aplica
    task_manager.tasks[task_id] = t2

    # ============================================================
    # 🟥 2) CASO: TAREA EN ERROR
    #    → el worker YA NO VOLVERÁ a procesarla
    #    → la API debe borrar todo **aquí mismo**
    # ============================================================
    if estado == TaskStatus.ERROR.value:

        # Eliminar ZIP y carpeta de trabajo
        remove_task_resources(task_id, task_dir, zip_path)

        msg = MESSAGES.info("task_error_removed")
        return jsonify({"error": msg}), 200


    # ============================================================
    # 🟦 3) CASO: TAREA EN COLA
    #    → nunca llegó al worker
    #    → hay que borrar TODO aquí mismo
    # ============================================================
    if estado == TaskStatus.EN_COLA.value:

        # Quitar de la cola
        remove_from_queue(task_manager.q, task_id)

        # Eliminar ZIP y carpeta de trabajo
        remove_task_resources(task_id, task_dir, zip_path)

        return jsonify({"error": MESSAGES.errors("task_deleted_before_execution")}), 200


    # ============================================================
    # 🟩 4) CASO: FINALIZADA o CANCELADA dentro del pipeline
    #    → el worker la eliminará desde su finally
    #    → solo limpiamos la cola por si seguía dentro
    # ============================================================
    remove_from_queue(task_manager.q, task_id)

    return jsonify({"message": "cancelándose", "task_id": task_id}), 200


def remove_task_resources(task_id, task_dir, zip_path):
    # 🧹 Borrar ZIP y carpeta de trabajo
    try:
        if zip_path and os.path.exists(zip_path):
            os.remove(zip_path)
        if task_dir.exists():
            shutil.rmtree(task_dir, ignore_errors=True)
    except Exception as e:
        msg = MESSAGES.errors("process_dir_deletion", task_id=task_id, error=e)
        logger.error(msg)

    # 🧹 Borrar metadata
    del task_manager.tasks[task_id]

def remove_from_queue(q, task_id):
    items = []
    try:
        while True:
            tid, path = q.get_nowait()
            if tid != task_id:
                items.append((tid, path))
    except Exception as e:
        msg = MESSAGES.warning("queue_unremovevable_task", task_id=task_id, error=e)
        logger.error(msg)
        pass

    for item in items:
        q.put(item)


@app.route("/delete_all", methods=["DELETE"])
@login_required
def delete_all_tasks():

    # ============================================================
    # 1) Eliminar TODAS las tareas del diccionario, con cleanup
    # ============================================================
    for task_id, t in list(task_manager.tasks.items()):

        estado = t.get("status")
        zip_path = t.get("zip_path")
        task_dir = (Path(config.PROCESSING_DIR) / task_id)

        # --------------------------------------------------------
        # 🔥 Caso A: Tareas que YA NO se están ejecutando
        #           (en cola, error, finalizadas, canceladas)
        #           → debemos borrar ZIP, carpeta y metadata
        # --------------------------------------------------------
        if estado in (
            TaskStatus.EN_COLA.value,
            TaskStatus.ERROR.value,
            TaskStatus.FINALIZADA.value,
            TaskStatus.CANCELADA.value
        ):

            # 🧹 Borrar ZIP
            try:
                if zip_path and os.path.exists(zip_path):
                    os.remove(zip_path)
            except Exception as e:
                msg = MESSAGES.error("delete_task_zip_unremovable", task_id=task_id, error=e)
                logger.error(msg)
                pass

            # 🧹 Borrar carpeta
            try:
                if task_dir.exists():
                    shutil.rmtree(task_dir, ignore_errors=True)
            except Exception as e:
                msg = MESSAGES.errors("delete_task_zip_unremovable", task_id=task_id, error=e)
                logger.error(msg)
                pass

            # 🧹 Borrar metadata
            try:
                del task_manager.tasks[task_id]
            except Exception as e:
                msg = MESSAGES.errorsf("taskmanager_task_unremovable", task_id=task_id, error=e)
                logger.error(msg)
                pass

        # --------------------------------------------------------
        # 🟥 Caso B: Tareas en ejecución
        #           → NO se deben borrar (evita corrupción)
        # --------------------------------------------------------
        else:
            # Las marcamos canceladas, ya las borrará el worker
            t2 = dict(t) # type: dict[str, object]
            t2["cancelled"] = True
            t2["status"] = TaskStatus.CANCELADA.value
            t2["finished"] = True
            task_manager.tasks[task_id] = t2

    # ============================================================
    # 2) Vaciar completamente la cola
    # ============================================================
    try:
        while True:
            task_manager.q.get_nowait()
    except Exception as e:
        msg = MESSAGES.warning("taskmanager_nowait", error=e)
        logger.warning(msg)
        pass

    msg = MESSAGES.info("app_tasks_removed")
    return jsonify({"message": msg}), 200


@app.route("/download")
@login_required
def download_csv():
    selected_view = request.args.get("view")
    if not selected_view:
        msg = MESSAGES.warning("app_no_view_selected")
        flash(msg, "danger")
        return redirect(url_for("index"))

    try:
        csv_text = export_view_to_csv(selected_view)
        buffer = BytesIO(csv_text.encode("utf-8"))
        return send_file(
            buffer,
            mimetype="text/csv",
            as_attachment=True,
            download_name=f"{selected_view}_export.csv"
        )
    except Exception as e:
        flash(str(e), "danger")
        return redirect(url_for("index"))


@app.route("/upload", methods=["POST"])
@login_required
def upload():

    def es_nombre_valido(nombre):
        # Formato de nombre de fichero aportado por el INE
        patron_zip_ine = rf"^\d{{5}}{config.MARCA_ZIP_INE}\.(ZIP|zip)$"

        # Formato de nombre de fichero aportado por el municipio
        patron_zip_mun = rf"^{config.MARCA_ZIP_MUN}\d{{5}}\.(ZIP|zip)$"

        # Se comprueba si el nombre del fichero es válido
        return re.match(f"{patron_zip_ine}|{patron_zip_mun}", nombre.upper()) is not None

    # Recibir UN solo fichero por llamada AJAX
    if "file" not in request.files:
        msg = MESSAGES.errors("no_file")
        return jsonify({"error": msg}), 400

    f = request.files["file"]

    if not f or f.filename == "" or not es_nombre_valido(f.filename):
        msg = MESSAGES.errors("app_invalid_file", filename=f.filename)
        return jsonify({"error": msg}), 400

    # Crear ID de tarea
    task_id = str(uuid.uuid4())

    # Guardar ZIP con el nombre basado en la tarea
    zip_path = UPLOAD_FOLDER / f"{task_id}.zip"
    f.save(str(zip_path))

    # Encolar tarea (igual que antes)
    task_manager.enqueue(task_id, str(zip_path), f.filename)

    return jsonify({
        "message": "enqueued",
        "task": task_id,
        "filename": f.filename
    })


@app.route("/tasks")
@login_required
def tasks():
    return jsonify(task_manager.get_all_tasks())


@app.route("/task/<task_id>")
@login_required
def task_status(task_id):
    return jsonify(task_manager.get_task(task_id))


@app.route("/retry/<task_id>", methods=["POST"])
@login_required
def retry(task_id):
    try:
        new_id = task_manager.retry(task_id)
        if not new_id:
            msg = MESSAGES.errors("task_retry_error", task_id=task_id)
            return jsonify({"error": msg}), 400
        return jsonify({"message": "retried", "new_task_id": new_id})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


def get_converted_dir(task_id: str) -> Path:
    base = (config.PROCESSING_DIR / task_id / "work" / "converted").resolve()

    if not base.exists() or not base.is_dir():
        abort(404)

    return base


@app.route("/tasks/<task_id>/log")
def view_task_log(task_id):
    base = get_converted_dir(task_id)

    # Buscar archivos .csv.bad
    bad_files = list(base.glob("*.csv.bad"))
    if not bad_files:
        return "No hay log disponible", 404

    bad_file = bad_files[0]

    # Generar Path del log correspondiente
    log_file = bad_file.with_suffix(".log")

    # Comprobar que existe
    if not log_file.exists():
        return "No hay log disponible", 404

    # Leer el contenido del log
    text = log_file.read_text(encoding="cp1252", errors="replace")

    return Response(
        text,
        mimetype="text/plain; charset=utf-8"
    )



@app.route("/tasks/<task_id>/bad")
def view_task_bad(task_id):
    base = get_converted_dir(task_id)

    bad_files = list(base.glob("*.csv.bad"))
    if not bad_files:
        return "No hay registros erróneos", 404

    bad_file = bad_files[0]

    text = bad_file.read_text(encoding="cp1252", errors="replace")
    return Response(
        text.encode("utf-8").decode("utf-8"),
        mimetype="text/plain; charset=utf-8"
    )


@app.route("/tasks/<task_id>/dsc")
def view_task_dsc(task_id):
    base = get_converted_dir(task_id)

    dsc_files = list(base.glob("*.csv.dsc"))
    if not dsc_files:
        return "No hay registros de datos omitidos", 404

    dsc_file = dsc_files[0]

    text = dsc_file.read_text(encoding="cp1252", errors="replace")
    return Response(
        text.encode("utf-8").decode("utf-8"),
        mimetype="text/plain; charset=utf-8"
    )

@app.route("/consulta_contadores", methods=["GET", "POST"])
@login_required
def consulta_contadores():
    breadcrumb = [{'name': 'Inicio', 'url': '/dashboard'}, {'name': 'Consulta de contadores', 'url': '/consulta_contadores'}]
    vistas = get_views()
    csv_data = None
    selected_view = None

    if request.method == "POST":
        selected_view = request.form.get("db_view")
        if selected_view:
            try:
                csv_text = export_view_to_csv(selected_view)
                csv_data = csv_text.splitlines()
                msg = MESSAGES.info("app_loaded_view", selected_view=selected_view)
                flash(msg, "success")
            except Exception as e:
                flash(str(e), "danger")

    return render_template("consulta_contadores.html", breadcrumb=breadcrumb, vistas=vistas, csv_data=csv_data,
                           selected_view=selected_view)


@app.route("/valoracion_tareas", methods=["GET", "POST"])
@login_required
def valoracion_tareas():
    breadcrumb = [{'name': 'Inicio', 'url': '/dashboard'}, {'name': 'Valoración de tareas','url': '/valoracion_tareas'}]

    selected_caso = request.form.get("caso", "1")  # CASO 1 por defecto
    calidad_actuacion_2 = request.form.get("calidad_actuacion_2", "MEDIA")  # Calidad de actuación 2, MEDIA por defecto
    calidad_actuacion_2_media = calidad_actuacion_2 == "MEDIA"

    def casos(valores, nota):
        def format_val(v):
            # Si es numérico → añadir nota
            try:
                # Si puede convertirse a número, se considera numérico
                float(v)
                return f"{v}% {nota}"
            except (ValueError, TypeError):
                # Si NO es numérico → devolver tal cual
                return str(v)

        return [format_val(v) for v in valores]

    def set_valores(actuacion, tarea, v1=None, v2=None, v3=None, nota=None):
        """ Establecer valores de porcentajes_maximos de forma individual.

            Por ejemplo:
            set_valores("Actuación 1", "Tarea A3", v3=0)
            set_valores("Actuación 1", "Tarea A1", v1=55, v2=52, nota="(**)")
            set_valores("Actuación 2", "No se realiza", v1="-")
        """

        filas = valoracion_criterios[actuacion]["filas"]

        for i, (nombre, valores, nt) in enumerate(filas):
            if nombre == tarea:
                nuevo_v1 = v1 if v1 is not None else valores[0]
                nuevo_v2 = v2 if v2 is not None else valores[1]
                nuevo_v3 = v3 if v3 is not None else valores[2]
                nuevo_nt = nota if nota is not None else nt

                filas[i] = (nombre, (nuevo_v1, nuevo_v2, nuevo_v3), nuevo_nt)
                return

    csv_data = None
    csv_data_totales_menores = None
    csv_data_totales_mayores = None
    selected_view = None
    valoracion_criterios = None

    try:

        data: dict[int, ContadoresTareasDict] = get_contadores_valoracion()
        csv_data = data_to_csv(data)
        csv_data = csv_data.splitlines()

        # Obtenemos los CMUN de los municipios de más de 20.000 habitantes (2, 5, 10, 21, 41, 42, 44, 50)
        municipios_grandes = load_municipios_grandes()

        # Resumimos contadores para municipios de hasta 20.000 habitantes
        data_totales_menores = totalizar_municipios_menores(data, municipios_grandes)
        csv_data_totales_menores = data_totales_to_csv(data_totales_menores)
        csv_data_totales_menores = csv_data_totales_menores.splitlines()

        # Resumimos contadores para municipios de más de 20.000 habitantes
        data_totales_mayores = totalizar_municipios_mayores(data, municipios_grandes)
        csv_data_totales_mayores = data_totales_to_csv(data_totales_mayores)
        csv_data_totales_mayores = csv_data_totales_mayores.splitlines()

        # Generamos la estructura a retornar a la vista
        valoracion_criterios = {
            "Actuación 1": {
                "descripcion": "Renovación del Portal Web Municipal (Sede electrónica) y tareas adicionales",
                "filas": [
                    ("Tarea A1", ("-", "-", "-"), "(*)"),
                    ("Tarea A2", ("-", "-", "-"), "(*)"),
                    ("Tarea A3", ("-", "-", "-"), "(*)"),
                    ("Tarea A4", ("-", "-", "-"), "(*)"),
                    ("Extra: Tareas A5, A6, B y C", ("-", "-", "-"), " Extra"),
                ]
            },

            "Actuación 2": {
                "descripcion": "Modernización de la web municipal",
                "filas": [
                    ("-", ("-", "-", "-"), "(**)"),
                ]
            }
        }

        # Se cargan datos según el caso elegido...

        # Se calculan los porcentajes de subvención para la tarea A1
        a1_v1, a1_v2, a1_v3 = valoracion_tarea_a1(
            selected_caso,
            data_totales_menores,
            data_totales_mayores)

        # Se calculan los porcentajes de subvención para la tarea A2
        a2_v1, a2_v2, a2_v3 = valoracion_tarea_a2(
            selected_caso,
            data_totales_menores,
            data_totales_mayores)

        # Se calculan los porcentajes de subvención para la tarea A3
        a3_v1, a3_v2, a3_v3 = valoracion_tarea_a3(
            selected_caso,
            data_totales_menores,
            data_totales_mayores)

        # Se calculan los porcentajes de subvención para la tarea A4
        a4_v1, a4_v2, a4_v3 = valoracion_tarea_a4(
            selected_caso,
            data_totales_menores,
            data_totales_mayores)

        # Se calculan los porcentajes de subvención para la tareas extra
        ae_v1, ae_v2, ae_v3 = valoracion_tareas_extra(
            selected_caso,
            data_totales_menores,
            data,
            municipios_grandes)

        # Se calculan los porcentajes de subvención para la actuación 2
        act2_v1, act2_v2, act2_v3 = valoracion_actuacion_2(selected_caso, not calidad_actuacion_2_media)

        ## Se establecen los porcentajes_maximos según el CASO, hay que calcularlos previamente
        #
        # ACTUACION 1
        #
        # Caso 1
        set_valores("Actuación 1", "Tarea A1", v1=a1_v1)                # 50% máximo
        set_valores("Actuación 1", "Tarea A2", v1=a2_v1)                # 20% máximo
        set_valores("Actuación 1", "Tarea A3", v1=a3_v1)                # 25% máximo
        set_valores("Actuación 1", "Tarea A4", v1=a4_v1)                #  5% máximo
        set_valores("Actuación 1", "Extra: Tareas A5, A6, B y C", v1=ae_v1)# 5% máximo

        # Caso 2
        set_valores("Actuación 1", "Tarea A1", v2=a1_v2)                # 50% máximo
        set_valores("Actuación 1", "Tarea A2", v2=a2_v2)                # 18% máximo
        set_valores("Actuación 1", "Tarea A3", v2=a3_v2)                # 23% máximo
        set_valores("Actuación 1", "Tarea A4", v2=a4_v2)                #  5% máximo
        set_valores("Actuación 1", "Extra: Tareas A5, A6, B y C", v2=ae_v2)# 5% máximo

        # Caso 3
        set_valores("Actuación 1", "Tarea A1", v3=a1_v3)                # 60% máximo
        set_valores("Actuación 1", "Tarea A2", v3=a2_v3)                # 30% máximo
        set_valores("Actuación 1", "Tarea A3", v3=a3_v3)                # N/A
        set_valores("Actuación 1", "Tarea A4", v3=a4_v3)                # N/A
        set_valores("Actuación 1", "Extra: Tareas A5, A6, B y C", v3=ae_v3)# 5% máximo

        # ACTUACION 2
        #
        # Caso 1
        set_valores("Actuación 2", "-", v1=act2_v1)                     # No se realiza

        # Caso 2
        set_valores("Actuación 2", "-", v2=act2_v2)                     #  4% máximo

        # Caso 3
        set_valores("Actuación 2", "-", v3=act2_v3)                     # 10% máximo

        msg = "Valoración de tareas recalculada"
        # TODO msg = MESSAGES.info("app_loaded_view", selected_view=selected_view)
        flash(msg, "success")

    except Exception as e:
        flash(str(e), "danger")

    return render_template("valoracion_tareas.html", breadcrumb=breadcrumb,
                           casos=casos,
                           selected_caso=selected_caso,
                           calidad_actuacion_2_media=calidad_actuacion_2_media,
                           csv_data_totales_menores = csv_data_totales_menores,
                           csv_data_totales_mayores = csv_data_totales_mayores,
                           csv_data=csv_data,
                           valoracion_criterios=valoracion_criterios)


if __name__ == "__main__":
    # En Windows hay que llamar a freeze_support() antes de crear procesos
    # cuando se arranca el script con python app.py
    from multiprocessing import freeze_support
    freeze_support()

    # Arrancar worker explícitamente en ejecución directa (dev)
    task_manager.start()

    # Si no se activó la autenticación por LDAP
    if not config.AUTH_LDAP:
        # Se arranca la apliación sin SSL para depuración y desarrollo
        app.run(host="0.0.0.0", port=80, debug=True)
    else:
        # Se arranca la aplicación con SSL
        app.run(host="0.0.0.0", port=443, debug=True, ssl_context=("certs/cert.pem", "certs/key.pem"))
        #
        # - Genera clave RSA 4096 bits (key.pem):
        #   openssl genpkey -algorithm RSA -out key.pem -pkeyopt rsa_keygen_bits:4096
        #   openssl genrsa -out key.pem 4096 (alternativamente)
        #
        # - Generar el certificado autofirmado (cert.pem) válido 365.000 días
        #   openssl req -x509 -new -nodes -key key.pem -sha256 -days 365000 -out cert.pem
        #       -config san.cnf -extensions v3_req
        #
        # - Verificar que el certificado contiene los SAN, busca la sección X509v3 Subject Alternative Name
        #   openssl x509 -in cert.pem -noout -text


# Creación de entorno virtual del proyecto...
#
# Borra la carpeta del virtualenv
# rmdir /s /q .venv
#
# Crea el nuevo entorno virtual
# python -m venv .venv
#
# Activa el virtualenv
# .\.venv\Scripts\Activate.ps1
# .\.venv\Scripts\activate.bat
#
# Se instala las librerias necesarias del proyecto
# pip install -r requirements.txt
#
# Comprobar las librerías instaladas en ese entorno
# python -m pip list
#
# Reinstalar de nuevo todos los requisitos
# pip install --upgrade -r requirements.txt
# 
# Para salir del virtualenv...
# deactivate
#
# NOTA
# En PyCharm:
# File > Settings > Python Interpreter
# Asegúrate de que el intérprete seleccionado sea .venv\Scripts\python.exe de tu proyecto.