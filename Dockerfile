FROM ubuntu:22.04

# Actualizar e instalar utilidades necesarias
RUN apt update && apt install -y \
    tesseract-ocr \
    tesseract-ocr-spa \
    poppler-utils \
    bash \
    && apt clean

# Crear directorios esperados en el contenedor
RUN mkdir -p /app/entrada /app/salida /app/scripts

WORKDIR /app

# Copiar scripts y enlazar entrada/salida desde el host
COPY convert_all.sh /app/scripts/
RUN chmod +x /app/scripts/convert_all.sh
