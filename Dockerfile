# Imagen base liviana con Python
FROM python:3.12-slim

WORKDIR /app

# Instalar dependencias primero (mejor caché de capas)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# El monolito sirve TANTO la API como el frontend (static/)
COPY app.py .
COPY static/ static/

# Cloud Run inyecta el puerto en $PORT (por defecto 8080)
ENV PORT=8080
EXPOSE 8080

# 1 worker a propósito: con varios, cada uno tiene SUS PROPIAS métricas en
# memoria y Prometheus haría scrape a uno u otro al azar, dando números
# inconsistentes. Para el lab, 1 worker mantiene las métricas correctas.
# Shell form para que $PORT se expanda (Cloud Run lo define en runtime).
CMD exec gunicorn --bind 0.0.0.0:$PORT --workers 1 app:app
