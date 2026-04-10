# workers.py
from multiprocessing import Process, Manager, Queue
from pathlib import Path

import config
from pipeline.manager import WorkerManager
from pipeline.status import TaskStatus

# Instancia retrasada hasta que el main la registre
_task_manager_instance = None


def _worker_process_entry(tasks_proxy, max_workers, queue_obj):
    """
    Entrada del proceso worker. Aquí SE CREA el Semaphore de hilos (threading.Semaphore)
    y se lanza el WorkerManager (que crea hilos para procesar tareas).
    """
    # Crear un semáforo de hilos dentro del proceso worker (threading.Semaphore)
    # Import aquí para evitar mezclar semáforos entre procesos a nivel de import.
    from threading import Semaphore
    sem = Semaphore(max_workers)

    wm = WorkerManager(tasks_proxy, sem, queue_obj)
    wm.run()


class TaskManager:
    """
    Manager que vive en el proceso principal (Flask) y lanza un proceso worker.
    Uso:
      - start() arrancará el proceso worker (y creará Manager() perezosamente).
      - enqueue() pone tareas en la cola multiprocessing.Queue() compartida.
    """

    def __init__(self, max_workers=config.MAX_CONCURRENT_WORKERS):
        self._max_workers = max_workers

        # Manager y tasks se crean perezosamente en start() para evitar problemas
        # si este módulo se importa en varios procesos.
        self._manager = None
        self.tasks = None

        # Cola multiprocessing para comunicar con el proceso worker
        self._queue = Queue()
        self._process = None

    @property
    def q(self):
        return self._queue

    def start(self):
        """Arranca el proceso worker si no está ya arrancado."""
        if not self._process or not self._process.is_alive():
            # Crear Manager() y dict compartido en el proceso principal justo antes de arrancar
            if self._manager is None:
                self._manager = Manager()
            if self.tasks is None:
                self.tasks = self._manager.dict()

            self._process = Process(
                target=_worker_process_entry,
                args=(self.tasks, self._max_workers, self._queue),
                daemon=True
            )
            self._process.start()

    def stop(self):
        """Detener el proceso worker (forzado)."""
        if self._process:
            try:
                self._process.terminate()
                self._process.join(3)
            except Exception:
                pass
            self._process = None

    def enqueue(self, task_id, zip_path, filename):
        """
        Encola una nueva tarea. Lanza start() perezosamente para evitar que
        Manager() se cree en imports.
        """
        self.start()

        # Asegurar ruta absoluta → CRUCIAL
        zip_path = str(Path(zip_path).resolve())

        # CORRECCIÓN: asignación real al dict (antes tenías un type-hint en vez de '=')
        self.tasks[task_id] = {
            "status": TaskStatus.EN_COLA.value,
            "zip_path": zip_path,
            "filename": filename,
            "cancelled": False,
            "finished": False,
        }

        # Encolar en la cola de multiprocessing para que el proceso worker la recoja
        self._queue.put((task_id, zip_path))

    def get_all_tasks(self):
        if self.tasks is None:
            return {}
        return dict(self.tasks)

    def get_task(self, tid):
        if self.tasks is None:
            return {"status": TaskStatus.DESCONOCIDO.value}
        return dict(self.tasks.get(tid, {"status": TaskStatus.DESCONOCIDO.value}))

    def queue_size(self):
        return self._queue.qsize()

    def retry(self, task_id):
        if self.tasks is None:
            return None

        old = self.tasks.get(task_id)
        if not old or old.get("status") != TaskStatus.ERROR.value:
            return None

        zip_path = old.get("zip_path")
        if not zip_path:
            return None

        import uuid
        new_id = str(uuid.uuid4())

        # marcar como reiniciado
        d = dict(old)
        d["restarted_as"] = new_id
        self.tasks[task_id] = d

        # encolar nuevo
        self.enqueue(new_id, zip_path, d.get("filename"))
        return new_id

    def exists(self, task_id):
        return self.tasks is not None and task_id in self.tasks

    def delete(self, task_id):
        """Elimina la tarea del diccionario compartido (usado por endpoints)."""
        try:
            if self.tasks is None:
                return False
            if task_id in self.tasks:
                del self.tasks[task_id]
                return True
            return False
        except Exception:
            return False


def get_task_manager():
    global _task_manager_instance
    return _task_manager_instance


def set_task_manager(instance):
    """Registrar la instancia global (para que get_task_manager() funcione)."""
    global _task_manager_instance
    _task_manager_instance = instance
