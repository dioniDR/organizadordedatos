#!/bin/bash

# Cargar utilidades
source "$(dirname "$0")/utils.sh"

# Configuración
ENTRADA="${INPUT_DIR:-/app/entrada}"
SALIDA="${OUTPUT_DIR:-/app/salida}"
MAX_JOBS="${MAX_PARALLEL_JOBS:-4}"

# Inicializar
init_logging
check_command pdftotext
check_command pdftoppm
check_command tesseract
check_dir "$ENTRADA"
ensure_dir "$SALIDA"

log_info "Iniciando procesamiento de PDFs desde $ENTRADA"

# Encontrar todos los PDFs
mapfile -t pdfs < <(find "$ENTRADA" -type f -name "*.pdf")
total_pdfs=${#pdfs[@]}

if [[ $total_pdfs -eq 0 ]]; then
    log_warn "No se encontraron archivos PDF en $ENTRADA"
    exit 0
fi

log_info "Encontrados $total_pdfs archivos PDF para procesar"

# Función para procesar un PDF
process_pdf() {
    local archivo="$1"
    local current="$2"
    local total="$3"
    
    local nombre=$(basename "$archivo" .pdf)
    local txt_output="$SALIDA/${nombre}.txt"
    local ocr_output="$SALIDA/${nombre}_ocr.txt"
    
    show_progress "$current" "$total" "$(basename "$archivo")"
    
    # Verificar espacio en disco (estimado 10MB por archivo)
    check_disk_space "$SALIDA" 10
    
    # Intentar extracción de texto directo
    if pdftotext "$archivo" "$txt_output" 2>/dev/null; then
        # Verificar si el archivo tiene contenido útil
        if [[ -s "$txt_output" ]] && [[ $(wc -w < "$txt_output") -gt 10 ]]; then
            log_debug "Texto extraído directamente de: $(basename "$archivo")"
            return 0
        fi
    fi
    
    # Si no hay texto o es muy poco, usar OCR
    log_debug "Aplicando OCR a: $(basename "$archivo")"
    local tmp_dir="$SALIDA/tmp_${nombre}_$$"
    ensure_dir "$tmp_dir"
    
    # Convertir PDF a imágenes
    if ! pdftoppm "$archivo" "$tmp_dir/page" -png -r 300 2>/dev/null; then
        log_error "Error convirtiendo PDF a imágenes: $(basename "$archivo")"
        rm -rf "$tmp_dir"
        return 1
    fi
    
    # Aplicar OCR a cada página
    local ocr_files=()
    for img in "$tmp_dir"/page-*.png; do
        if [[ -f "$img" ]]; then
            local ocr_file="${img%.png}.txt"
            if tesseract "$img" "${img%.png}" -l spa --psm 3 2>/dev/null; then
                ocr_files+=("$ocr_file")
            fi
        fi
    done
    
    # Consolidar texto OCR
    if [[ ${#ocr_files[@]} -gt 0 ]]; then
        cat "${ocr_files[@]}" > "$ocr_output" 2>/dev/null
        log_debug "OCR completado para: $(basename "$archivo")"
    else
        log_warn "No se pudo extraer texto de: $(basename "$archivo")"
    fi
    
    # Limpiar archivos temporales
    rm -rf "$tmp_dir"
}

# Procesar PDFs con control de paralelismo
current=0
for archivo in "${pdfs[@]}"; do
    ((current++))
    
    # Controlar número de trabajos en paralelo
    while [[ $(jobs -r | wc -l) -ge $MAX_JOBS ]]; do
        sleep 0.1
    done
    
    process_pdf "$archivo" "$current" "$total_pdfs" &
done

# Esperar a que terminen todos los trabajos
wait

clear_progress
log_info "Procesamiento de PDFs completado. Archivos procesados: $total_pdfs"

# Estadísticas finales
txt_count=$(find "$SALIDA" -name "*.txt" -type f | wc -l)
log_info "Archivos de texto generados: $txt_count"
