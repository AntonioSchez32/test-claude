$(function () {
    // Inicializar todos los tooltips en la página
    initTooltips();
});

//Guardamos la posición del cursor en todo momento para gestionar tooltips
let mouseX = -1, mouseY = -1;

$(document).on('mousemove', function(e) {
    mouseX = e.clientX;
    mouseY = e.clientY;
});

function destroyAllTooltips(container = document) {
    const tooltips = container.querySelectorAll('[data-bs-toggle="tooltip"]');
    tooltips.forEach(el => {
        const instance = bootstrap.Tooltip.getInstance(el);
        if (instance) instance.dispose();
    });
}

function initTooltips() {
    $('[data-bs-toggle="tooltip"]').each(function () {
        const $el = $(this);

        // Destruir tooltip existente si lo hay
        const existing = bootstrap.Tooltip.getInstance(this);
        if (existing) existing.dispose();

        // Crear tooltip nuevo
        const tooltip = new bootstrap.Tooltip(this, {
            placement: 'auto',
            trigger: 'hover focus'
        });

        // Detectar si el cursor está sobre este elemento
        const rect = this.getBoundingClientRect();
        if (
            mouseX >= rect.left &&
            mouseX <= rect.right &&
            mouseY >= rect.top &&
            mouseY <= rect.bottom
        ) {
            tooltip.show();  // mostrar tooltip si el cursor está encima
        }
    });
}

/*********************************************************
 *  VARIABLES GLOBALES
 *********************************************************/
let generalModalCallback = null;
let ajaxActiveRequests = 0;

/*********************************************************
 *  INICIALIZACIÓN GENERAL (EVENTOS DEL MODAL)
 *********************************************************/
$(function () {
    const confirmBtn = document.getElementById("generalModalConfirmBtn");

    confirmBtn.addEventListener("click", () => {
        if (typeof generalModalCallback === "function") {
            generalModalCallback();
        }

        const modalEl = document.getElementById("generalModal");
        const modal = bootstrap.Modal.getInstance(modalEl);
        modal.hide();
    });
});

/*********************************************************
 *  MODAL GENERAL (GLOBAL)
 *********************************************************/
window.openGeneralModal = function ({
    title = "Confirmar",
    body = "",
    confirmText = "Aceptar",
    confirmClass = "btn-primary",
    headerClass = "bg-primary",
    onConfirm = null
}) {

    const modalEl = document.getElementById("generalModal");
    const modal = new bootstrap.Modal(modalEl);

    document.getElementById("generalModalTitle").innerHTML = title;
    document.getElementById("generalModalBody").innerHTML = body;

    const confirmBtn = document.getElementById("generalModalConfirmBtn");
    confirmBtn.innerHTML = confirmText;
    confirmBtn.className = "btn " + confirmClass;

    const header = document.getElementById("generalModalHeader");
    header.className = "modal-header text-white " + headerClass;

    generalModalCallback = onConfirm;

    modal.show();
};

/*********************************************************
 *  MENSAJES AJAX (GLOBAL)
 *********************************************************/
window.showAjaxMessage = function (category, message, duration = 5000) {

    const container = document.getElementById("ajaxMessages");
    if (!container) return;

    const id = "ajaxmsg_" + Math.random().toString(36).substr(2, 9);

    const html = `
        <div id="${id}"
             class="alert alert-${category} alert-dismissible fade show shadow-sm mx-3"
             role="alert" style="font-size: 0.95rem;">
            ${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    `;

    container.insertAdjacentHTML("beforeend", html);

    setTimeout(() => {
        const el = document.getElementById(id);
        if (el) {
            const alert = bootstrap.Alert.getOrCreateInstance(el);
            alert.close();
        }
    }, duration);
};

/*********************************************************
 *  AJAX LOADER (GLOBAL)
 *********************************************************/
window.showAjaxLoader = function () {
    document.getElementById("ajaxLoader").style.display = "flex";
};

window.hideAjaxLoader = function () {
    document.getElementById("ajaxLoader").style.display = "none";
};

/*********************************************************
 *  WRAPPER GLOBAL DE FETCH() CON LOADER INTEGRADO
 *********************************************************/
const originalFetch = window.fetch;

window.fetch = async (input, init = {}) => {

    const noLoader = init && init.noLoader === true;

    if (!noLoader) {
        ajaxActiveRequests++;
        showAjaxLoader();
    }

    try {
        const response = await originalFetch(input, init);
        return response;

    } catch (err) {
        throw err;

    } finally {
        if (!noLoader) {
            ajaxActiveRequests--;
            if (ajaxActiveRequests <= 0) {
                hideAjaxLoader();
            }
        }
    }
};


/**
 * Exporta el contenido de una tabla HTML a un archivo CSV.
 *
 * @param {string} tableId   - ID de la tabla HTML que se desea exportar.
 * @param {string} filename  - Nombre del archivo CSV resultante (incluye .csv).
 * @param {string} delimiter - Carácter separador usado en el CSV (por defecto ";").
 *
 * La función recorre todas las filas (<tr>) y columnas (<th> y <td>) de la tabla,
 * genera una cadena CSV y fuerza la descarga automática del fichero.
 * También incluye un BOM UTF-8 para compatibilidad con Excel.
 */
function exportTableToCSV(tableId, filename = "export.csv", delimiter = ";") {
    const table = document.getElementById(tableId);
    if (!table) {
        console.error(`No existe una tabla con id: ${tableId}`);
        return;
    }

    let csv = [];
    let rows = table.querySelectorAll("tr");

    rows.forEach(row => {
        let cols = row.querySelectorAll("th, td");
        let rowData = [];

        cols.forEach(col => {
            // Limpieza de saltos de línea y separadores
            let text = col.innerText.replace(/(\r\n|\n|\r)/gm, " ").trim();
            text = text.replace(new RegExp(delimiter, "g"), ",");
            rowData.push(text);
        });

        csv.push(rowData.join(delimiter));
    });

    const csvString = csv.join("\n");
    const blob = new Blob(["\ufeff" + csvString], { type: "text/csv;charset=utf-8;" }); // UTF-8 BOM para Excel
    const link = document.createElement("a");

    link.href = URL.createObjectURL(blob);
    link.download = filename;
    link.click();
}

