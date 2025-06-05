# 🗂️ Organizador de Archivos Inteligente (Docker + OCR)

Este proyecto automatiza el análisis, limpieza, extracción de texto y organización de documentos comunes en entornos empresariales. Diseñado para correr en contenedores Docker, permite procesar:

- Archivos **PDF** (con o sin OCR)
- Documentos **Word (DOCX)** y **Excel (XLSX)**
- Archivos **CSV**, **TXT** y **XML**
- Limpieza de duplicados
- Organización por año
- Consolidación de resultados

---

## 📁 Estructura del Proyecto

organizador/
├── entrada/ # Carpeta compartida con documentos de entrada
├── salida/ # Resultados del procesamiento
├── scripts/ # Scripts bash que automatizan cada tarea
├── Dockerfile
├── docker-compose.yml
└── README.md

yaml
Copy
Edit

---

## ⚙️ Scripts disponibles

| Script | Función |
|--------|---------|
| `procesar_pdfs.sh` | Extrae texto o aplica OCR si el PDF está escaneado |
| `limpiar_repetidos.sh` | Detecta archivos duplicados por hash MD5 |
| `organizar_por_anio.sh` | Mueve PDFs a carpetas según su año |
| `convertir_docx_xlsx.sh` | Convierte DOCX a TXT y XLSX a CSV |
| `extraer_xml.sh` | Extrae texto plano desde XML |
| `consolidar_textos.sh` | Une todos los `.txt` en un solo archivo final |
| `run_all.sh` | Ejecuta todos los anteriores en orden lógico |

---

## 🐳 Docker

### Requisitos

- Docker >= 20.10
- Docker Compose >= 2.0

### Configuración inicial

1. **Copiar y ajustar configuración:**
   ```bash
   cp .env.example .env
   # Editar .env con tus rutas y configuraciones
   ```

2. **Crear directorios necesarios:**
   ```bash
   mkdir -p entrada salida db logs
   ```

### Build y ejecución

```bash
# Build del contenedor
docker-compose build

# Ejecución básica
docker-compose up

# Ejecución con monitoreo (opcional)
docker-compose --profile monitoring up

# Ejecución en background
docker-compose up -d
```

### Comandos útiles

```bash
# Ver logs en tiempo real
docker-compose logs -f organizador_documentos

# Ejecutar validación del entorno
docker-compose exec organizador_documentos /app/scripts/setup.sh --validate

# Verificar dependencias
docker-compose exec organizador_documentos /app/scripts/setup.sh --check-deps

# Acceder al contenedor
docker-compose exec organizador_documentos bash

# Parar servicios
docker-compose down
```

**Nota:** Coloca tus archivos en la carpeta `entrada/` antes de iniciar. Todos los resultados se guardan en `salida/`.

🧪 Casos de uso
Digitalización masiva de archivos antiguos

Preparación de datasets para IA/LLM

Análisis de documentos empresariales (facturas, actas, informes)

Clasificación automatizada por fecha o tipo

🛠️ Dependencias internas del contenedor
poppler-utils (para pdftotext y pdfinfo)

tesseract-ocr con soporte en español

pandoc para .docx

gnumeric para .xlsx

libxml2-utils para xmllint

📌 Notas
Todos los scripts pueden ejecutarse también en Linux sin Docker si tienes las dependencias.

Se puede montar /home u otras rutas como volumen si se desea escanear el sistema completo.

Para mejorar velocidad, se recomienda evitar subcarpetas profundas y excluir rutas del sistema (/usr, /bin, etc).

📬 Contacto
Desarrollado como parte de una exploración autodidacta de sistemas inteligentes de organización de documentos.

css
Copy
Edit

¿Te gustaría que lo genere automáticamente dentro del contenedor o prefieres guardarlo tú ahora?