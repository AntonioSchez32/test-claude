from configparser import ConfigParser
from pathlib import Path


class MessageCatalog:
    """
    Helper para cargar mensajes de un INI y formatearlos con parámetros.
    """

    def __init__(self, ini_path: Path):
        self.cfg = ConfigParser()
        read_files = self.cfg.read(ini_path, encoding="utf-8")

        if not read_files:
            raise FileNotFoundError(f"No se pudo cargar el fichero de mensajes: {ini_path}")

    def get(self, section: str, key: str, **kwargs) -> str:
        """
        Devuelve el mensaje formateado.
        Lanza KeyError si la sección o clave no existe.
        """
        try:
            template = self.cfg[section][key]
        except KeyError as e:
            raise KeyError(f"Mensaje no encontrado: [{section}] {key}") from e

        # Formatear si hay argumentos
        if kwargs:
            return template.format(**kwargs)

        return template

    # Conveniencia: acceso directo tipo msg.errors("ctl_no_csv_files")
    def __getattr__(self, section: str):
        if section not in self.cfg:
            raise AttributeError(f"La sección '{section}' no existe en el fichero de mensajes.")

        def section_accessor(key: str, **kwargs):
            return self.get(section, key, **kwargs)

        return section_accessor