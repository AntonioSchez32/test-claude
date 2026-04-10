from typing import TypedDict, Dict


# ------------------------------------------------------------
# Definición de tipos y funciones para la valoración de tareas
# ------------------------------------------------------------

class ContadoresIneDict(TypedDict, total=False):
    CMUN: int
    HH: int
    HC: int
    HD: int
    HS: int
    HV: int
    PP: int
    VC: int
    VV: int


class ContadoresTareasDict(TypedDict, total=False):
    HS_1: int
    HH_1: int
    A1HS: int
    HD_2: int
    HH_2: int
    A2HD: int
    HD_3: int
    HH_3: int
    VC_3: int
    VV_3: int
    A3VC: int
    HV_4: int
    HH_4: int
    A4HV: int
    HH_5: int
    A5HA: int
    HH_6: int
    VV_6: int
    A6HM: int
    A6VM: int
    BVA: int
    HC_C: int
    CHC: int


class Por100TareasDict(TypedDict, total=False):
    A1: float
    A2: float
    A3: float
    A4: float
    EXTRAS: float # Tareas extra A5, A6, B y C
    ACT2: float


class TareasDict(TypedDict, total=False):
    A1: int
    A2: int
    A3: int
    A4: int
    EXTRAS: int # Tareas extra A5, A6, B y C


TAREAS_VALIDAS = set(TareasDict.__annotations__.keys())
TAREAS_EXTRAS_PREFIX = ("A5", "A6", "B", "C")
ACTUACION_2_PREFIX = ("ACT2")


# Porcentajes de valoración de las tareas, uso: porcentajes_maximos[caso]["A3"] ó porcentajes_maximos[caso]["EXTRAS"]
#
# Importe máximo de subvención 1.260.000,00€ - BOE Núm. 178 Miércoles 24 de julio de 2024
# https://mptmd.gob.es/content/dam/mpt/es/mod/BOE-A-2024-15337-1a-RESOLUCION-CONCECION-PADRON.pdf
porcentajes_maximos: Dict[int, Por100TareasDict] = {
    1: {  # Caso 1       #
        "A1": 0.50,      # Hogares sin CIV
        "A2": 0.20,      # Registros con direccion padronal y catastral diferente
        "A3": 0.25,      # Registros del fichero de viviendas sin código vía INE
        "A4": 0.05,      # Registros del fichero de hogares sin código vía Catastro
        "EXTRAS": 0.05,  # Aplica si no se llegó a 100% en municipios de más de 20000 hab. (A5, A6, B y/o C)
        "ACT2": 0  # A5: Separación hogares, A6: Mejora de ficheros, B: Completar info territorial, C: Colectivos
    },
    2: {  # Caso 2
        "A1": 0.50,
        "A2": 0.18,
        "A3": 0.23,
        "A4": 0.05,
        "EXTRAS": 0.05,
        "ACT2": 0.04
    },
    3: {  # Caso 3
        "A1": 0.60,
        "A2": 0.30,
        "A3": 0,
        "A4": 0,
        "EXTRAS": 0.05,
        "ACT2": 0.10
    }
}


def get_porcentajes_maximos(caso: int, tarea: str) -> float:
    """ Retorna los valores máximos de porcentajes de subvención según el caso y la tarea indicados """
    tarea_mayus = tarea.upper()

    # 1. Tareas extras por prefijo
    if tarea_mayus.startswith(TAREAS_EXTRAS_PREFIX):
        return porcentajes_maximos[caso]["EXTRAS"]

    if tarea_mayus.startswith(ACTUACION_2_PREFIX):
        return porcentajes_maximos[caso]["ACT2"]

    # 2. Tareas normales
    if tarea_mayus not in TAREAS_VALIDAS:
        raise ValueError(
            f"Tarea inválida '{tarea}'. Las tareas válidas son: "
            f"{sorted(TAREAS_VALIDAS)} o tareas EXTRA (A5, A6, B, C)."
        )

    return porcentajes_maximos[caso][tarea_mayus]


def valoracion_tarea_a1(selected_caso, data_totales_menores, data_totales_mayores):

    """ Retorna el porcentaje de valoración de la tarea A1 según los datos proporcionados """

    # --- Cálculo de porcentajes_maximos base ---
    valor_a1hs = data_totales_menores.get("A1HS", 0)
    valor_hs = data_totales_menores.get("HS_1", 0)
    valor_hh = data_totales_menores.get("HH_1", 0)

    promedio_hs_hh = valor_hs / valor_hh if valor_hh else 0
    promedio_asignacion_civ = valor_a1hs / valor_hs if valor_hs else 0

    int_selected_caso = int(selected_caso)
    porcentaje_max_a1 = get_porcentajes_maximos(int_selected_caso, "A1")

    # --- Reglas de porcentaje ---
    if (promedio_hs_hh >= 0.50 and promedio_asignacion_civ >= 0.70) or \
       (0.25 <= promedio_hs_hh <= 0.50 and promedio_asignacion_civ >= 0.80) or \
       (promedio_hs_hh < 0.25 and promedio_asignacion_civ >= 0.90):
        porcentaje = 1
    elif (promedio_hs_hh >= 0.50 and 0.50 <= promedio_asignacion_civ <= 0.70) or \
         (0.25 <= promedio_hs_hh <= 0.50 and 0.60 <= promedio_asignacion_civ <= 0.80) or \
         (promedio_hs_hh < 0.25 and 0.70 <= promedio_asignacion_civ <= 0.90):
        porcentaje = 0.666
    elif (promedio_hs_hh >= 0.50 and 0.25 <= promedio_asignacion_civ <= 0.50) or \
         (0.25 <= promedio_hs_hh <= 0.50 and 0.35 <= promedio_asignacion_civ <= 0.60) or \
         (promedio_hs_hh < 0.25 and 0.45 <= promedio_asignacion_civ <= 0.70):
        porcentaje = 0.333
    else:
        porcentaje = 0

    porcentaje *= porcentaje_max_a1

    # --- Cálculo adicional si no llega al máximo ---
    if porcentaje < porcentaje_max_a1:
        valor_a1hs = data_totales_mayores.get("A1HS", 0)
        valor_hs = data_totales_mayores.get("HS_1", 0)
        promedio_a1hs_hs = valor_a1hs / valor_hs if valor_hs else 0

        if promedio_a1hs_hs >= 0.80:
            porcentaje += 0.10
        elif 0.60 <= promedio_a1hs_hs <= 0.80:
            porcentaje += 0.05
        elif 0.35 <= promedio_a1hs_hs <= 0.60:
            porcentaje += 0.03

    # --- Límite máximo ---
    if porcentaje > porcentaje_max_a1:
        porcentaje = porcentaje_max_a1

    # --- Resultado por caso ---
    porcentaje_str = f"{porcentaje * 100:.2f}"

    tarea_a1_c1 = tarea_a1_c2 = tarea_a1_c3 = "0.00"

    match int_selected_caso:
        case 1:
            tarea_a1_c1 = porcentaje_str
        case 2:
            tarea_a1_c2 = porcentaje_str
        case 3:
            tarea_a1_c3 = porcentaje_str

    return tarea_a1_c1, tarea_a1_c2, tarea_a1_c3


def valoracion_tarea_a2(selected_caso, data_totales_menores, data_totales_mayores):

    """ Retorna el porcentaje de valoración de la tarea A2 según los datos proporcionados """

    # --- Cálculo de porcentajes_maximos base ---
    valor_a2hd = data_totales_menores.get("A2HD", 0)
    valor_hd = data_totales_menores.get("HD_2", 0)
    valor_hh = data_totales_menores.get("HH_2", 0)

    promedio_hd_hh = valor_hd / valor_hh if valor_hh else 0
    promedio_dir_catas_padron_dif = valor_a2hd / valor_hd if valor_hd else 0

    int_selected_caso = int(selected_caso)
    porcentaje_max_a2 = get_porcentajes_maximos(int_selected_caso, "A2")

    # --- Reglas de porcentaje ---
    if (promedio_hd_hh >= 0.35 and promedio_dir_catas_padron_dif >= 0.70) or \
       (0.20 <= promedio_hd_hh <= 0.35 and promedio_dir_catas_padron_dif >= 0.80) or \
       (promedio_hd_hh < 0.20 and promedio_dir_catas_padron_dif >= 0.90):
        porcentaje = 1
    elif (promedio_hd_hh >= 0.35 and 0.50 <= promedio_dir_catas_padron_dif <= 0.70) or \
         (0.20 <= promedio_hd_hh <= 0.35 and 0.60 <= promedio_dir_catas_padron_dif <= 0.80) or \
         (promedio_hd_hh < 0.20 and 0.70 <= promedio_dir_catas_padron_dif <= 0.90):
        porcentaje = 0.666
    elif (promedio_hd_hh >= 0.35 and 0.25 <= promedio_dir_catas_padron_dif <= 0.50) or \
         (0.20 <= promedio_hd_hh <= 0.35 and 0.35 <= promedio_dir_catas_padron_dif <= 0.60) or \
         (promedio_hd_hh < 0.20 and 0.45 <= promedio_dir_catas_padron_dif <= 0.70):
        porcentaje = 0.333
    else:
        porcentaje = 0

    porcentaje *= porcentaje_max_a2

    # --- Cálculo adicional si no llega al máximo ---
    if porcentaje < porcentaje_max_a2:
        valor_a2hd = data_totales_mayores.get("A2HD", 0)
        valor_hd = data_totales_mayores.get("HD_2", 0)
        promedio_a2hd_hd = valor_a2hd / valor_hd if valor_hd else 0

        if promedio_a2hd_hd >= 0.80:
            porcentaje += 0.05
        elif 0.60 <= promedio_a2hd_hd <= 0.80:
            porcentaje += 0.03
        elif 0.35 <= promedio_a2hd_hd <= 0.60:
            porcentaje += 0.01

    # --- Límite máximo ---
    if porcentaje > porcentaje_max_a2:
        porcentaje = porcentaje_max_a2

    # --- Resultado por caso ---
    porcentaje_str = f"{porcentaje * 100:.2f}"

    tarea_a2_c1 = tarea_a2_c2 = tarea_a2_c3 = "0.00"

    match int_selected_caso:
        case 1:
            tarea_a2_c1 = porcentaje_str
        case 2:
            tarea_a2_c2 = porcentaje_str
        case 3:
            tarea_a2_c3 = porcentaje_str

    return tarea_a2_c1, tarea_a2_c2, tarea_a2_c3


def valoracion_tarea_a3(selected_caso, data_totales_menores, data_totales_mayores):

    """ Retorna el porcentaje de valoración de la tarea A3 según los datos proporcionados """

    # --- Cálculo de porcentajes_maximos base ---
    valor_a3vc = data_totales_menores.get("A3VC", 0)
    valor_vc = data_totales_menores.get("HD_3", 0)
    valor_vv = data_totales_menores.get("HH_3", 0)

    promedio_vc_vv = valor_vc / valor_vv if valor_vv else 0
    promedio_asig_cvia_ine = valor_a3vc / valor_vc if valor_vc else 0

    int_selected_caso = int(selected_caso)
    porcentaje_max_a3 = get_porcentajes_maximos(int_selected_caso, "A3")

    # --- Reglas de porcentaje ---
    if (promedio_vc_vv >= 0.35 and promedio_asig_cvia_ine >= 0.70) or \
       (0.20 <= promedio_vc_vv <= 0.35 and promedio_asig_cvia_ine >= 0.80) or \
       (promedio_vc_vv < 0.20 and promedio_asig_cvia_ine >= 0.90):
        porcentaje = 1
    elif (promedio_vc_vv >= 0.35 and 0.50 <= promedio_asig_cvia_ine <= 0.70) or \
         (0.20 <= promedio_vc_vv <= 0.35 and 0.60 <= promedio_asig_cvia_ine <= 0.80) or \
         (promedio_vc_vv < 0.20 and 0.70 <= promedio_asig_cvia_ine <= 0.90):
        porcentaje = 0.666
    elif (promedio_vc_vv >= 0.35 and 0.25 <= promedio_asig_cvia_ine <= 0.50) or \
         (0.20 <= promedio_vc_vv <= 0.35 and 0.35 <= promedio_asig_cvia_ine <= 0.60) or \
         (promedio_vc_vv < 0.20 and 0.45 <= promedio_asig_cvia_ine <= 0.70):
        porcentaje = 0.333
    else:
        porcentaje = 0

    porcentaje *= porcentaje_max_a3

    # --- Cálculo adicional si no llega al máximo ---
    if porcentaje < porcentaje_max_a3:
        valor_a3vc = data_totales_mayores.get("A3VC", 0)
        valor_hd = data_totales_mayores.get("VC_3", 0)
        promedio_a3vc_vc = valor_a3vc / valor_vc if valor_vc else 0

        if promedio_a3vc_vc >= 0.80:
            porcentaje += 0.05
        elif 0.60 <= promedio_a3vc_vc <= 0.80:
            porcentaje += 0.03
        elif 0.35 <= promedio_a3vc_vc <= 0.60:
            porcentaje += 0.01

    # --- Límite máximo ---
    if porcentaje > porcentaje_max_a3:
        porcentaje = porcentaje_max_a3

    # --- Resultado por caso ---
    porcentaje_str = f"{porcentaje * 100:.2f}"

    tarea_a3_c1 = tarea_a3_c2 = "0.00"
    tarea_a3_c3 = "-"

    match int_selected_caso:
        case 1:
            tarea_a3_c1 = porcentaje_str
        case 2:
            tarea_a3_c2 = porcentaje_str
        case 3:
            tarea_a3_c3 = "-" # El caso 3 no tiene valoración en esta situación

    return tarea_a3_c1, tarea_a3_c2, tarea_a3_c3


def valoracion_tarea_a4(selected_caso, data_totales_menores, data_totales_mayores):

    """ Retorna el porcentaje de valoración de la tarea A4 según los datos proporcionados """

    # --- Cálculo de porcentajes_maximos base ---
    valor_a4hv = data_totales_menores.get("A4HV", 0)
    valor_hv = data_totales_menores.get("HV_4", 0)
    valor_hh = data_totales_menores.get("HH_4", 0)

    promedio_hv_hh = valor_hv / valor_hh if valor_hh else 0
    promedio_asig_cvia_catastro = valor_a4hv / valor_hv if valor_hv else 0

    int_selected_caso = int(selected_caso)
    porcentaje_max_a4 = get_porcentajes_maximos(int_selected_caso, "A4")

    # --- Reglas de porcentaje ---
    if (promedio_hv_hh >= 0.10 and promedio_asig_cvia_catastro >= 0.70) or \
       (0.05 <= promedio_hv_hh <= 0.10 and promedio_asig_cvia_catastro >= 0.80) or \
       (promedio_hv_hh < 0.05 and promedio_asig_cvia_catastro >= 0.90):
        porcentaje = 1
    elif (promedio_hv_hh >= 0.10 and 0.50 <= promedio_asig_cvia_catastro <= 0.70) or \
         (0.05 <= promedio_hv_hh <= 0.10 and 0.60 <= promedio_asig_cvia_catastro <= 0.80) or \
         (promedio_hv_hh < 0.05 and 0.70 <= promedio_asig_cvia_catastro <= 0.90):
        porcentaje = 0.666
    elif (promedio_hv_hh >= 0.10 and 0.25 <= promedio_asig_cvia_catastro <= 0.50) or \
         (0.05 <= promedio_hv_hh <= 0.10 and 0.35 <= promedio_asig_cvia_catastro <= 0.60) or \
         (promedio_hv_hh < 0.05 and 0.45 <= promedio_asig_cvia_catastro <= 0.70):
        porcentaje = 0.333
    else:
        porcentaje = 0

    porcentaje *= porcentaje_max_a4

    # --- Cálculo adicional si no llega al máximo ---
    if porcentaje < porcentaje_max_a4:
        valor_a4hv = data_totales_mayores.get("A4HV", 0)
        valor_hv = data_totales_mayores.get("HV_4", 0)
        promedio_a4hv_hv = valor_a4hv / valor_hv if valor_hv else 0

        if promedio_a4hv_hv >= 0.80:
            porcentaje += 0.01
        elif 0.60 <= promedio_a4hv_hv <= 0.80:
            porcentaje += 0.005
        elif 0.35 <= promedio_a4hv_hv <= 0.60:
            porcentaje += 0.0025

    # --- Límite máximo ---
    if porcentaje > porcentaje_max_a4:
        porcentaje = porcentaje_max_a4

    # --- Resultado por caso ---
    porcentaje_str = f"{porcentaje * 100:.2f}"

    tarea_a4_c1 = tarea_a4_c2 = "0.00"
    tarea_a4_c3 = "-"

    match int_selected_caso:
        case 1:
            tarea_a4_c1 = porcentaje_str
        case 2:
            tarea_a4_c2 = porcentaje_str
        case 3:
            tarea_a4_c3 = "-" # El caso 3 no tiene valoración en esta situación

    return tarea_a4_c1, tarea_a4_c2, tarea_a4_c3


def valoracion_tareas_extra(selected_caso, data_totales_menores, data_completo, municipios_grandes):

    """ Retorna el porcentaje de valoración de las tareas A5, A6, B y C según los datos proporcionados """

    valor_hh = data_totales_menores.get("HH_5", 0)
    valor_a5ha = data_totales_menores.get("A5HA", 0)
    valor_vv = data_totales_menores.get("VV_6", 0)
    valor_a6hm = data_totales_menores.get("A6HM", 0)
    valor_a6vm = data_totales_menores.get("A6VM", 0)
    valor_bva = data_totales_menores.get("BVA", 0)
    valor_hc = data_totales_menores.get("HC_C", 0)
    valor_chc = data_totales_menores.get("CHC", 0)

    # --- Cálculo de porcentajes_maximos base ---
    int_selected_caso = int(selected_caso)
    porcentaje_max_extras = get_porcentajes_maximos(int_selected_caso, "EXTRAS")

    # Comprobar si se ha enviado información de al menos dos de las cuatro tareas restantes de la actuación 1
    # (A5, A6, B y C) para un 70% de los municipios de menos de 20.000 habitantes.
    #
    # Comprobar si se ha enviado información de una de las cuatro tareas restantes de la actuación 1 (A5, A6, B y C)
    # para un 40% de los municipios de menos de 20.000 habitantes.
    #
    data_filtrados_menores = filtrar_municipios_menores(data_completo, municipios_grandes)
    porcentaje = comprobar_tareas_restantes(data_filtrados_menores)

    # --- Resultado por caso ---
    porcentaje_str = f"{porcentaje * 100:.2f}"

    tareas_extra_c1 = tareas_extra_c2 = tareas_extra_c3 = "0.00"

    match int_selected_caso:
        case 1:
            tareas_extra_c1 = porcentaje_str
        case 2:
            tareas_extra_c2 = porcentaje_str
        case 3:
            tareas_extra_c3 = porcentaje_str

    return tareas_extra_c1, tareas_extra_c2, tareas_extra_c3


def valoracion_actuacion_2(selected_caso: str, calidad_actuacion_alta: bool):

    """ Retorna el porcentaje de valoración de la actuación 2 en función de la calidad del trabajo realizado """

    # --- Cálculo de porcentajes_maximos base ---
    int_selected_caso = int(selected_caso)

    porcentaje_max_actuacion_2 = get_porcentajes_maximos(int_selected_caso, "ACT2")

    # En función de los trabajos realizados, si la calidad es alta 100% del bloque, sino 66,6% del bloque.
    if calidad_actuacion_alta:
        porcentaje = porcentaje_max_actuacion_2
    else:
        porcentaje = 0.666 * porcentaje_max_actuacion_2

    # --- Resultado por caso ---
    porcentaje_str = f"{porcentaje * 100:.2f}"

    actuacion_2_c1 = "No se realiza"
    actuacion_2_c2 = actuacion_2_c3 = "0.00"

    match int_selected_caso:
        case 1:
            actuacion_2_c1 = "No se realiza"
        case 2:
            actuacion_2_c2 = porcentaje_str
        case 3:
            actuacion_2_c3 = porcentaje_str

    return actuacion_2_c1, actuacion_2_c2, actuacion_2_c3


def filtrar_municipios_menores(
    data: dict[int, ContadoresTareasDict],
    municipios_grandes: set[int]
) -> dict[int, ContadoresTareasDict]:
    """
    Devuelve un nuevo diccionario con solo los municipios menores
    de 20.000 habitantes (es decir, los que NO estén en municipios_grandes).
    Mantiene el mismo formato que la estructura de entrada.
    """

    # Devolvemos solamente los municipios cuyo CMUN NO esté en la lista de grandes
    return {
        cmun: valores
        for cmun, valores in data.items()
        if cmun not in municipios_grandes
    }


def comprobar_tareas_restantes(
    data_menores: dict[int, ContadoresTareasDict]
) -> float:
    """
    Comprueba si los municipios menores cumplen:
    - 70% con al menos 2 tareas enviadas (A5, A6, B, C)
    - 40% con al menos 1 tarea enviada (A5, A6, B, C)

    Retorna:
        (cumple_70, cumple_40, porcentaje_2_tareas, porcentaje_1_tarea)
    """

    tareas_por_municipio = []

    for cmun, valores in data_menores.items():

        # Contar cuántas de las tareas A5, A6, B, C tienen información (>0)
        count = 0

        # A5
        if valores.get("A5HA", 0) > 0:
            count += 1

        # A6 (cuenta si A6HM o A6VM > 0)
        if valores.get("A6HM", 0) > 0 or valores.get("A6VM", 0) > 0:
            count += 1

        # B
        if valores.get("BVA", 0) > 0:
            count += 1

        # C
        if valores.get("CHC", 0) > 0:
            count += 1

        tareas_por_municipio.append(count)

    total = len(tareas_por_municipio)

    # Municipios con al menos 2 tareas
    m2 = sum(1 for x in tareas_por_municipio if x >= 2)

    # Municipios con al menos 1 tarea
    m1 = sum(1 for x in tareas_por_municipio if x >= 1)

    # Porcentajes
    pct_2 = m2 / total if total else 0
    pct_1 = m1 / total if total else 0

    # Verificación de umbrales
    cumple_70_pct = pct_2 >= 0.70
    cumple_40_pct = pct_1 >= 0.40

    if cumple_70_pct:
        return 0.05
    elif cumple_40_pct:
        return 0.025
    else:
        return 0


def totalizar_municipios_mayores(
    data: dict[int, ContadoresTareasDict],
    municipios_grandes: set[int]
) -> ContadoresTareasDict:
    """
    Devuelve un solo ContadoresTareasDict que representa la suma de
    todos los municipios con menos de 20.000 habitantes.
    NO devuelve CMUN.
    """

    # Crear la estructura vacía con todas las claves del TypedDict
    total: ContadoresTareasDict = {
        key: 0 for key in ContadoresTareasDict.__annotations__.keys()
    }

    for cmun, valores in data.items():
        if cmun in municipios_grandes:
            # Sumar campo a campo
            for key in ContadoresTareasDict.__annotations__.keys():
                total[key] += valores.get(key, 0)

    return total


def totalizar_municipios_menores(
    data: dict[int, ContadoresTareasDict],
    municipios_grandes: set[int]
) -> ContadoresTareasDict:
    """
    Devuelve un solo ContadoresTareasDict que representa la suma de
    todos los municipios con menos de 20.000 habitantes.
    NO devuelve CMUN.
    """

    # Crear la estructura vacía con todas las claves del TypedDict
    total: ContadoresTareasDict = {
        key: 0 for key in ContadoresTareasDict.__annotations__.keys()
    }

    for cmun, valores in data.items():
        if cmun not in municipios_grandes:
            # Sumar campo a campo
            for key in ContadoresTareasDict.__annotations__.keys():
                total[key] += valores.get(key, 0)

    return total