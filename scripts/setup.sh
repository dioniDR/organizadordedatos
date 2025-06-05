#!/bin/bash

# Script de configuración y validación del entorno

# Cargar utilidades
source "$(dirname "$0")/utils.sh"

# Configuración por defecto
DEFAULT_INPUT_DIR="/app/entrada"
DEFAULT_OUTPUT_DIR="/app/salida" 
DEFAULT_DB_DIR="/app/db"
DEFAULT_LOG_DIR="/app/logs"

# Función para mostrar ayuda
show_help() {
    cat << EOF
Configuración del Organizador de Documentos

USO: $0 [OPCIONES]

OPCIONES:
    -h, --help              Mostrar esta ayuda
    -v, --validate          Solo validar el entorno (no inicializar)
    -i, --input DIR         Directorio de entrada (default: $DEFAULT_INPUT_DIR)
    -o, --output DIR        Directorio de salida (default: $DEFAULT_OUTPUT_DIR)
    -d, --db DIR           Directorio de base de datos (default: $DEFAULT_DB_DIR)
    -l, --log DIR          Directorio de logs (default: $DEFAULT_LOG_DIR)
    --log-level LEVEL      Nivel de logging: DEBUG, INFO, WARN, ERROR (default: INFO)
    --max-jobs N           Máximo número de trabajos paralelos (default: 4)
    --check-deps           Verificar dependencias del sistema

EJEMPLOS:
    $0                     # Configuración básica
    $0 --validate          # Solo validar
    $0 --check-deps        # Verificar dependencias
    $0 -i /custom/input -o /custom/output --log-level DEBUG

EOF
}

# Función para verificar dependencias
check_dependencies() {
    log_info "Verificando dependencias del sistema..."
    
    local required_commands=(
        "pdftotext:poppler-utils"
        "pdftoppm:poppler-utils" 
        "tesseract:tesseract-ocr"
        "libreoffice:libreoffice"
        "pandoc:pandoc"
        "sqlite3:sqlite3"
        "curl:curl"
        "jq:jq"
        "file:file"
        "stat:coreutils"
        "find:findutils"
        "grep:grep"
    )
    
    local missing_deps=()
    
    for dep in "${required_commands[@]}"; do
        local cmd="${dep%:*}"
        local package="${dep#*:}"
        
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd ($package)")
            log_error "Comando no encontrado: $cmd (instalar paquete: $package)"
        else
            log_debug "✓ $cmd disponible"
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Dependencias faltantes: ${missing_deps[*]}"
        return 1
    fi
    
    log_info "✓ Todas las dependencias están disponibles"
    return 0
}

# Función para verificar permisos
check_permissions() {
    local dir="$1"
    local operation="$2"
    
    case $operation in
        "read")
            if [[ ! -r "$dir" ]]; then
                log_error "Sin permisos de lectura en: $dir"
                return 1
            fi
            ;;
        "write")
            if [[ ! -w "$dir" ]]; then
                log_error "Sin permisos de escritura en: $dir"
                return 1
            fi
            ;;
        "execute")
            if [[ ! -x "$dir" ]]; then
                log_error "Sin permisos de ejecución en: $dir"
                return 1
            fi
            ;;
    esac
    
    return 0
}

# Función para validar el entorno
validate_environment() {
    log_info "Validando entorno del sistema..."
    
    local validation_errors=0
    
    # Verificar directorios
    for dir_var in INPUT_DIR OUTPUT_DIR DB_DIR LOG_DIR; do
        local dir_path="${!dir_var}"
        
        if [[ ! -d "$dir_path" ]]; then
            log_warn "Directorio no existe: $dir_path"
            if [[ "$dir_var" == "INPUT_DIR" ]]; then
                log_error "Directorio de entrada es obligatorio"
                ((validation_errors++))
            fi
        else
            # Verificar permisos
            case $dir_var in
                "INPUT_DIR")
                    check_permissions "$dir_path" "read" || ((validation_errors++))
                    ;;
                "OUTPUT_DIR"|"DB_DIR"|"LOG_DIR")
                    check_permissions "$dir_path" "write" || ((validation_errors++))
                    ;;
            esac
        fi
    done
    
    # Verificar espacio en disco
    if [[ -d "$OUTPUT_DIR" ]]; then
        local available_space=$(df "$OUTPUT_DIR" | awk 'NR==2 {print $4}')
        local available_mb=$((available_space / 1024))
        
        if [[ $available_mb -lt 100 ]]; then
            log_warn "Poco espacio disponible: ${available_mb}MB"
        else
            log_info "Espacio disponible: ${available_mb}MB"
        fi
    fi
    
    # Verificar variables de entorno importantes
    if [[ -z "$MAX_PARALLEL_JOBS" ]] || [[ ! "$MAX_PARALLEL_JOBS" =~ ^[0-9]+$ ]]; then
        log_warn "MAX_PARALLEL_JOBS no está configurado correctamente, usando default: 4"
        export MAX_PARALLEL_JOBS=4
    fi
    
    return $validation_errors
}

# Función para inicializar el entorno
initialize_environment() {
    log_info "Inicializando entorno de trabajo..."
    
    # Crear directorios necesarios
    for dir in "$OUTPUT_DIR" "$DB_DIR" "$LOG_DIR"; do
        ensure_dir "$dir"
    done
    
    # Configurar estructura de salida
    ensure_dir "$OUTPUT_DIR/txt"
    ensure_dir "$OUTPUT_DIR/processed"
    ensure_dir "$OUTPUT_DIR/temp"
    
    # Inicializar base de datos si no existe
    local db_file="$DB_DIR/documentos.db"
    if [[ ! -f "$db_file" ]]; then
        log_info "Inicializando base de datos: $db_file"
        sqlite3 "$db_file" << 'EOF'
CREATE TABLE IF NOT EXISTS archivos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    ruta_original TEXT NOT NULL,
    ruta_procesado TEXT,
    tipo_archivo TEXT NOT NULL,
    tamano INTEGER,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_procesado TIMESTAMP,
    hash_md5 TEXT,
    estado TEXT DEFAULT 'pendiente',
    metadatos TEXT
);

CREATE INDEX IF NOT EXISTS idx_hash_md5 ON archivos(hash_md5);
CREATE INDEX IF NOT EXISTS idx_estado ON archivos(estado);
CREATE INDEX IF NOT EXISTS idx_tipo_archivo ON archivos(tipo_archivo);
EOF
        log_info "Base de datos inicializada"
    fi
    
    # Crear archivo de configuración
    local config_file="$DB_DIR/config.conf"
    cat > "$config_file" << EOF
# Configuración del Organizador de Documentos
# Generado automáticamente el $(date)

INPUT_DIR=$INPUT_DIR
OUTPUT_DIR=$OUTPUT_DIR
DB_DIR=$DB_DIR
LOG_DIR=$LOG_DIR
LOG_LEVEL=$LOG_LEVEL
MAX_PARALLEL_JOBS=$MAX_PARALLEL_JOBS

# Configuración OCR
OCR_LANGUAGE=spa
OCR_PSM=3
OCR_DPI=300

# Configuración de procesamiento
BACKUP_ENABLED=true
CLEANUP_TEMP=true
PRESERVE_METADATA=true
EOF
    
    log_info "Archivo de configuración creado: $config_file"
}

# Parsear argumentos de línea de comandos
VALIDATE_ONLY=false
CHECK_DEPS_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--validate)
            VALIDATE_ONLY=true
            shift
            ;;
        --check-deps)
            CHECK_DEPS_ONLY=true
            shift
            ;;
        -i|--input)
            INPUT_DIR="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -d|--db)
            DB_DIR="$2"
            shift 2
            ;;
        -l|--log)
            LOG_DIR="$2"
            shift 2
            ;;
        --log-level)
            LOG_LEVEL="$2"
            shift 2
            ;;
        --max-jobs)
            MAX_PARALLEL_JOBS="$2"
            shift 2
            ;;
        *)
            log_error "Opción desconocida: $1"
            show_help
            exit 1
            ;;
    esac
done

# Configurar valores por defecto
INPUT_DIR="${INPUT_DIR:-$DEFAULT_INPUT_DIR}"
OUTPUT_DIR="${OUTPUT_DIR:-$DEFAULT_OUTPUT_DIR}"
DB_DIR="${DB_DIR:-$DEFAULT_DB_DIR}"
LOG_DIR="${LOG_DIR:-$DEFAULT_LOG_DIR}"
LOG_LEVEL="${LOG_LEVEL:-INFO}"
MAX_PARALLEL_JOBS="${MAX_PARALLEL_JOBS:-4}"

# Exportar variables de entorno
export INPUT_DIR OUTPUT_DIR DB_DIR LOG_DIR LOG_LEVEL MAX_PARALLEL_JOBS

# Inicializar logging
init_logging

log_info "=== CONFIGURACIÓN DEL ORGANIZADOR DE DOCUMENTOS ==="
log_info "Directorio de entrada: $INPUT_DIR"
log_info "Directorio de salida: $OUTPUT_DIR"
log_info "Directorio de BD: $DB_DIR"
log_info "Directorio de logs: $LOG_DIR"
log_info "Nivel de logging: $LOG_LEVEL"
log_info "Trabajos paralelos: $MAX_PARALLEL_JOBS"

# Ejecutar según los argumentos
if [[ "$CHECK_DEPS_ONLY" == "true" ]]; then
    check_dependencies
    exit $?
elif [[ "$VALIDATE_ONLY" == "true" ]]; then
    validate_environment
    exit $?
else
    # Configuración completa
    if check_dependencies && validate_environment; then
        initialize_environment
        log_info "✓ Configuración completada exitosamente"
        exit 0
    else
        log_error "✗ Error en la configuración"
        exit 1
    fi
fi