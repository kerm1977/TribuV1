// Gestión de Accesos Directos - La Tribu

class AccessManager {
    constructor() {
        this.accesos = this.cargarAccesos();
        this.accesoAEliminar = null;
        this.init();
    }

    init() {
        this.setupForm();
        this.renderAccesos();
        this.setupModal();
    }

    setupModal() {
        // Hacer la función disponible globalmente
        window.accessManager = this;
    }

    abrirModalCrear() {
        const modal = document.getElementById('modalNuevoAccesoSimple');
        if (modal) {
            // Mostrar modal manualmente
            modal.style.display = 'block';
            modal.classList.add('show');
            document.body.classList.add('modal-open');
            
            // Agregar backdrop
            let backdrop = document.querySelector('.modal-backdrop');
            if (!backdrop) {
                backdrop = document.createElement('div');
                backdrop.className = 'modal-backdrop fade show';
                document.body.appendChild(backdrop);
            }
            
            // Configurar cierre del modal
            this.setupModalClose();
        }
    }

    setupModalClose() {
        const modal = document.getElementById('modalNuevoAccesoSimple');
        
        // Cerrar con botón X
        const closeBtn = modal.querySelector('.btn-close');
        if (closeBtn) {
            closeBtn.onclick = () => this.cerrarModalManual();
        }
        
        // Cerrar haciendo clic fuera
        modal.onclick = (e) => {
            if (e.target === modal) {
                this.cerrarModalManual();
            }
        };
        
        // Cerrar con tecla ESC
        document.onkeydown = (e) => {
            if (e.key === 'Escape') {
                this.cerrarModalManual();
            }
        };
    }

    cerrarModalManual() {
        const modal = document.getElementById('modalNuevoAccesoSimple');
        if (modal) {
            modal.style.display = 'none';
            modal.classList.remove('show');
            document.body.classList.remove('modal-open');
            
            // Remover backdrop
            const backdrop = document.querySelector('.modal-backdrop');
            if (backdrop) {
                backdrop.remove();
            }
            
            // Limpiar eventos
            document.onkeydown = null;
        }
    }

    setupForm() {
        const form = document.getElementById('form-acceso-simple');
        if (form) {
            form.addEventListener('submit', (e) => {
                e.preventDefault();
                this.guardarAcceso();
            });
        }
    }

    cargarAccesos() {
        const guardados = localStorage.getItem('accesos_directos');
        return guardados ? JSON.parse(guardados) : [];
    }

    guardarAccesos() {
        localStorage.setItem('accesos_directos', JSON.stringify(this.accesos));
    }

    guardarAcceso() {
        const nombre = document.getElementById('acc-nombre-simple').value.trim();
        const icono = document.getElementById('acc-icono-simple').value;
        const url = document.getElementById('acc-url-simple').value.trim();
        const fileInput = document.getElementById('acc-file-simple');

        if (!nombre) {
            return;
        }

        // Si hay archivo, procesarlo primero
        if (fileInput.files.length > 0) {
            this.procesarArchivoYGuardar(nombre, icono, fileInput.files[0]);
        } else if (url) {
            // Si no hay archivo pero hay URL, guardar normalmente
            this.crearAccesoDirecto(nombre, icono, url);
        }
    }

    async procesarArchivoYGuardar(nombre, icono, file) {
        try {
            const fileName = this.generarNombreArchivo(file.name);
            const fileContent = await this.leerArchivoComoTexto(file);
            
            // Guardar archivo en localStorage
            this.guardarArchivoLocal(fileName, fileContent);
            
            // Crear acceso directo con el archivo local
            this.crearAccesoDirecto(nombre, icono, fileName);
            
        } catch (error) {
            console.error('Error procesando archivo:', error);
        }
    }

    leerArchivoComoTexto(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = (e) => resolve(e.target.result);
            reader.onerror = reject;
            reader.readAsText(file);
        });
    }

    generarNombreArchivo(originalName) {
        // Generar nombre único para evitar conflictos
        const timestamp = Date.now();
        const baseName = originalName.replace('.html', '');
        return `${baseName}_${timestamp}.html`;
    }

    guardarArchivoLocal(fileName, content) {
        // Guardar en localStorage con prefijo
        const storageKey = `html_file_${fileName}`;
        localStorage.setItem(storageKey, content);
        
        // También guardar registro de archivos
        const archivos = JSON.parse(localStorage.getItem('archivos_locales') || '[]');
        if (!archivos.includes(fileName)) {
            archivos.push(fileName);
            localStorage.setItem('archivos_locales', JSON.stringify(archivos));
        }
    }

    crearAccesoDirecto(nombre, icono, url) {
        const nuevoAcceso = {
            id: Date.now(),
            nombre: nombre,
            icono: icono,
            url: url,
            creado: new Date().toISOString(),
            esLocal: url.startsWith('http') ? false : true
        };

        this.accesos.push(nuevoAcceso);
        this.guardarAccesos();
        this.renderAccesos();
        this.cerrarModal();
        this.limpiarFormulario();
    }

    eliminarAcceso(id) {
        // Buscar el acceso a eliminar
        const acceso = this.accesos.find(a => a.id === id);
        if (!acceso) return;

        // Guardar referencia y mostrar modal
        this.accesoAEliminar = id;
        this.mostrarModalEliminar(acceso.nombre);
    }

    mostrarModalEliminar(nombreAcceso) {
        // Actualizar contenido del modal
        document.getElementById('eliminar-titulo').textContent = '¿Eliminar Acceso Directo?';
        document.getElementById('eliminar-mensaje').textContent = 
            `¿Estás seguro de que quieres eliminar "${nombreAcceso}"? Esta acción no se puede deshacer.`;

        // Mostrar modal manualmente
        const modal = document.getElementById('modalConfirmarEliminar');
        if (modal) {
            // Forzar display block
            modal.style.display = 'block';
            modal.classList.add('show');
            document.body.classList.add('modal-open');
            
            // Agregar backdrop
            let backdrop = document.querySelector('.modal-backdrop');
            if (!backdrop) {
                backdrop = document.createElement('div');
                backdrop.className = 'modal-backdrop fade show';
                backdrop.style.cssText = 'position: fixed; top: 0; left: 0; z-index: 1040; width: 100vw; height: 100vh; background-color: rgba(0,0,0,0.5);';
                document.body.appendChild(backdrop);
            }
            
            // Forzar animación de entrada
            setTimeout(() => {
                const dialog = modal.querySelector('.modal-dialog');
                if (dialog) {
                    dialog.style.transform = 'scale(1)';
                    dialog.style.opacity = '1';
                }
            }, 10);
            
            // Configurar cierre del modal
            this.setupModalEliminarClose();
        }
    }

    setupModalEliminarClose() {
        const modal = document.getElementById('modalConfirmarEliminar');
        
        // Cerrar con botón Cancelar
        const cancelBtn = modal.querySelector('.btn-secondary');
        if (cancelBtn) {
            cancelBtn.onclick = () => this.cancelarEliminar();
        }
        
        // Cerrar haciendo clic fuera
        modal.onclick = (e) => {
            if (e.target === modal) {
                this.cancelarEliminar();
            }
        };
        
        // Cerrar con tecla ESC
        const escHandler = (e) => {
            if (e.key === 'Escape') {
                this.cancelarEliminar();
                document.removeEventListener('keydown', escHandler);
            }
        };
        document.addEventListener('keydown', escHandler);
    }

    confirmarEliminar() {
        if (this.accesoAEliminar !== null) {
            // Eliminar el acceso
            this.accesos = this.accesos.filter(acceso => acceso.id !== this.accesoAEliminar);
            this.guardarAccesos();
            this.renderAccesos();
            
            // Limpiar y cerrar modal
            this.accesoAEliminar = null;
            this.cerrarModalEliminar();
        }
    }

    cancelarEliminar() {
        this.accesoAEliminar = null;
        this.cerrarModalEliminar();
    }

    cerrarModalEliminar() {
        const modal = document.getElementById('modalConfirmarEliminar');
        if (modal) {
            // Animación de salida
            const dialog = modal.querySelector('.modal-dialog');
            if (dialog) {
                dialog.style.transform = 'scale(0.9)';
                dialog.style.opacity = '0';
            }
            
            setTimeout(() => {
                modal.style.display = 'none';
                modal.classList.remove('show');
                document.body.classList.remove('modal-open');
                
                // Remover backdrop
                const backdrop = document.querySelector('.modal-backdrop');
                if (backdrop) {
                    backdrop.remove();
                }
            }, 300);
        }
    }

    renderAccesos() {
        const container = document.querySelector('.container.py-5');
        if (!container) return;

        // Buscar la sección de accesos rápidos existente
        const rapidosSection = container.querySelector('h2.text-center');
        
        if (!rapidosSection) return;

        // Buscar o crear la sección de accesos personalizados
        let accesosSection = container.querySelector('.accesos-personalizados');
        
        if (!accesosSection) {
            // Crear la sección después de los accesos rápidos
            accesosSection = document.createElement('div');
            accesosSection.className = 'accesos-personalizados mt-2';
            
            // Insertar después de la sección de accesos rápidos
            const rapidosRow = container.querySelector('.row.g-3');
            if (rapidosRow && rapidosRow.parentNode) {
                rapidosRow.parentNode.insertBefore(accesosSection, rapidosRow.nextSibling);
            } else {
                container.appendChild(accesosSection);
            }
        }

        if (this.accesos.length === 0) {
            accesosSection.innerHTML = '';
            return;
        }

        let html = `
            <h3 class="text-center fw-bold mb-2">Mis Accesos Directos</h3>
            <div class="row g-3 justify-content-center">
        `;

        this.accesos.forEach(acceso => {
            html += `
                <div class="col-6 col-md-3">
                    <div class="quick-access-card text-center p-4 rounded-3 bg-white shadow-sm hover-lift cursor-pointer position-relative" 
                         onclick="accessManager.abrirAcceso('${this.escapeHtml(acceso.url)}')">
                        <button class="btn btn-sm btn-danger position-absolute top-0 end-0 m-1 rounded-circle" 
                                onclick="event.stopPropagation(); accessManager.eliminarAcceso(${acceso.id})"
                                style="width: 25px; height: 25px; padding: 0;">
                            <i class="bi bi-x" style="font-size: 0.8rem;"></i>
                        </button>
                        <i class="bi ${this.escapeHtml(acceso.icono)} text-primary fs-3 mb-2"></i>
                        <p class="small fw-bold mb-0">${this.escapeHtml(acceso.nombre)}</p>
                    </div>
                </div>
            `;
        });

        html += '</div>';
        accesosSection.innerHTML = html;
    }

    abrirAcceso(url) {
        if (url.startsWith('http://') || url.startsWith('https://')) {
            // Enlace web - abrir en nueva ventana
            window.open(url, '_blank');
        } else {
            // Verificar si es un archivo local guardado
            const storageKey = `html_file_${url}`;
            const fileContent = localStorage.getItem(storageKey);
            
            if (fileContent) {
                // Abrir archivo local desde localStorage con botón volver
                this.abrirArchivoLocal(url, fileContent);
            } else {
                // Enlace local tradicional - navegar en la misma ventana
                window.location.href = url;
            }
        }
    }

    abrirArchivoLocal(fileName, content) {
        // Crear una nueva página con el contenido del archivo y botón volver
        const newWindow = window.open('', '_blank');
        
        if (newWindow) {
            newWindow.document.write(`
                <!DOCTYPE html>
                <html lang="es">
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <title>${fileName.replace('.html', '').replace(/_\d+$/, '')}</title>
                    <style>
                        body {
                            margin: 0;
                            padding: 0;
                            font-family: system-ui, -apple-system, sans-serif;
                        }
                        .back-btn {
                            position: fixed;
                            top: 20px;
                            left: 20px;
                            z-index: 9999;
                            background: rgba(255,255,255,0.9);
                            border: none;
                            border-radius: 50%;
                            width: 50px;
                            height: 50px;
                            display: flex;
                            align-items: center;
                            justify-content: center;
                            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
                            cursor: pointer;
                            transition: all 0.3s ease;
                        }
                        .back-btn:hover {
                            background: white;
                            transform: scale(1.1);
                        }
                        .back-btn i {
                            font-size: 1.2rem;
                            color: #333;
                        }
                    </style>
                    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
                </head>
                <body>
                    <button class="back-btn" onclick="window.close()" title="Cerrar ventana">
                        <i class="bi bi-arrow-left"></i>
                    </button>
                    ${content}
                </body>
                </html>
            `);
            newWindow.document.close();
        } else {
            // Fallback: mostrar en la misma página con botón volver
            const volverBtn = document.createElement('button');
            volverBtn.innerHTML = '<i class="bi bi-arrow-left me-2"></i>Volver';
            volverBtn.className = 'btn btn-primary position-fixed top-0 start-0 m-3';
            volverBtn.style.zIndex = '9999';
            volverBtn.onclick = () => window.history.back();
            
            document.body.innerHTML = content;
            document.body.insertBefore(volverBtn, document.body.firstChild);
            document.title = fileName.replace('.html', '').replace(/_\d+$/, '');
        }
    }

    cerrarModal() {
        this.cerrarModalManual();
    }

    limpiarFormulario() {
        document.getElementById('form-acceso-simple').reset();
    }

    // Método para limpiar archivos locales (opcional)
    limpiarArchivosLocales() {
        if (confirm('¿Estás seguro de que quieres eliminar todos los archivos HTML locales?')) {
            const archivos = JSON.parse(localStorage.getItem('archivos_locales') || '[]');
            archivos.forEach(fileName => {
                localStorage.removeItem(`html_file_${fileName}`);
            });
            localStorage.removeItem('archivos_locales');
        }
    }

    escapeHtml(text) {
        const map = {
            '&': '&amp;',
            '<': '&lt;',
            '>': '&gt;',
            '"': '&quot;',
            "'": '&#039;'
        };
        return text.replace(/[&<>"']/g, m => map[m]);
    }
}

// Inicializar el gestor de accesos
let accessManager;
document.addEventListener('DOMContentLoaded', () => {
    accessManager = new AccessManager();
    window.accessManager = accessManager;
});
