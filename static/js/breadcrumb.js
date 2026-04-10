let currentPath = "";

function renderBreadcrumb(path, loadFolderCallback) {
    currentPath = path;
    const $breadcrumb = $("#breadcrumb-secundario");
    $breadcrumb.empty();

    const parts = path ? path.split("/") : [];
    let cumulative = "";

    // Carpeta raíz
    $breadcrumb.append(`<li class="breadcrumb-item"><a href="#" data-path=""><i class="bi bi-house text-dark"></i></a></li>`);

    parts.forEach((part, i) => {
        cumulative += (i === 0 ? part : "/" + part);
        if (i === parts.length - 1) {
            $breadcrumb.append(`<li class="breadcrumb-item active">${part}</li>`);
        } else {
            $breadcrumb.append(`<li class="breadcrumb-item"><a href="#" data-path="${cumulative}">${part}</a></li>`);
        }
    });

    // Manejo de clics
    $breadcrumb.find("a").on("click", function (e) {
        e.preventDefault();
        const newPath = $(this).data("path") || "";
        if (typeof loadFolderCallback === "function") {
            loadFolderCallback(newPath);
        }
    });
}

// Exportar la función (si usas módulos, opcional)
// export { renderBreadcrumb };
