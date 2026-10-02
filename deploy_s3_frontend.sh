#!/bin/bash
# ========================================================
# Script para compilar y desplegar la SPA en Amazon S3 Frontend
# Uso: ./deploy_s3_frontend.sh <NOMBRE_DEL_BUCKET> <URL_API_FASTAPI>
# ========================================================

set -e

BUCKET_NAME="$1"
API_URL="${2:-http://localhost:8000}"

if [ -z "$BUCKET_NAME" ]; then
    echo "Uso: ./deploy_s3_frontend.sh <NOMBRE_DEL_BUCKET_S3_FRONTEND> [URL_DE_FASTAPI]"
    echo "Ejemplo: ./deploy_s3_frontend.sh mi-video-spa-bucket http://54.210.123.45:8000"
    exit 1
fi

echo "=========================================="
echo "Compilando y desplegando SPA en S3..."
echo "Bucket S3: $BUCKET_NAME"
echo "API URL:   $API_URL"
echo "=========================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/frontend"

# Exportar URL de FastAPI para que Vite la embeba en el build
export VITE_API_URL="$API_URL"

# Instalar dependencias si faltan
if [ ! -d "node_modules" ]; then
    echo "Instalando paquetes npm..."
    npm install
fi

# Compilar
echo "Compilando frontend con Vite (npm run build)..."
npm run build

# Subir a S3
echo "Sincronizando dist/ con s3://$BUCKET_NAME..."
aws s3 sync dist/ "s3://$BUCKET_NAME" --delete

echo "=========================================="
echo "¡Frontend desplegado con exito en Amazon S3!"
echo "URL Website: http://$BUCKET_NAME.s3-website-us-east-1.amazonaws.com"
echo "=========================================="
