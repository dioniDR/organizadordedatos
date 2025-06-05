#!/bin/bash

# Script de mantenimiento interactivo del Organizador de Documentos
# Permite al usuario controlar cada paso del proceso

# Cargar utilidades
source "$(dirname "$0")/scripts/utils.sh"

# Configuración
SCRIPT_DIR="$(dirname "$0")"
MENU_TITLE="🔧 MANTENIMIENTO DEL ORGANIZADOR DE DOCUMENTOS"

# Estados de los pasos
declare -A STEP_STATUS
declare -A STEP_DESCRIPTION
declare -A STEP_SCRIPT

# Definir pasos del mantenimiento
setup_maintenance_steps() {
    # Orden de ejecución lógico
    STEPS=(
        "01_validate"
        "02_backup"
        "03_cleanup"
        "04_process_pdfs"
        "05_convert_office"
        "06_extract_xml"
        "07_deduplicate"
        "08_organize"
        "09_consolidate"
        "10_verify"
    )
    
    # Descripciones de cada paso
    STEP_DESCRIPTION["01_validate"]="Validar entorno y dependencias"
    STEP_DESCRIPTION["02_backup"]="Crear respaldo de datos existentes"
    STEP_DESCRIPTION["03_cleanup"]="Limpiar archivos temporales y logs antiguos"
    STEP_DESCRIPTION["04_process_pdfs"]="Procesar archivos PDF (texto y OCR)"
    STEP_DESCRIPTION["05_convert_office"]="Convertir documentos DOCX y XLSX"
    STEP_DESCRIPTION["06_extract_xml"]="Extraer contenido de archivos XML"
    STEP_DESCRIPTION["07_deduplicate"]="Eliminar archivos duplicados"
    STEP_DESCRIPTION["08_organize"]="Organizar archivos por año y tipo"
    STEP_DESCRIPTION["09_consolidate"]="Consolidar textos en archivo único"
    STEP_DESCRIPTION["10_verify"]="Verificar integridad y generar reporte"
    
    # Scripts asociados a cada paso
    STEP_SCRIPT["01_validate"]="scripts/setup.sh --validate"
    STEP_SCRIPT["02_backup"]="scripts/backup.sh"
    STEP_SCRIPT["03_cleanup"]="scripts/cleanup.sh"
    STEP_SCRIPT["04_process_pdfs"]="scripts/procesar_pdfs.sh"
    STEP_SCRIPT["05_convert_office"]="scripts/convertir_docx_xlsx.sh"
    STEP_SCRIPT["06_extract_xml"]="scripts/extraer_xml.sh"
    STEP_SCRIPT["07_deduplicate"]="scripts/limpiar_repetidos.sh"
    STEP_SCRIPT["08_organize"]="scripts/organizar_por_anio.sh"
    STEP_SCRIPT["09_consolidate"]="scripts/consolidar_textos.sh"
    STEP_SCRIPT["10_verify"]="scripts/verify.sh"
    
    # Inicializar estados
    for step in "${STEPS[@]}"; do
        STEP_STATUS["$step"]="⏸️  Pendiente"
    done
}

# Función para mostrar el estado actual
show_status() {
    clear
    echo -e "\n${GREEN}$MENU_TITLE${NC}\n"
    echo "═══════════════════════════════════════════════════════════════════"
    echo -e "${BLUE}Estado actual del mantenimiento:${NC}\n"
    
    local step_num=1
    for step in "${STEPS[@]}"; do
        local status="${STEP_STATUS[$step]}"
        local description="${STEP_DESCRIPTION[$step]}"
        
        printf "%2d. %-50s %s\n" "$step_num" "$description" "$status"
        ((step_num++))
    done
    
    echo ""
    echo "═══════════════════════════════════════════════════════════════════"
}

# Función para mostrar ayuda de un paso
show_step_help() {
    local step="$1"
    local description="${STEP_DESCRIPTION[$step]}"
    local script="${STEP_SCRIPT[$step]}"
    
    echo -e "\n${YELLOW}📋 Información del paso:${NC}"
    echo "Descripción: $description"
    echo "Script: $script"
    
    case $step in
        "01_validate")
            echo -e "\n${BLUE}Este paso verifica:${NC}"
            echo "• Dependencias del sistema (tesseract, poppler, etc.)"
            echo "• Permisos de directorios"
            echo "• Espacio en disco disponible"
            echo "• Variables de entorno"
            ;;
        "02_backup")
            echo -e "\n${BLUE}Este paso:${NC}"
            echo "• Crea respaldo de la base de datos"
            echo "• Respalda archivos de configuración"
            echo "• Guarda estado actual de salida"
            ;;
        "03_cleanup")
            echo -e "\n${BLUE}Este paso limpia:${NC}"
            echo "• Archivos temporales antiguos"
            echo "• Logs de más de 7 días"
            echo "• Caché de procesamiento"
            ;;
        "04_process_pdfs")
            echo -e "\n${BLUE}Este paso procesa:${NC}"
            echo "• Extracción de texto directo de PDFs"
            echo "• OCR para PDFs escaneados"
            echo "• Procesamiento paralelo optimizado"
            ;;
        "05_convert_office")
            echo -e "\n${BLUE}Este paso convierte:${NC}"
            echo "• Archivos DOCX a texto plano"
            echo "• Archivos XLSX a CSV"
            echo "• Preserva metadatos importantes"
            ;;
        "06_extract_xml")
            echo -e "\n${BLUE}Este paso extrae:${NC}"
            echo "• Contenido de texto de XMLs"
            echo "• Estructura de datos preservada"
            echo "• Validación de formato"
            ;;
        "07_deduplicate")
            echo -e "\n${BLUE}Este paso elimina:${NC}"
            echo "• Archivos duplicados por hash MD5"
            echo "• Contenido duplicado en textos"
            echo "• Mantiene registro de eliminados"
            ;;
        "08_organize")
            echo -e "\n${BLUE}Este paso organiza:${NC}"
            echo "• Archivos por año de creación"
            echo "• Estructura de carpetas lógica"
            echo "• Metadatos en base de datos"
            ;;
        "09_consolidate")
            echo -e "\n${BLUE}Este paso consolida:${NC}"
            echo "• Todos los textos en archivo único"
            echo "• Índice de contenidos"
            echo "• Estadísticas finales"
            ;;
        "10_verify")
            echo -e "\n${BLUE}Este paso verifica:${NC}"
            echo "• Integridad de archivos procesados"
            echo "• Completitud del procesamiento"
            echo "• Genera reporte final"
            ;;
    esac
}

# Función para ejecutar un paso
execute_step() {
    local step="$1"
    local description="${STEP_DESCRIPTION[$step]}"
    local script="${STEP_SCRIPT[$step]}"
    
    echo -e "\n${YELLOW}🚀 Ejecutando: $description${NC}"
    echo "Script: $script"
    
    STEP_STATUS["$step"]="🔄 Ejecutando..."
    
    # Verificar si el script existe
    local script_path="$SCRIPT_DIR/$script"
    if [[ ! -f "$script_path" ]]; then
        STEP_STATUS["$step"]="❌ Error: Script no encontrado"
        log_error "Script no encontrado: $script_path"
        return 1
    fi
    
    # Ejecutar el script
    local start_time=$(date +%s)
    if bash "$script_path"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        STEP_STATUS["$step"]="✅ Completado (${duration}s)"
        log_info "Paso completado: $description en ${duration}s"
        return 0
    else
        local exit_code=$?
        STEP_STATUS["$step"]="❌ Error (código: $exit_code)"
        log_error "Paso falló: $description con código $exit_code"
        return $exit_code
    fi
}

# Función para ejecutar pasos hasta cierto punto
execute_up_to() {
    local target_step="$1"
    local found=false
    
    for step in "${STEPS[@]}"; do
        if [[ "$step" == "$target_step" ]]; then
            found=true
        fi
        
        if [[ "$found" == "false" ]] || [[ "$step" == "$target_step" ]]; then
            if [[ "${STEP_STATUS[$step]}" != *"✅"* ]]; then
                execute_step "$step"
                if [[ $? -ne 0 ]]; then
                    echo -e "\n${RED}❌ Error en paso: ${STEP_DESCRIPTION[$step]}${NC}"
                    echo -e "¿Desea continuar con el siguiente paso? (s/N): \c"
                    read -r continue_choice
                    if [[ ! "$continue_choice" =~ ^[Ss]$ ]]; then
                        return 1
                    fi
                fi
            else
                echo -e "⏭️  Saltando paso ya completado: ${STEP_DESCRIPTION[$step]}"
            fi
        fi
        
        if [[ "$step" == "$target_step" ]]; then
            break
        fi
    done
}

# Menú principal
show_main_menu() {
    echo -e "\n${GREEN}OPCIONES DISPONIBLES:${NC}"
    echo ""
    echo "📋 INFORMACIÓN:"
    echo "  h) Mostrar esta ayuda"
    echo "  s) Mostrar estado actual"
    echo "  i) Información sobre un paso específico"
    echo ""
    echo "🔧 EJECUCIÓN INDIVIDUAL:"
    echo "  1-10) Ejecutar paso específico"
    echo ""
    echo "🚀 EJECUCIÓN MÚLTIPLE:"
    echo "  u) Ejecutar hasta un paso específico"
    echo "  a) Ejecutar TODOS los pasos (sin parar)"
    echo "  r) Reiniciar todos los estados"
    echo ""
    echo "🔍 UTILIDADES:"
    echo "  l) Ver logs recientes"
    echo "  c) Limpiar pantalla"
    echo ""
    echo "❌ SALIR:"
    echo "  q) Salir del mantenimiento"
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
}

# Función principal del menú interactivo
interactive_menu() {
    init_logging
    setup_maintenance_steps
    
    log_info "Iniciando mantenimiento interactivo"
    
    while true; do
        show_status
        show_main_menu
        
        echo -e "\n${YELLOW}Seleccione una opción:${NC} \c"
        read -r choice
        
        case $choice in
            h|H|help|ayuda)
                show_main_menu
                echo -e "\nPresione Enter para continuar..."
                read -r
                ;;
            s|S|status|estado)
                # Ya se muestra arriba, solo pausa
                echo -e "\nPresione Enter para continuar..."
                read -r
                ;;
            i|I|info)
                echo -e "\n¿Sobre qué paso desea información? (1-10): \c"
                read -r step_num
                if [[ "$step_num" =~ ^[1-9]|10$ ]]; then
                    local step_index=$((step_num - 1))
                    local step="${STEPS[$step_index]}"
                    show_step_help "$step"
                else
                    echo -e "${RED}Número de paso inválido${NC}"
                fi
                echo -e "\nPresione Enter para continuar..."
                read -r
                ;;
            [1-9]|10)
                local step_index=$((choice - 1))
                local step="${STEPS[$step_index]}"
                echo -e "\n¿Ejecutar: ${STEP_DESCRIPTION[$step]}? (S/n): \c"
                read -r confirm
                if [[ ! "$confirm" =~ ^[Nn]$ ]]; then
                    execute_step "$step"
                    echo -e "\nPresione Enter para continuar..."
                    read -r
                fi
                ;;
            u|U|hasta)
                echo -e "\n¿Hasta qué paso ejecutar? (1-10): \c"
                read -r step_num
                if [[ "$step_num" =~ ^[1-9]|10$ ]]; then
                    local step_index=$((step_num - 1))
                    local target_step="${STEPS[$step_index]}"
                    echo -e "\n¿Ejecutar hasta: ${STEP_DESCRIPTION[$target_step]}? (S/n): \c"
                    read -r confirm
                    if [[ ! "$confirm" =~ ^[Nn]$ ]]; then
                        execute_up_to "$target_step"
                    fi
                else
                    echo -e "${RED}Número de paso inválido${NC}"
                fi
                echo -e "\nPresione Enter para continuar..."
                read -r
                ;;
            a|A|all|todo)
                echo -e "\n${RED}⚠️  ¿Ejecutar TODOS los pasos del mantenimiento?${NC}"
                echo -e "Esto puede tomar mucho tiempo. (S/n): \c"
                read -r confirm
                if [[ ! "$confirm" =~ ^[Nn]$ ]]; then
                    for step in "${STEPS[@]}"; do
                        execute_step "$step"
                    done
                    echo -e "\n${GREEN}✅ Mantenimiento completo terminado${NC}"
                fi
                echo -e "\nPresione Enter para continuar..."
                read -r
                ;;
            r|R|reset|reiniciar)
                echo -e "\n¿Reiniciar todos los estados? (s/N): \c"
                read -r confirm
                if [[ "$confirm" =~ ^[Ss]$ ]]; then
                    for step in "${STEPS[@]}"; do
                        STEP_STATUS["$step"]="⏸️  Pendiente"
                    done
                    echo -e "${GREEN}Estados reiniciados${NC}"
                fi
                ;;
            l|L|logs)
                echo -e "\n${BLUE}📄 Logs recientes:${NC}"
                if [[ -f "$LOG_DIR/mantenimiento.log" ]]; then
                    tail -20 "$LOG_DIR/mantenimiento.log"
                else
                    echo "No hay logs disponibles"
                fi
                echo -e "\nPresione Enter para continuar..."
                read -r
                ;;
            c|C|clear|limpiar)
                clear
                ;;
            q|Q|quit|salir|exit)
                echo -e "\n${YELLOW}¿Está seguro de que desea salir? (s/N): \c"
                read -r confirm
                if [[ "$confirm" =~ ^[Ss]$ ]]; then
                    log_info "Mantenimiento interactivo finalizado por el usuario"
                    echo -e "\n${GREEN}¡Hasta luego!${NC}"
                    exit 0
                fi
                ;;
            *)
                echo -e "\n${RED}Opción no válida: $choice${NC}"
                echo -e "Presione 'h' para ver la ayuda"
                sleep 2
                ;;
        esac
    done
}

# Función para mostrar ayuda del script
show_script_help() {
    cat << EOF
🔧 Script de Mantenimiento del Organizador de Documentos

USO: $0 [OPCIONES]

OPCIONES:
    -h, --help          Mostrar esta ayuda
    -i, --interactive   Modo interactivo (por defecto)
    -s, --status        Mostrar solo el estado actual
    --step N            Ejecutar solo el paso N (1-10)
    --up-to N          Ejecutar hasta el paso N
    --all              Ejecutar todos los pasos sin interacción
    --validate         Solo validar el entorno
    --dry-run          Mostrar qué se ejecutaría sin hacerlo

EJEMPLOS:
    $0                  # Modo interactivo
    $0 --step 4         # Solo procesar PDFs
    $0 --up-to 6        # Ejecutar pasos 1-6
    $0 --all            # Ejecutar todo automáticamente
    $0 --status         # Ver estado actual

PASOS DEL MANTENIMIENTO:
EOF

    setup_maintenance_steps
    local step_num=1
    for step in "${STEPS[@]}"; do
        printf "    %2d. %s\n" "$step_num" "${STEP_DESCRIPTION[$step]}"
        ((step_num++))
    done
}

# Procesar argumentos de línea de comandos
if [[ $# -eq 0 ]]; then
    # Sin argumentos, ejecutar modo interactivo
    interactive_menu
else
    case $1 in
        -h|--help)
            show_script_help
            exit 0
            ;;
        -i|--interactive)
            interactive_menu
            ;;
        -s|--status)
            setup_maintenance_steps
            show_status
            ;;
        --step)
            if [[ -n "$2" && "$2" =~ ^[1-9]|10$ ]]; then
                setup_maintenance_steps
                init_logging
                local step_index=$(($2 - 1))
                local step="${STEPS[$step_index]}"
                execute_step "$step"
            else
                echo "Error: Especifique un número de paso válido (1-10)"
                exit 1
            fi
            ;;
        --up-to)
            if [[ -n "$2" && "$2" =~ ^[1-9]|10$ ]]; then
                setup_maintenance_steps
                init_logging
                local step_index=$(($2 - 1))
                local target_step="${STEPS[$step_index]}"
                execute_up_to "$target_step"
            else
                echo "Error: Especifique un número de paso válido (1-10)"
                exit 1
            fi
            ;;
        --all)
            setup_maintenance_steps
            init_logging
            log_info "Ejecutando mantenimiento completo automático"
            for step in "${STEPS[@]}"; do
                execute_step "$step"
                if [[ $? -ne 0 ]]; then
                    log_error "Mantenimiento abortado en paso: ${STEP_DESCRIPTION[$step]}"
                    exit 1
                fi
            done
            log_info "Mantenimiento completo terminado exitosamente"
            ;;
        --validate)
            setup_maintenance_steps
            init_logging
            execute_step "01_validate"
            ;;
        --dry-run)
            setup_maintenance_steps
            echo "🔍 SIMULACIÓN - Pasos que se ejecutarían:"
            local step_num=1
            for step in "${STEPS[@]}"; do
                echo "  $step_num. ${STEP_DESCRIPTION[$step]} -> ${STEP_SCRIPT[$step]}"
                ((step_num++))
            done
            ;;
        *)
            echo "Error: Opción desconocida: $1"
            echo "Use '$0 --help' para ver las opciones disponibles"
            exit 1
            ;;
    esac
fi