# Multi-stage build for optimized image
FROM ubuntu:22.04 as base

# Variables de entorno para evitar preguntas en la instalación y configurar locale
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=Europe/Madrid

# Install system dependencies in optimized layers
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    tzdata \
    && ln -fs /usr/share/zoneinfo/$TZ /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata \
    && rm -rf /var/lib/apt/lists/*

# Install OCR and document processing tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    tesseract-ocr \
    tesseract-ocr-spa \
    tesseract-ocr-eng \
    poppler-utils \
    pdf2svg \
    ghostscript \
    imagemagick \
    && rm -rf /var/lib/apt/lists/*

# Install office and conversion tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    libreoffice \
    unoconv \
    pandoc \
    && rm -rf /var/lib/apt/lists/*

# Install system utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    sqlite3 \
    inotify-tools \
    fd-find \
    ripgrep \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Crear directorios necesarios con permisos apropiados
RUN mkdir -p /app/entrada /app/salida /app/scripts /app/db /app/logs \
    && chown -R appuser:appuser /app

# Configurar directorio de trabajo
WORKDIR /app

# Copiar scripts y configuración
COPY scripts/ /app/scripts/
COPY convert_all.sh convertir_ocr_organizar.sh /app/scripts/
RUN chmod +x /app/scripts/*.sh \
    && chown -R appuser:appuser /app/scripts

# Variables de entorno para configuración
ENV INPUT_DIR=/app/entrada \
    OUTPUT_DIR=/app/salida \
    DB_DIR=/app/db \
    LOG_DIR=/app/logs \
    LOG_LEVEL=INFO \
    MAX_PARALLEL_JOBS=4

# Configurar ImageMagick policy para PDFs
RUN sed -i 's/policy domain="coder" rights="none" pattern="PDF"/policy domain="coder" rights="read|write" pattern="PDF"/' /etc/ImageMagick-6/policy.xml

# Healthcheck mejorado
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD [ -d "$INPUT_DIR" ] && [ -d "$OUTPUT_DIR" ] && [ -w "$OUTPUT_DIR" ] || exit 1

# Cambiar a usuario no privilegiado
USER appuser

# Comando por defecto con logging mejorado
CMD ["/bin/bash", "-c", "exec /app/scripts/convert_all.sh 2>&1 | tee /app/logs/processing.log"]
