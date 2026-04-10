# pipeline/manager.py
import logging.config
from threading import Thread
from queue import Empty
from pathlib import Path
import config
from utils.messages_loader import MESSAGES
from .status import TaskStatus
from .task import process_task, safe_cleanup

logging.config.fileConfig("logging.conf", disable_existing_loggers=False)
logger = logging.getLogger("pipeline")

class WorkerManager:
    def __init__(self, tasks_shared, semaphore, q):
        """
        tasks_shared: Manager().dict() proxy compartido entre procesos
        semaphore: threading . Semaphore (CREADO dentro del proceso worker)
        q: multiprocessing.Queue compartida con el proceso principal
        """
        self.tasks = tasks_shared
        self.sem = semaphore
        self.q = q
        self.running = True

    def run(self):
        """
        Loop principal del proceso worker: consume la cola y lanza hilos.
        """
        while self.running:

            # Inicializamos un task_id seguro para excepciones tempranas
            task_id = None

            try:
                task_id, zip_path = self.q.get(timeout=1)
                # Si no existe metadata, continuar
                if not task_id or self.tasks is None:
                    continue

                # Si la tarea fue eliminada por otro (race) -> saltar
                if task_id not in self.tasks:
                    continue

            except Empty:
                continue
            except Exception as e:
                # task_id puede ser None si la excepción ocurre ANTES del get()
                safe_id = task_id if task_id else TaskStatus.DESCONOCIDO.value
                msg = MESSAGES.errors("worker_unreadable_queue", safe_id=safe_id, error=e)
                logger.error(msg)
                continue

            # Adquirir semáforo (slot de ejecución) antes de crear el hilo
            self.sem.acquire()
            t = Thread(
                target=self._run_task_thread,
                args=(task_id, zip_path),
                daemon=True
            )
            t.start()

    def _run_task_thread(self, task_id, zip_path):
        """
        Hilo encargado de procesar una tarea concreta.
        Controla:
        - Cancelación antes de iniciar (cleanup + eliminación)
        - Creación del directorio de trabajo
        - Ejecución del pipeline
        - Eliminación automática de tareas terminadas o canceladas
        """

        try:
            # Leer metadata actual de la tarea
            t = self.tasks.get(task_id)

            # Si la tarea ya no existe → no hay nada que hacer
            if not t:
                return

            # ---------------------------------------------------------------
            # 🔥 CANCELADA ANTES DE ENTRAR → limpiar + eliminar + salir
            # ---------------------------------------------------------------
            if t.get("cancelled"):
                # Hacer cleanup aquí porque la tarea nunca va a entrar al pipeline
                task_dir = (Path(config.PROCESSING_DIR) / task_id).resolve()
                safe_cleanup(task_id, zip_path, task_dir, self.tasks)

                # Y eliminarla del diccionario
                del self.tasks[task_id]
                return

            # ---------------------------------------------------------------
            # 🔨 CREAR DIRECTORIO DE TRABAJO
            # ---------------------------------------------------------------
            task_dir = (Path(config.PROCESSING_DIR) / task_id).resolve()
            task_dir.mkdir(parents=True, exist_ok=True)

            # ---------------------------------------------------------------
            # 🚀 EJECUTAR PIPELINE COMPLETO (process_task)
            # ---------------------------------------------------------------
            process_task(task_id, zip_path, task_dir, self.tasks)


        finally:
            # Liberar el semáforo aunque ocurra una excepción
            try:
                self.sem.release()
            except Exception:
                pass

            # ---------------------------------------------------------------
            # 🧹 ELIMINACIÓN AUTOMÁTICA DE TAREAS FINALIZADAS
            # ---------------------------------------------------------------
            t = self.tasks.get(task_id)
            if t and t.get("finished"):
                # Llamar siempre a cleanup si terminó OK o cancelada dentro del pipeline
                if t.get("status") in (TaskStatus.FINALIZADA.value, TaskStatus.CANCELADA.value):
                    try:
                        task_dir = (Path(config.PROCESSING_DIR) / task_id).resolve()
                        safe_cleanup(task_id, zip_path, task_dir, self.tasks)
                    except Exception as e:
                        msg = MESSAGES.errors("worker_cleanup_error", task_id=task_id, error=e)
                        logger.error(msg)
                # Ahora sí eliminar la entrada de la tarea
                del self.tasks[task_id]
