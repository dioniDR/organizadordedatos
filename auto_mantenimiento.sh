#!/bin/bash

# Script de mantenimiento completamente automatizado
# Ejecuta todos los pasos sin intervención del usuario

# Cargar utilidades
source "$(dirname "$0")/scripts/utils.sh"

# Configuración
SCRIPT_DIR="$(dirname "$0")"
AUTOMATION_MODE="FULL"
FORCE_EXECUTION=false
SKIP_BACKUPS=false
NOTIFICATION_EMAIL=""

# Pasos del mantenimiento automatizado
AUTOMATED_STEPS=(
    "validate_environment"
    "create_backups"
    "cleanup_old_files"
    "process_documents"
    "organize_results"
    "verify_integrity"
    "generate_reports"
    "cleanup_temp_files"
)

# Descripción de cada paso
declare -A AUTO_STEP_DESC
AUTO_STEP_DESC["validate_environment"]="Validación del entorno y dependencias"
AUTO_STEP_DESC["create_backups"]="Creación de respaldos de seguridad"
AUTO_STEP_DESC["cleanup_old_files"]="Limpieza de archivos antiguos"
AUTO_STEP_DESC["process_documents"]="Procesamiento completo de documentos"
AUTO_STEP_DESC["organize_results"]="Organización y estructuración de resultados"
AUTO_STEP_DESC["verify_integrity"]="Verificación de integridad"
AUTO_STEP_DESC["generate_reports"]="Generación de reportes finales"
AUTO_STEP_DESC["cleanup_temp_files"]="Limpieza final de archivos temporales"

# Función para mostrar progreso general
show_automation_progress() {
    local current_step=$1
    local total_steps=$2
    local step_name="$3"
    local start_time="$4"
    
    local percent=$((current_step * 100 / total_steps))
    local elapsed=$(($(date +%s) - start_time))
    local eta=$((elapsed * total_steps / current_step - elapsed))
    
    clear
    echo -e "\n${GREEN}🤖 MANTENIMIENTO AUTOMATIZADO EN PROGRESO${NC}"
    echo "═══════════════════════════════════════════════════════════════════"
    echo -e "📊 Progreso general: ${BLUE}$current_step/$total_steps${NC} (${percent}%)"
    echo -e "⏱️  Tiempo transcurrido: ${elapsed}s"
    echo -e "⏳ Tiempo estimado restante: ${eta}s"
    echo -e "🔄 Paso actual: ${YELLOW}$step_name${NC}"
    echo "═══════════════════════════════════════════════════════════════════"
    
    # Barra de progreso visual
    local bar_length=50
    local filled_length=$((percent * bar_length / 100))
    printf "\n["
    for ((i=1; i<=filled_length; i++)); do printf "█"; done
    for ((i=filled_length+1; i<=bar_length; i++)); do printf "░"; done
    printf "] %d%%\n\n" "$percent"
}

# Función para validar el entorno
validate_environment() {
    log_info "🔍 Iniciando validación del entorno..."
    
    # Ejecutar script de setup para validación
    if bash "$SCRIPT_DIR/scripts/setup.sh" --validate; then
        log_info "✅ Entorno validado correctamente"
        return 0
    else
        log_error "❌ Error en la validación del entorno"
        return 1
    fi
}

# Función para crear respaldos
create_backups() {
    log_info "💾 Creando respaldos de seguridad..."
    
    if [[ "$SKIP_BACKUPS" == "true" ]]; then
        log_warn "⏭️  Saltando creación de respaldos (modo --skip-backups)"
        return 0
    fi
    
    local backup_dir="$OUTPUT_DIR/backups/$(date '+%Y%m%d_%H%M%S')"
    ensure_dir "$backup_dir"
    
    # Respaldar base de datos
    if [[ -f "$DB_DIR/documentos.db" ]]; then
        cp "$DB_DIR/documentos.db" "$backup_dir/documentos_backup.db"
        log_info "✅ Base de datos respaldada"
    fi
    
    # Respaldar archivos de configuración
    if [[ -f "$DB_DIR/config.conf" ]]; then
        cp "$DB_DIR/config.conf" "$backup_dir/config_backup.conf"
        log_info "✅ Configuración respaldada"
    fi
    
    # Respaldar logs importantes
    if [[ -d "$LOG_DIR" ]]; then
        tar -czf "$backup_dir/logs_backup.tar.gz" -C "$LOG_DIR" . 2>/dev/null
        log_info "✅ Logs respaldados"
    fi
    
    log_info "✅ Respaldos creados en: $backup_dir"
    return 0
}

# Función para limpiar archivos antiguos
cleanup_old_files() {
    log_info "🧹 Limpiando archivos antiguos..."
    
    local cleaned_count=0
    
    # Limpiar logs antiguos (más de 7 días)
    if [[ -d "$LOG_DIR" ]]; then
        local old_logs=$(find "$LOG_DIR" -name "*.log" -type f -mtime +7 2>/dev/null | wc -l)
        find "$LOG_DIR" -name "*.log" -type f -mtime +7 -delete 2>/dev/null
        cleaned_count=$((cleaned_count + old_logs))
        log_info "🗑️  Eliminados $old_logs logs antiguos"
    fi
    
    # Limpiar archivos temporales
    if [[ -d "$OUTPUT_DIR/temp" ]]; then
        local temp_files=$(find "$OUTPUT_DIR/temp" -type f 2>/dev/null | wc -l)
        rm -rf "$OUTPUT_DIR/temp"/* 2>/dev/null
        cleaned_count=$((cleaned_count + temp_files))
        log_info "🗑️  Eliminados $temp_files archivos temporales"
    fi
    
    # Limpiar respaldos antiguos (más de 30 días)
    if [[ -d "$OUTPUT_DIR/backups" ]]; then
        local old_backups=$(find "$OUTPUT_DIR/backups" -type d -mtime +30 2>/dev/null | wc -l)
        find "$OUTPUT_DIR/backups" -type d -mtime +30 -exec rm -rf {} + 2>/dev/null
        cleaned_count=$((cleaned_count + old_backups))
        log_info "🗑️  Eliminados $old_backups respaldos antiguos"
    fi
    
    log_info "✅ Limpieza completada. $cleaned_count elementos eliminados"
    return 0
}

# Función para procesar documentos
process_documents() {
    log_info "📄 Iniciando procesamiento completo de documentos..."
    
    local processing_steps=(
        "scripts/procesar_pdfs.sh"
        "scripts/convertir_docx_xlsx.sh"
        "scripts/extraer_xml.sh"
        "scripts/limpiar_repetidos.sh"
    )
    
    local step_count=0
    local total_processing_steps=${#processing_steps[@]}
    
    for script in "${processing_steps[@]}"; do
        ((step_count++))
        local script_name=$(basename "$script" .sh)
        
        log_info "[$step_count/$total_processing_steps] Ejecutando: $script_name"
        
        if [[ -f "$SCRIPT_DIR/$script" ]]; then
            if timeout 3600 bash "$SCRIPT_DIR/$script"; then
                log_info "✅ $script_name completado"
            else
                local exit_code=$?
                if [[ $exit_code -eq 124 ]]; then
                    log_error "⏰ $script_name excedió timeout de 1 hora"
                else
                    log_error "❌ $script_name falló con código: $exit_code"
                fi
                
                if [[ "$FORCE_EXECUTION" != "true" ]]; then
                    return $exit_code
                fi
            fi
        else
            log_warn "⚠️  Script no encontrado: $script"
        fi
    done
    
    log_info "✅ Procesamiento de documentos completado"
    return 0
}

# Función para organizar resultados
organize_results() {
    log_info "📁 Organizando resultados..."
    
    # Ejecutar organización por año
    if [[ -f "$SCRIPT_DIR/scripts/organizar_por_anio.sh" ]]; then
        if bash "$SCRIPT_DIR/scripts/organizar_por_anio.sh"; then
            log_info "✅ Organización por año completada"
        else
            log_error "❌ Error en organización por año"
            return 1
        fi
    fi
    
    # Ejecutar consolidación de textos
    if [[ -f "$SCRIPT_DIR/scripts/consolidar_textos.sh" ]]; then
        if bash "$SCRIPT_DIR/scripts/consolidar_textos.sh"; then
            log_info "✅ Consolidación de textos completada"
        else
            log_error "❌ Error en consolidación de textos"
            return 1
        fi
    fi
    
    log_info "✅ Organización de resultados completada"
    return 0
}

# Función para verificar integridad
verify_integrity() {
    log_info "🔍 Verificando integridad de datos..."
    
    local verification_errors=0
    
    # Verificar que existen archivos de salida
    if [[ ! -d "$OUTPUT_DIR" ]] || [[ -z "$(ls -A "$OUTPUT_DIR" 2>/dev/null)" ]]; then
        log_error "❌ Directorio de salida vacío"
        ((verification_errors++))
    else
        local output_files=$(find "$OUTPUT_DIR" -type f | wc -l)
        log_info "📊 Archivos en salida: $output_files"
    fi
    
    # Verificar base de datos
    if [[ -f "$DB_DIR/documentos.db" ]]; then
        local db_records=$(sqlite3 "$DB_DIR/documentos.db" "SELECT COUNT(*) FROM archivos;" 2>/dev/null || echo "0")
        log_info "📊 Registros en BD: $db_records"
    else
        log_warn "⚠️  Base de datos no encontrada"
    fi
    
    # Verificar logs
    if [[ -d "$LOG_DIR" ]]; then
        local log_files=$(find "$LOG_DIR" -name "*.log" -type f | wc -l)
        log_info "📊 Archivos de log: $log_files"
    fi
    
    if [[ $verification_errors -eq 0 ]]; then
        log_info "✅ Verificación de integridad completada sin errores"
        return 0
    else
        log_error "❌ Verificación de integridad encontró $verification_errors errores"
        return 1
    fi
}

# Función para generar reportes
generate_reports() {
    log_info "📊 Generando reportes finales..."
    
    local report_dir="$OUTPUT_DIR/reportes"
    ensure_dir "$report_dir"
    
    local report_file="$report_dir/reporte_$(date '+%Y%m%d_%H%M%S').txt"
    
    cat > "$report_file" << EOF
═══════════════════════════════════════════════════════════════════
🤖 REPORTE DE MANTENIMIENTO AUTOMATIZADO
═══════════════════════════════════════════════════════════════════

📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')
🖥️  Sistema: $(uname -a)
⚙️  Usuario: $(whoami)

📁 ESTADÍSTICAS DE ARCHIVOS:
───────────────────────────────────────────────────────────────────
EOF
    
    # Estadísticas de entrada
    if [[ -d "$INPUT_DIR" ]]; then
        local input_files=$(find "$INPUT_DIR" -type f 2>/dev/null | wc -l)
        local input_size=$(du -sh "$INPUT_DIR" 2>/dev/null | cut -f1)
        echo "📥 Archivos de entrada: $input_files" >> "$report_file"
        echo "📥 Tamaño de entrada: $input_size" >> "$report_file"
    fi
    
    # Estadísticas de salida
    if [[ -d "$OUTPUT_DIR" ]]; then
        local output_files=$(find "$OUTPUT_DIR" -type f 2>/dev/null | wc -l)
        local output_size=$(du -sh "$OUTPUT_DIR" 2>/dev/null | cut -f1)
        echo "📤 Archivos de salida: $output_files" >> "$report_file"
        echo "📤 Tamaño de salida: $output_size" >> "$report_file"
    fi
    
    # Estadísticas por tipo de archivo
    echo "" >> "$report_file"
    echo "📊 ARCHIVOS POR TIPO:" >> "$report_file"
    echo "───────────────────────────────────────────────────────────────────" >> "$report_file"
    
    if [[ -d "$OUTPUT_DIR" ]]; then
        find "$OUTPUT_DIR" -type f -name "*.txt" 2>/dev/null | wc -l | xargs echo "📄 Archivos TXT:" >> "$report_file"
        find "$OUTPUT_DIR" -type f -name "*.pdf" 2>/dev/null | wc -l | xargs echo "📕 Archivos PDF:" >> "$report_file"
        find "$OUTPUT_DIR" -type f -name "*.csv" 2>/dev/null | wc -l | xargs echo "📊 Archivos CSV:" >> "$report_file"
    fi
    
    # Información de base de datos
    if [[ -f "$DB_DIR/documentos.db" ]]; then
        echo "" >> "$report_file"
        echo "🗄️  BASE DE DATOS:" >> "$report_file"
        echo "───────────────────────────────────────────────────────────────────" >> "$report_file"
        
        local total_records=$(sqlite3 "$DB_DIR/documentos.db" "SELECT COUNT(*) FROM archivos;" 2>/dev/null || echo "0")
        local processed_records=$(sqlite3 "$DB_DIR/documentos.db" "SELECT COUNT(*) FROM archivos WHERE estado='procesado';" 2>/dev/null || echo "0")
        local error_records=$(sqlite3 "$DB_DIR/documentos.db" "SELECT COUNT(*) FROM archivos WHERE estado='error';" 2>/dev/null || echo "0")
        
        echo "📊 Total de registros: $total_records" >> "$report_file"
        echo "✅ Archivos procesados: $processed_records" >> "$report_file"
        echo "❌ Archivos con error: $error_records" >> "$report_file"
    fi
    
    echo "" >> "$report_file"
    echo "═══════════════════════════════════════════════════════════════════" >> "$report_file"
    echo "🤖 Reporte generado automáticamente" >> "$report_file"
    echo "═══════════════════════════════════════════════════════════════════" >> "$report_file"
    
    log_info "✅ Reporte generado: $report_file"
    
    # Mostrar resumen en consola
    echo -e "\n${GREEN}📊 RESUMEN DEL MANTENIMIENTO:${NC}"
    cat "$report_file" | grep -E "^(📥|📤|📄|📕|📊|✅|❌)" | head -10
    
    return 0
}

# Función para limpieza final
cleanup_temp_files() {
    log_info "🧹 Limpieza final de archivos temporales..."
    
    # Limpiar archivos temporales de procesamiento
    find "$OUTPUT_DIR" -name "tmp_*" -type d -exec rm -rf {} + 2>/dev/null
    find "$OUTPUT_DIR" -name "*.tmp" -type f -delete 2>/dev/null
    find "$OUTPUT_DIR" -name "temp_*" -type f -delete 2>/dev/null
    
    # Limpiar archivos de bloqueo
    find "$OUTPUT_DIR" -name "*.lock" -type f -delete 2>/dev/null
    
    log_info "✅ Limpieza final completada"
    return 0
}

# Función para enviar notificación por email
send_notification() {
    local status="$1"
    local report_file="$2"
    
    if [[ -n "$NOTIFICATION_EMAIL" ]]; then
        local subject="Mantenimiento automatizado: $status"
        local body="El mantenimiento automatizado ha $status en $(date)"
        
        if command -v mail &> /dev/null && [[ -f "$report_file" ]]; then
            mail -s "$subject" "$NOTIFICATION_EMAIL" < "$report_file"
            log_info "📧 Notificación enviada a: $NOTIFICATION_EMAIL"
        else
            log_warn "⚠️  No se pudo enviar notificación por email"
        fi
    fi
}

# Función principal de automatización
run_automated_maintenance() {
    local start_time=$(date +%s)
    local total_steps=${#AUTOMATED_STEPS[@]}
    local current_step=0
    local failed_steps=()
    
    log_info "🤖 Iniciando mantenimiento completamente automatizado"
    log_info "📊 Total de pasos: $total_steps"
    log_info "⚙️  Modo de fuerza: $FORCE_EXECUTION"
    log_info "💾 Saltar respaldos: $SKIP_BACKUPS"
    
    for step in "${AUTOMATED_STEPS[@]}"; do
        ((current_step++))
        local step_desc="${AUTO_STEP_DESC[$step]}"
        
        show_automation_progress "$current_step" "$total_steps" "$step_desc" "$start_time"
        
        log_info "[$current_step/$total_steps] Ejecutando: $step_desc"
        
        if $step; then
            log_info "✅ Paso completado: $step_desc"
        else
            local exit_code=$?
            log_error "❌ Paso falló: $step_desc (código: $exit_code)"
            failed_steps+=("$step_desc")
            
            if [[ "$FORCE_EXECUTION" != "true" ]]; then
                log_error "🛑 Deteniendo mantenimiento debido a error"
                break
            else
                log_warn "⚠️  Continuando debido a modo --force"
            fi
        fi
        
        # Pequeña pausa para mostrar progreso
        sleep 1
    done
    
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))
    
    # Generar reporte final
    local report_file="$OUTPUT_DIR/reportes/reporte_$(date '+%Y%m%d_%H%M%S').txt"
    
    # Mostrar resumen final
    clear
    if [[ ${#failed_steps[@]} -eq 0 ]]; then
        echo -e "\n${GREEN}🎉 MANTENIMIENTO AUTOMATIZADO COMPLETADO EXITOSAMENTE${NC}"
        log_info "✅ Mantenimiento automatizado completado exitosamente"
        send_notification "completado exitosamente" "$report_file"
    else
        echo -e "\n${YELLOW}⚠️  MANTENIMIENTO COMPLETADO CON ERRORES${NC}"
        echo -e "${RED}Pasos que fallaron:${NC}"
        for failed_step in "${failed_steps[@]}"; do
            echo -e "  ❌ $failed_step"
        done
        log_error "⚠️  Mantenimiento completado con ${#failed_steps[@]} errores"
        send_notification "completado con errores" "$report_file"
    fi
    
    echo -e "\n📊 Estadísticas:"
    echo -e "  ⏱️  Duración total: ${total_duration}s"
    echo -e "  ✅ Pasos completados: $((current_step - ${#failed_steps[@]}))/$total_steps"
    echo -e "  ❌ Pasos fallidos: ${#failed_steps[@]}"
    echo -e "  📄 Reporte generado: $report_file"
    
    if [[ ${#failed_steps[@]} -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Función para mostrar ayuda
show_help() {
    cat << EOF
🤖 Script de Mantenimiento Automatizado del Organizador de Documentos

USO: $0 [OPCIONES]

OPCIONES:
    -h, --help              Mostrar esta ayuda
    -f, --force             Continuar ejecución aunque fallen algunos pasos
    --skip-backups          Saltar creación de respaldos (más rápido)
    --email EMAIL           Enviar notificación a este email al terminar
    --dry-run              Mostrar qué se ejecutaría sin hacerlo
    -v, --verbose          Modo verbose (LOG_LEVEL=DEBUG)
    -q, --quiet            Modo silencioso (LOG_LEVEL=ERROR)

PASOS AUTOMATIZADOS:
EOF
    
    local step_num=1
    for step in "${AUTOMATED_STEPS[@]}"; do
        printf "    %2d. %s\n" "$step_num" "${AUTO_STEP_DESC[$step]}"
        ((step_num++))
    done
    
    cat << EOF

EJEMPLOS:
    $0                      # Ejecución automática estándar
    $0 --force              # Continuar aunque haya errores
    $0 --skip-backups       # Omitir respaldos (más rápido)
    $0 --email admin@empresa.com  # Enviar notificación
    $0 --dry-run            # Solo mostrar qué se haría

NOTAS:
    • Este script ejecuta TODO el mantenimiento sin parar
    • Para control paso a paso, use ./mantenimiento.sh
    • Los logs se guardan en $LOG_DIR/
    • Los reportes se generan en $OUTPUT_DIR/reportes/

EOF
}

# Procesar argumentos de línea de comandos
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -f|--force)
            FORCE_EXECUTION=true
            shift
            ;;
        --skip-backups)
            SKIP_BACKUPS=true
            shift
            ;;
        --email)
            NOTIFICATION_EMAIL="$2"
            shift 2
            ;;
        --dry-run)
            echo "🔍 SIMULACIÓN - Pasos que se ejecutarían:"
            local step_num=1
            for step in "${AUTOMATED_STEPS[@]}"; do
                echo "  $step_num. ${AUTO_STEP_DESC[$step]}"
                ((step_num++))
            done
            exit 0
            ;;
        -v|--verbose)
            LOG_LEVEL="DEBUG"
            shift
            ;;
        -q|--quiet)
            LOG_LEVEL="ERROR"
            shift
            ;;
        *)
            echo "Error: Opción desconocida: $1"
            echo "Use '$0 --help' para ver las opciones disponibles"
            exit 1
            ;;
    esac
done

# Configurar entorno y ejecutar
export LOG_LEVEL
init_logging

# Ejecutar mantenimiento automatizado
run_automated_maintenance