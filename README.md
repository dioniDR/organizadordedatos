# Organizador de PDFs con OCR y Clasificación

Este proyecto permite procesar archivos PDF para extraer texto, aplicar OCR si es necesario, generar versiones accesibles y organizar archivos por año de creación.

## 🛠 Requisitos

- Docker y Docker Compose
- Archivos `.pdf` colocados en la carpeta `entrada/`

## 🚀 Cómo usar

1. Coloca tus archivos PDF en `entrada/`
2. Ejecuta el contenedor:

```bash
docker compose up --build
