param (
    [Parameter(Mandatory=$true)]
    [string]$BucketName,

    [Parameter(Mandatory=$false)]
    [string]$ApiUrl = "http://localhost:8000"
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Compilando y Desplegando SPA en S3 Frontend" -ForegroundColor Cyan
Write-Host "Bucket S3: $BucketName" -ForegroundColor Yellow
Write-Host "API URL:   $ApiUrl" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Configurar variable de entorno para la compilación de Vite
$env:VITE_API_URL = $ApiUrl

# 2. Entrar al directorio frontend
Set-Location -Path "$PSScriptRoot\frontend"

# 3. Instalar dependencias si no existen
if (-not (Test-Path "node_modules")) {
    Write-Host "Instalando paquetes npm..." -ForegroundColor Green
    npm.cmd install
}

# 4. Compilar proyecto (genera dist/)
Write-Host "Compilando SPA con Vite (npm run build)..." -ForegroundColor Green
npm.cmd run build

if (-not (Test-Path "dist\index.html")) {
    Write-Host "Error: No se encontró dist/index.html tras la compilación." -ForegroundColor Red
    exit 1
}

# 5. Subir a S3
Write-Host "Subiendo contenido de dist/ al bucket s3://$BucketName..." -ForegroundColor Green
aws s3 sync dist/ "s3://$BucketName" --delete

Write-Host "==========================================" -ForegroundColor Green
Write-Host "¡Despliegue de Frontend exitoso!" -ForegroundColor Green
Write-Host "URL de tu SPA: http://$BucketName.s3-website-us-east-1.amazonaws.com" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Green
