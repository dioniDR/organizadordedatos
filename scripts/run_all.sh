#!/bin/bash

# Cargar utilidades
source "$(dirname "$0")/utils.sh"

# Inicializar logging
init_logging

log_info "=== INICIANDO PROCESAMIENTO COMPLETO DE DOCUMENTOS ==="

# Lista de scripts a ejecutar en orden
SCRIPTS=(
    "procesar_pdfs.sh"
    "convertir_docx_xlsx.sh" 
    "extraer_xml.sh"
    "limpiar_repetidos.sh"
    "organizar_por_anio.sh"
    "consolidar_textos.sh"
)

SCRIPT_DIR="$(dirname "$0")"
total_scripts=${#SCRIPTS[@]}
current_script=0
failed_scripts=()

# Ejecutar cada script
for script in "${SCRIPTS[@]}"; do
    ((current_script++))
    script_path="$SCRIPT_DIR/$script"
    
    log_info "[$current_script/$total_scripts] Ejecutando: $script"
    
    if [[ ! -f "$script_path" ]]; then
        log_error "Script no encontrado: $script_path"
        failed_scripts+=("$script")
        continue
    fi
    
    if [[ ! -x "$script_path" ]]; then
        chmod +x "$script_path"
        log_debug "Permisos de ejecución añadidos a: $script"
    fi
    
    # Ejecutar script con timeout
    start_time=$(date +%s)
    
    if timeout 3600 bash "$script_path"; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        log_info "✓ $script completado en ${duration}s"
    else
        exit_code=$?
        log_error "✗ $script falló con código de salida: $exit_code"
        failed_scripts+=("$script")
        
        # Decidir si continuar o parar
        if [[ $exit_code -eq 124 ]]; then
            log_error "Script $script excedió el timeout de 1 hora"
        fi
        
        # Para scripts críticos, parar la ejecución
        case $script in
            "procesar_pdfs.sh"|"convertir_docx_xlsx.sh")
                log_error "Script crítico falló. Abortando procesamiento."
                exit $exit_code
                ;;
        esac
    fi
    
    log_info "Progreso general: $current_script/$total_scripts scripts ejecutados"
done

# Resumen final
log_info "=== PROCESAMIENTO COMPLETADO ==="

if [[ ${#failed_scripts[@]} -eq 0 ]]; then
    log_info "✓ Todos los scripts se ejecutaron correctamente"
    
    # Estadísticas finales
    if [[ -d "$OUTPUT_DIR" ]]; then
        total_files=$(find "$OUTPUT_DIR" -type f | wc -l)
        total_size=$(du -sh "$OUTPUT_DIR" 2>/dev/null | cut -f1)
        log_info "Archivos generados: $total_files"
        log_info "Tamaño total de salida: $total_size"
    fi
    
    exit 0
else
    log_error "✗ Scripts que fallaron: ${failed_scripts[*]}"
    log_error "Revisar logs para más detalles"
    exit 1
fi
