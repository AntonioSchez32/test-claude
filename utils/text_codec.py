# utils/text_codec.py
import unicodedata
from pathlib import Path
from charset_normalizer import from_bytes


def leer_o_convertir_a_utf8(src_path: Path) -> str:
    """
    Lee un fichero de texto usando detección robusta, priorizando Windows-1252.
    Orden final de detección:
      1) charset-normalizer (general)
      2) Windows-1252 (prioritario)
      3) UTF-8 (por si ya viene convertido)
      4) IBM/DOS: cp850 → cp437
      5) Latin-1
      6) Último recurso: latin-1 con 'replace'

    Devuelve SIEMPRE texto Unicode válido (UTF-8 en memoria).
    """

    raw = src_path.read_bytes()

    # ----------------------------------------------------------
    # 0) Detectar si es binario (contiene bytes nulos)
    # ----------------------------------------------------------
    if b"\x00" in raw:
        # Byte nulo → no es texto real → se devuelve algo legible.
        return raw.decode("latin-1", errors="replace")

    # ----------------------------------------------------------
    # 1) Intentar charset-normalizer primero (heurística moderna)
    # ----------------------------------------------------------
    try:
        best = from_bytes(raw).best()
        if best is not None:
            text = str(best)
            return unicodedata.normalize("NFC", text)
    except Exception:
        pass

    # ----------------------------------------------------------
    # 2) Fallback manual priorizando Windows-1252
    # ----------------------------------------------------------
    # ORDEN ÓPTIMO:
    #  - cp1252   → encoding REAL de Windows en Europa
    #  - utf-8    → útil por si el fichero ya estaba convertido
    #  - cp850    → IBM Europa (muy común en exportaciones)
    #  - cp437    → OEM DOS original
    #  - latin-1  → fallback estable
    #
    for enc in ("cp1252", "utf-8", "cp850", "cp437", "latin-1"):
        try:
            text = raw.decode(enc)
            return unicodedata.normalize("NFC", text)
        except UnicodeDecodeError:
            continue

    # ----------------------------------------------------------
    # 3) Último recurso: latin-1 "permisivo"
    # ----------------------------------------------------------
    text = raw.decode("latin-1", errors="replace")
    return unicodedata.normalize("NFC", text)

