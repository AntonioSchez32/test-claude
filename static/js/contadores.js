$(function() {
      // Cierra automáticamente las alertas después de 5 segundos (5.000 ms)
      setTimeout(() => {
        $('.alert').each(function() {
            const bsAlert = bootstrap.Alert.getOrCreateInstance(this);
            bsAlert.close();
          });
        }, 5000);

        // Formatea los valores numéricos en la tabla
        $('td[data-value]').each(function() {
            const value = $(this).attr('data-value');
            if ($(this).is(':first-child') && value < 999) {
                // Primera columna: completar con ceros a la izquierda
                /*
                if (!isNaN(value) && value.trim() !== '') {
                    const paddedValue = String(value).padStart(3, '0');
                    $(this).text(paddedValue);
                }
                */
            } else {
                // Otras columnas: formato con separadores de miles
                if (!isNaN(value) && value.trim() !== '') {

                    const formatted = new Intl.NumberFormat('es-ES', {
                        minimumFractionDigits: 0,
                        useGrouping: true
                    }).format(Number(value));

                    //const formatted = Number(value).toLocaleString('es-ES', { minimumFractionDigits: 0 });

                    $(this).text(formatted);
                }
            }
        });

});