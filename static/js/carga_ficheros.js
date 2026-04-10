/************************************************************
 *  SISTEMA DE TAREAS - ESTADO Y REFRESCO
 ************************************************************/

async function refresh() {
    const res = await fetch('/tasks', { noLoader: true });
    const data = await res.json();
    const tbody = document.getElementById('tasksBody');

    // Destruir tooltips existentes antes de limpiar
    destroyAllTooltips(tbody);


    // Vaciar la tabla
    tbody.innerHTML = '';

    // Agregar filas
    for (const [tid, info] of Object.entries(data)) {
        const tr = document.createElement('tr');

        // Clasificación del estado
        const status = info.status.toLowerCase();
        tr.className = status.includes('error')
            ? 'error'
            : status.includes('complet')
            ? 'completed'
            : 'running';

        let actionButtons = "";

        // Botón reintentar (si tiene error)
        if (status.includes("error")) {
            actionButtons += `
                <button class="btn btn-sm btn-warning action-btn me-1"
                    data-bs-toggle="tooltip" data-bs-placement="bottom" title="Reintentar tarea"
                    onclick="retryTask('${tid}')">
                    <i class="bi bi-arrow-repeat"></i>
                </button>
                <a href="/tasks/${tid}/log" target="_blank"
                    class="btn btn-sm btn-info action-btn me-1"
                    data-bs-toggle="tooltip" data-bs-placement="bottom" title="Ver el log de la carga">
                    <i class="bi bi-file-text"></i>
                </a>
                <a href="/tasks/${tid}/bad" target="_blank"
                    class="btn btn-sm btn-info action-btn me-1"
                    style="filter: brightness(0.9);"
                    data-bs-toggle="tooltip" data-bs-placement="bottom" title="Ver datos rechazados durante la carga">
                    <i class="bi bi-eye"></i>
                </a>`;
        }

        // Botón eliminar → abre modal Bootstrap
        actionButtons += `
            <button class="btn btn-sm btn-danger action-btn"
                data-bs-toggle="tooltip" data-bs-placement="bottom" title="Eliminar tarea"
                onclick="openDeleteModal('${tid}')">
                <i class="bi bi-trash"></i>
            </button>
        `;

        const filename = info.filename || "(sin nombre)";
        const detailOutput = (info.detail || '') + (info.output ? (' - ' + info.output) : '');

        tr.innerHTML = `
            <td class="col-md-3 text-center">${tid}</td>
            <td class="col-md-2 text-center">${filename}</td>
            <td class="col-md-2 text-center">${info.status}</td>
            <td class="col-md-3 text-center">${detailOutput}</td>
            <td class="col-md-2 text-center">
                <div class="d-flex justify-content-center gap-2">${actionButtons}</div>
            </td>
        `;

        tbody.appendChild(tr);

    }

    // Inicializar tooltips de los elementos recién agregados
    setTimeout(() => initTooltips(), 50);
}

// Primera carga inmediata al abrir la página.
refresh();

// Refresca la tabla cada 2 segundos.
setInterval(refresh, 2000);

/************************************************************
 *  ELIMINACIÓN CON MODAL BOOTSTRAP (SUSTITUYE AL CONFIRM)
 ************************************************************/

let deleteTaskId = null;

// Abre el modal Bootstrap
function openDeleteModal(id) {
    openGeneralModal({
        title: "Confirmar eliminación",
        body: `¿Seguro que desea eliminar la tarea <strong>${id}</strong> y todos sus archivos asociados?`,
        confirmText: "Eliminar",
        confirmClass: "btn-danger",
        headerClass: "bg-danger",
        onConfirm: () => deleteTask(id)
    });
}

// Botón "Eliminar" dentro del modal
async function deleteTask(deleteTaskId) {
    if (!deleteTaskId) return;

    showAjaxMessage("warning", `Eliminando tarea <strong>${deleteTaskId}</strong>...`);

    const res = await fetch(`/delete/${deleteTaskId}`, { method: "DELETE" });
    const j = await res.json();

    if (res.ok) {
        showAjaxMessage("success", `Tarea eliminada correctamente.`);
        refresh();
    } else {
        showAjaxMessage("danger", `Error eliminando tarea: ${j.error || JSON.stringify(j)}`);
    }

    // Cerrar modal
    const modalEl = document.getElementById('confirmDeleteModal');
    const modal = bootstrap.Modal.getInstance(modalEl);
    if (modal != null) {
        modal.hide();
    }

    deleteTaskId = null;
};

/************************************************************
 *  REINTENTAR TAREA
 ************************************************************/
async function retryTask(id) {

    // TODO - eliminar - if (!confirm('¿Reintentar tarea ' + id + '?')) return;
    showAjaxMessage("primary", `Reintentando tarea <strong>${id}</strong>...`);

    const res = await fetch('/retry/' + id, { method: 'POST' });
    const j = await res.json();

    if (res.ok) {
        showAjaxMessage("success", `Tarea <strong>${id}</strong> relanzada correctamente con ID <strong>${j.new_task_id}</strong>.`);
    } else {
        showAjaxMessage("danger", `No se pudo reintentar: ${j.error || JSON.stringify(j)}`);
    }
}


/************************************************************
 *  CARGA ASÍNCRONA DE ZIPs (Opción B)
 ************************************************************/
$(function () {

    // Lista local de archivos pendientes de subir
    let pendingFiles = [];

    // Elementos
    const dropZone = $('#dropZone');
    const fileInput = $('#fileInput');
    const progressContainer = $('#progressContainer');
    const uploadStatus = $('#uploadStatus');
    const btnStartUpload = $('#btnStartUpload');

    /**************** SELECCIÓN MANUAL ****************/
    fileInput.on('change', function () {
        const newFiles = Array.from(this.files);
        pendingFiles.push(...newFiles);

        /* TODO - borrar - uploadStatus.html(`<p>${pendingFiles.length} archivo(s) listos para subir.</p>`); */
    });

    /**************** DRAG & DROP ****************/
    dropZone.on('dragover', function (e) {
        e.preventDefault();
        dropZone.addClass('dragover');
    });

    dropZone.on('dragleave', function (e) {
        e.preventDefault();
        dropZone.removeClass('dragover');
    });

    dropZone.on('drop', function (e) {
        e.preventDefault();
        dropZone.removeClass('dragover');

        const files = Array.from(e.originalEvent.dataTransfer.files);
        pendingFiles.push(...files);

        uploadStatus.html(`<p>${pendingFiles.length} archivo(s) listos para subir.</p>`);
    });

    /**************** SUBIDA FINAL AL PULSAR BOTÓN ****************/
    btnStartUpload.on('click', async function () {
        if (pendingFiles.length === 0) {
            showAjaxMessage("warning", "No ha seleccionado los ficheros a subir.");
            //TODO - borrar - uploadStatus.html('<p style="color:red;">No hay archivos para subir.</p>');
            return;
        }

        progressContainer.empty();

        const concurrency = 5;
        let results = [];

        for (let i = 0; i < pendingFiles.length; i += concurrency) {
            const chunk = pendingFiles.slice(i, i + concurrency);

            const chunkResults = await Promise.all(
                chunk.map(async file => {
                    try {
                        await uploadFile(file);
                        return { file, status: 'ok' };
                    } catch (err) {
                        // Asegúrate de que 'err' sea un objeto
                        // Si 'uploadFile' no parsea la respuesta JSON, deberías hacerlo aquí.
                        // Asumimos que 'err' es el objeto { "error": "..." }

                        const errorData = err.response && err.response.data ? err.response.data : err;

                        const msg =
                            errorData?.error ||       // Captura "El fichero... no es válido"
                            errorData?.message ||     // Maneja errores estándar
                            errorData?.detail ||      // Por si acaso
                            JSON.parse(errorData).error; // Último recurso

                        const bar = document.getElementById('progressContainer');
                        if (bar) { // Siempre es buena idea comprobar si el elemento existe
                            bar.title = msg;
                        }
                        showAjaxMessage("danger", `Error al subir el fichero ${file.name}: ${msg}`);

                        return { file, status: 'error', error: err };
                    }
                })
            );

            results.push(...chunkResults);
        }

        if (results.some(r => r.status === 'error')) {
            showAjaxMessage("danger", "Algunos archivos fallaron.");
            // TODO - borrar - uploadStatus.append('<p style="color:red;">Algunos archivos fallaron.</p>');
        } else {
            uploadStatus.html('');
            const uno = pendingFiles.length === 1;
            showAjaxMessage(
                "info",
                `Se ha${uno ? "" : "n"} cargado${uno ? "" : "s"} ${pendingFiles.length} fichero${uno ? "" : "s"}.`
            );
            // TODO - borrar - uploadStatus.html('');
        }

        pendingFiles = [];
        fileInput.val('');
        refresh();
    });


    /**************** SUBIDA INDIVIDUAL CON BARRA ****************/
    function uploadFile(file) {
        return new Promise((resolve, reject) => {

            // Crear barra visual
            const id = 'progress_' + Math.random().toString(36).substring(2, 10);

            /** TODO - borrar - const row = $(`
                <div class="mb-2">
                    <div class="fw-semibold small mb-1">${file.name}</div>
                    <div class="progress" style="height: 24px;">
                        <div id="${id}" class="progress-bar progress-bar-striped progress-bar-animated"
                             role="progressbar" style="width: 0%">0%</div>
                    </div>
                </div>
            `); */

            const row = $(`
                <div class="mb-2 progress-row" style="position: relative;">

                    <button class="btn btn-sm btn-light close-progress-btn"
                            onclick="removeProgressRow(this)"
                            style="position:absolute; top:-6px; right:-6px; z-index:10;">
                        ×
                    </button>

                    <div class="fw-semibold small mb-1">${file.name}</div>

                    <div class="progress" style="height: 24px;">
                        <div id="${id}" class="progress-bar progress-bar-striped progress-bar-animated"
                             role="progressbar" style="width: 0%">0%</div>
                    </div>
                </div>
            `);


            progressContainer.append(row);

            const formData = new FormData();
            formData.append("file", file);

            $.ajax({
                xhr: function () {
                    const xhr = new window.XMLHttpRequest();
                    xhr.upload.addEventListener("progress", function (e) {
                        if (e.lengthComputable) {
                            const pct = Math.round((e.loaded / e.total) * 100);
                            $("#" + id).css("width", pct + "%").text(pct + "%");
                        }
                    });
                    return xhr;
                },
                url: "/upload",
                method: "POST",
                data: formData,
                processData: false,
                contentType: false,

                success: function (resp) {
                    if (resp.error) {
                        $("#" + id).addClass("bg-danger").text("❌ Error");
                        return reject(resp.error);
                    }

                    $("#" + id)
                        .removeClass("progress-bar-animated")
                        .addClass("bg-success")
                        .text("✔ Subido");

                    setTimeout(() => row.fadeOut(150, () => row.remove()), 300);
                    resolve();
                },

                error: function (xhr) {
                    $("#" + id)
                        .removeClass("progress-bar-animated")
                        .addClass("bg-danger")
                        .text("❌ Error");

                    reject(xhr.responseText || "Error en subida");
                }
            });

        });
    }

    document.getElementById("btnDeleteAll").addEventListener("click", async () => {

        // Obtener número de tareas ANTES de abrir el modal
        let total = 0;
        try {
            const res = await fetch("/tasks");
            const tasks = await res.json();
            total = Object.keys(tasks).length;
        } catch (e) {
            total = 0;
        }

        if(total == 0) {
            showAjaxMessage("warning", "No hay tareas que cancelar.");
            return;
        }

        openGeneralModal({
            title: "Cancelación de todas las tareas",
            body: `¿Seguro que desea solicitar la cancelación de <strong>todas</strong> las tareas (${total} en total) y sus archivos asociados?`,
            confirmText: "Eliminar",
            confirmClass: "btn-danger",
            headerClass: "bg-danger",
            onConfirm: async () => {

                showAjaxMessage("success", `Se solicitado la cancelación de ${total} tareas.`);

                try {

                    await fetch("/delete_all", { method: "DELETE" })
                        .then(r => r.json())
                        .then(data => {
                            showAjaxMessage("info", data.message);
                    });

                } catch (e) {
                    showAjaxMessage("danger", "Error solicitando la cancelación de ${total} tareas.");
                }

                refresh();
            }
        });

    });

    document.getElementById("btnDataDelete").addEventListener("click", async () => {

        openGeneralModal({
            title: "Borrado de datos",
            body: `¿Seguro que desea eliminar <strong>todos</strong> los datos cargados?`,
            confirmText: "Borrar",
            confirmClass: "btn-danger",
            headerClass: "bg-danger",
            onConfirm: async () => {

                showAjaxMessage("success", `Se ha solicitado el borrado de datos.`);

                try {

                    await fetch("/delete_data", { method: "DELETE" })
                        .then(r => r.json())
                        .then(data => {
                            showAjaxMessage("info", data.message);
                    });

                } catch (e) {
                    showAjaxMessage("danger", "Error solicitando el borrado de datos.");
                }

                refresh();
            }
        });

    });



});
/************************************************************/

/************************************************************
 *  CIERRE MANUAL DE BARRAS DE PROGRESO
 ************************************************************/
function removeProgressRow(btn) {
    const row = $(btn).closest(".progress-row");
    row.fadeOut(150, () => row.remove());
}

/************************************************************
 *  Función para abrir el modal mostrando links a log y bad
 ************************************************************/
window.openTaskFilesModal = function ({ taskId, logUrl, badUrl }) {
    const bodyHtml = `
        <p>Archivos de la tarea <strong>${taskId}</strong>:</p>
        <div class="d-flex gap-2">
            <a href="${logUrl}" target="_blank" class="btn btn-outline-primary">Ver Log</a>
            <a href="${badUrl}" target="_blank" class="btn btn-outline-danger">Ver Bad</a>
        </div>
    `;

    // Reutilizamos el modal general
    openGeneralModal({
        title: `Archivos de la tarea ${taskId}`,
        body: bodyHtml,
        confirmText: "Cerrar",
        confirmClass: "btn-secondary",
        headerClass: "bg-info",
        onConfirm: null  // solo cierra el modal
    });
};