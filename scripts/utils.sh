#!/bin/bash

# Utilidades comunes para logging y manejo de errores

# Configuración de logging
LOG_LEVEL=${LOG_LEVEL:-INFO}
LOG_DIR=${LOG_DIR:-/app/logs}
LOG_FILE="$LOG_DIR/$(basename "$0" .sh).log"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función de logging
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Solo mostrar si el nivel es apropiado
    case $LOG_LEVEL in
        DEBUG) levels="DEBUG INFO WARN ERROR" ;;
        INFO)  levels="INFO WARN ERROR" ;;
        WARN)  levels="WARN ERROR" ;;
        ERROR) levels="ERROR" ;;
    esac
    
    if [[ " $levels " =~ " $level " ]]; then
        # Color según nivel
        case $level in
            ERROR) color=$RED ;;
            WARN)  color=$YELLOW ;;
            INFO)  color=$GREEN ;;
            DEBUG) color=$BLUE ;;
            *)     color=$NC ;;
        esac
        
        echo -e "${color}[$timestamp] [$level] $message${NC}" | tee -a "$LOG_FILE"
    fi
}

# Funciones específicas
log_debug() { log "DEBUG" "$@"; }
log_info() { log "INFO" "$@"; }
log_warn() { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }

# Manejo de errores
handle_error() {
    local exit_code=$1
    local message="$2"
    local line_no=${3:-$LINENO}
    
    log_error "Error en línea $line_no: $message (código de salida: $exit_code)"
    exit $exit_code
}

# Trap para capturar errores
set -eE
trap 'handle_error $? "Error inesperado" $LINENO' ERR

# Validar que un comando existe
check_command() {
    local cmd=$1
    if ! command -v "$cmd" &> /dev/null; then
        handle_error 127 "Comando requerido no encontrado: $cmd"
    fi
}

# Validar que un archivo existe
check_file() {
    local file=$1
    if [[ ! -f "$file" ]]; then
        handle_error 2 "Archivo no encontrado: $file"
    fi
}

# Validar que un directorio existe
check_dir() {
    local dir=$1
    if [[ ! -d "$dir" ]]; then
        handle_error 2 "Directorio no encontrado: $dir"
    fi
}

# Crear directorio si no existe
ensure_dir() {
    local dir=$1
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" || handle_error $? "No se pudo crear directorio: $dir"
        log_info "Directorio creado: $dir"
    fi
}

# Obtener información del archivo
get_file_info() {
    local file=$1
    check_file "$file"
    
    local size=$(stat -c%s "$file")
    local mime=$(file -b --mime-type "$file")
    local modified=$(stat -c%Y "$file")
    
    echo "size:$size,mime:$mime,modified:$modified"
}

# Verificar espacio en disco
check_disk_space() {
    local dir=$1
    local required_mb=$2
    
    local available=$(df "$dir" | awk 'NR==2 {print $4}')
    local available_mb=$((available / 1024))
    
    if [[ $available_mb -lt $required_mb ]]; then
        handle_error 28 "Espacio insuficiente. Requerido: ${required_mb}MB, Disponible: ${available_mb}MB"
    fi
}

# Progreso de procesamiento
show_progress() {
    local current=$1
    local total=$2
    local item="$3"
    
    local percent=$((current * 100 / total))
    local bar_length=50
    local filled_length=$((percent * bar_length / 100))
    
    printf "\r["
    for ((i=1; i<=filled_length; i++)); do printf "="; done
    for ((i=filled_length+1; i<=bar_length; i++)); do printf " "; done
    printf "] %d%% (%d/%d) %s" "$percent" "$current" "$total" "$item"
}

# Limpiar línea de progreso
clear_progress() {
    printf "\r%*s\r" "$(tput cols)" ""
}

# Inicializar logging
init_logging() {
    ensure_dir "$LOG_DIR"
    log_info "Iniciando $(basename "$0") - PID: $$"
}