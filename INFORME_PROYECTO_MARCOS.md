# 📋 INFORME TÉCNICO Y GUÍA DEL PROYECTO
## Plataforma de Videos en la Nube (AWS + FastAPI + React)

**Estudiante:** Marcos Cumbajin  
**Usuario / Alias:** kakozzz (`kakozzz@uide.edu.ec`)  
**Proyecto:** Plataforma de Video Streaming Cloud  
**Tecnologías:** React 18 (Vite), FastAPI (Python 3.12), Amazon S3, Amazon EC2, Amazon RDS  

---

## 📌 1. ¿Qué se hizo en este proyecto? (Resumen Ejecutivo)

Se desarrolló desde cero una solución integral de plataforma de streaming de videos cumpliendo estrictamente cada uno de los puntos exigidos en la actividad práctica:

1. **Aclaración sobre Docker:** Se eliminó Docker del proyecto porque el enunciado solicita despliegue nativo de **FastAPI en Amazon EC2**, la **SPA en Amazon S3** y la **base de datos en Amazon RDS**. Así el proyecto queda 100% limpio y apegado a lo que el profesor evaluará.
2. **Backend API en FastAPI:** Se construyó una API REST robusta, modular y completamente documentada en Swagger UI (`/docs`), con autenticación JWT, hashing seguro de contraseñas (PBKDF2-SHA256) y validaciones de formatos y pesos de archivos.
3. **Frontend SPA en React:** Se diseñó una interfaz moderna, estética y personalizada para **Marcos Cumbajin (@kakozzz)** con modo oscuro, tags de categorías interactivas, reproductor con botones de like/compartir, sistema de comentarios dinámico y gestión total de videos en el perfil.
4. **Almacenamiento S3 y Base de Datos RDS:** Se estructuró el código para conectarse a los 3 buckets de S3 y a la base de datos relacional de RDS sin quemar contraseñas ni llaves en el código, usando variables de entorno y soporte nativo para **IAM Roles**.

---

## 🏛️ 2. Arquitectura de la Solución

```text
                                   +------------------------------------------+
                                   |      NAVEGADOR DEL USUARIO               |
                                   |   (SPA React alojada en S3 Frontend)     |
                                   +--------------------+---------------------+
                                                        |
                         +------------------------------+------------------------------+
                         |                              |                              |
                         v                              v                              v
       +----------------------------------+   +-------------------+          +-------------------+
       |     BUCKET 1: S3 FRONTEND        |   | BUCKET 2: VIDEOS  |          | BUCKET 3: PORTADAS|
       |  Archivos compilados (dist/)     |   | Archivos *.mp4    |          | Archivos *.jpg    |
       |  Static Website Hosting activo   |   | (Hasta 100 MB)    |          | Archivos *.png    |
       +----------------------------------+   +-------------------+          +-------------------+
                         |                              ^                              ^
                         | Peticiones API REST          | Streaming directo            | Carga de imágenes
                         v                              |                              |
       +------------------------------------------------+------------------------------+
       |                         INSTANCIA AMAZON EC2                                  |
       |                                                                               |
       |   +--------------------------+         +----------------------------------+   |
       |   | NGINX REVERSE PROXY      | ------> | FASTAPI + UVICORN                |   |
       |   | (Escucha en Puerto 80)   |         | (Escucha en Puerto 8000)         |   |
       |   +--------------------------+         | Swagger UI interactiva en /docs  |   |
       |                                        +-----------------+----------------+   |
       |   * IAM Role asignado a EC2                              |                    |
       |     (Acceso a S3 sin llaves quemadas)                    | Conexión Segura    |
       +----------------------------------------------------------+ (SQLAlchemy ORM)   |
                                                                  v                    |
                                            +--------------------------------------+   |
                                            |          AMAZON RDS                  |<--+
                                            | (PostgreSQL o MySQL en Capa Gratuita)|
                                            | Tablas: users, videos, comments      |
                                            +--------------------------------------+
```

---

## 📂 3. Estructura de Archivos del Proyecto

```text
streamcloud-kakozzz/
├── backend/
│   ├── app/
│   │   ├── config.py              # Ajustes de entorno, RDS y nombres de buckets S3
│   │   ├── database.py            # Conexión SQLAlchemy con soporte para SQLite y RDS
│   │   ├── models.py              # Modelos: User, Video y Comment
│   │   ├── schemas.py             # Validaciones Pydantic v2 (DTOs)
│   │   ├── security.py            # Hash seguro PBKDF2 y tokens JWT
│   │   ├── s3.py                  # Lógica de subida a Amazon S3 y validación de 100MB
│   │   ├── seed.py                # Inicialización con datos de Marcos Cumbajin (@kakozzz)
│   │   ├── main.py                # App FastAPI, CORS, healthcheck y Swagger /docs
│   │   └── routers/
│   │       ├── users.py           # Rutas: POST /users, POST /login, GET /users/{id}
│   │       ├── videos.py          # Rutas: CRUD de videos, vistas y recomendados
│   │       └── comments.py        # Rutas: POST y GET /videos/{id}/comments
│   ├── tests/
│   │   └── test_api.py            # Pruebas automatizadas con pytest (100% pasando)
│   ├── deploy_ec2.sh              # Script automático de instalación en EC2 (Linux)
│   ├── videoplatform.service      # Servicio Systemd para mantener la API viva en EC2
│   ├── nginx.conf                 # Configuración de Nginx en EC2 (Puerto 80 -> 8000)
│   ├── requirements.txt           # Librerías de Python necesarias
│   ├── run_local.py               # Script para encender la API localmente
│   └── .env.example               # Ejemplo de variables de entorno para RDS y S3
├── frontend/
│   ├── src/
│   │   ├── pages/
│   │   │   ├── AuthPage.jsx       # Pág 1: Registro y Login con autorelleno de Marcos
│   │   │   ├── HomePage.jsx       # Pág 2: Catálogo principal con categorías y buscador
│   │   │   ├── PlayerPage.jsx     # Pág 3: Reproductor MP4, likes, comentarios y recomendados
│   │   │   └── ProfilePage.jsx    # Pág 4: Perfil de Marcos (@kakozzz), stats y CRUD videos
│   │   ├── components/
│   │   │   ├── Navbar.jsx         # Barra estética con logo, buscador y avatar
│   │   │   ├── VideoCard.jsx      # Tarjeta con portada, vistas, fecha y autor
│   │   │   ├── UploadVideoModal.jsx # Modal para subir MP4 (máx 100MB) y portadas a S3
│   │   │   └── EditVideoModal.jsx # Modal para actualizar videos existentes
│   │   ├── context/AuthContext.jsx# Persistencia de sesión JWT
│   │   └── services/api.js        # Comunicación Fetch con los endpoints de FastAPI
│   ├── dist/                      # Carpeta compilada lista para subir a S3 Frontend
│   ├── package.json               # Dependencias de React, Vite y Tailwind CSS
│   └── vite.config.js             # Configuración del compilador Vite
├── deploy_s3_frontend.ps1         # Script en PowerShell para subir dist/ al Bucket 1 de S3
├── deploy_s3_frontend.sh          # Script en Bash para subir dist/ al Bucket 1 de S3
├── .gitignore                     # Protege contraseñas, node_modules y bases locales
├── README.md                      # Manual completo del proyecto
└── INFORME_PROYECTO_MARCOS.md     # Este informe detallado
```

---

## 🛠️ 4. Detalle de los Requerimientos Cumplidos

### 1. Páginas de la SPA en React
- **Página 1 (Registro / Login):** Permite crear cuenta o iniciar sesión con nombre, correo y contraseña. Incluye un botón para autocompletar rápidamente con la cuenta de **Marcos Cumbajin** (`kakozzz@uide.edu.ec` / `password123`).
- **Página 2 (Principal):** Catálogo de videos obtenidos dinámicamente desde FastAPI con miniatura, título, usuario, vistas y fecha. Además incluye filtro de categorías temáticas de Cloud y buscador.
- **Página 3 (Reproductor):** Reproductor HTML5 funcional de videos MP4, descripción completa, autor con insignia verificada, contador de vistas interactivo (+1 al reproducir), caja de comentarios en tiempo real y lista de videos recomendados dinámicos.
- **Página 4 (Perfil del usuario):** Muestra el perfil de **Marcos Cumbajin (@kakozzz)**, total de videos subidos, vistas acumuladas, botón para **Publicar videos** (con selector de archivo MP4 de máx 100MB y portada JPG/PNG), botón para **Editar** información del video y botón para **Eliminar** videos.

### 2. Almacenamiento en Amazon S3
- **Bucket 1 (Frontend):** Se compila con `npm run build` generando la carpeta `frontend/dist/`. Solo el contenido de esta carpeta se sube a S3.
- **Bucket 2 (Videos):** Restringido estrictamente a formato `.mp4` y tamaño máximo de 100 MB.
- **Bucket 3 (Miniaturas):** Restringido a formatos `.jpg`, `.jpeg` y `.png`.

### 3. API FastAPI en EC2
- Cumple con todos los endpoints obligatorios:
  - `POST /users`, `POST /login`, `GET /users/{id}`, `GET /users/{id}/videos`
  - `POST /videos`, `POST /videos/upload`, `GET /videos`, `GET /videos/{id}`, `PUT /videos/{id}`, `DELETE /videos/{id}`, `POST /videos/{id}/view`, `GET /videos/{id}/recommended`
  - `POST /videos/{id}/comments`, `GET /videos/{id}/comments`
- Documentación OpenAPI automática en `/docs` y `/redoc`.
- Endpoint de verificación de salud en `/health`.

### 4. Base de Datos en Amazon RDS
- Modelado con **SQLAlchemy 2.0**.
- Entidades creadas: `User` (id, name, email, password_hash, created_at), `Video` (id, title, description, video_url, thumbnail_url, views, user_id, created_at), `Comment` (id, content, user_id, video_id, created_at).
- Compatible con **PostgreSQL** y **MySQL** en RDS cambiando únicamente la variable `DATABASE_URL` en `.env`.

---

## 🧪 5. Cómo Probar la Aplicación en Local

### 1. Iniciar el Backend (FastAPI):
En una terminal:
```powershell
.\backend\.venv\Scripts\python.exe backend\run_local.py
```
- Swagger Docs: [http://localhost:8000/docs](http://localhost:8000/docs)
- Healthcheck: [http://localhost:8000/health](http://localhost:8000/health)

### 2. Iniciar el Frontend (React):
En otra terminal:
```powershell
cd frontend
npm.cmd run dev
```
- Aplicación web: [http://localhost:5173](http://localhost:5173)

### 3. Ejecutar las Pruebas Unitarias Automatizadas:
```powershell
$env:PYTHONPATH="backend"
.\backend\.venv\Scripts\python.exe -m pytest backend/tests/test_api.py -v
```

---

## ☁️ 6. Tu Guía para cuando hagas la Parte de AWS

Cuando entres a la consola de AWS a desplegar, sigue estos pasos sencillos:

### Paso 1: Crear los 3 Buckets en S3
1. **Bucket 1 (Frontend):**
   - Habilita *Static website hosting* con `index.html`.
   - Agrega la política de bucket pública para lectura (`s3:GetObject`).
2. **Bucket 2 (Videos) y Bucket 3 (Miniaturas):**
   - Configura las reglas de CORS en la pestaña *Permissions* para permitir peticiones `GET` y `PUT` desde cualquier origen.

### Paso 2: Crear la Base de Datos en RDS
1. Crea una base de datos **PostgreSQL** o **MySQL** en la capa gratuita (Free Tier).
2. En el Security Group de RDS, agrega una regla de entrada (Inbound) en el puerto `5432` (PostgreSQL) o `3306` (MySQL) permitiendo tráfico desde tu EC2.
3. Copia el Endpoint que te dé RDS (ej: `videodb.c123.us-east-1.rds.amazonaws.com`).

### Paso 3: Crear la Instancia EC2
1. Lanza una instancia EC2 (Ubuntu 24.04 o Amazon Linux 2023, tipo `t2.micro` o `t3.micro`).
2. En Security Group, abre los puertos `22` (SSH), `80` (HTTP) y `8000` (FastAPI).
3. **IAM Role:** Crea un rol de IAM con permisos de S3 (`AmazonS3FullAccess`) y asígnalo a tu EC2. Así la API podrá subir videos y miniaturas a S3 sin colocar contraseñas ni llaves en el código.

### Paso 4: Desplegar FastAPI en tu EC2
1. Conéctate a tu EC2 por SSH:
   ```bash
   ssh -i "tu-clave.pem" ec2-user@TU_IP_PUBLICA
   ```
2. Clona tu repositorio de GitHub y entra a la carpeta `backend`:
   ```bash
   git clone https://github.com/TU_USUARIO/TU_REPO.git
   cd TU_REPO/backend
   ```
3. Edita el archivo `.env`:
   ```ini
   DATABASE_URL=postgresql://postgres:TuPassword@TU_ENDPOINT_RDS:5432/videodb
   SECRET_KEY=clave-secreta-marcos-uide-2026
   AWS_REGION=us-east-1
   S3_BUCKET_VIDEOS=nombre-de-tu-bucket-videos
   S3_BUCKET_THUMBNAILS=nombre-de-tu-bucket-miniaturas
   ```
4. Ejecuta el script de instalación automática:
   ```bash
   chmod +x deploy_ec2.sh
   ./deploy_ec2.sh
   ```
5. ¡Listo! Tu API estará activa en `http://TU_IP_PUBLICA/docs`.

### Paso 5: Desplegar el Frontend en S3
1. En tu computadora local, edita `frontend/.env.production` con la IP de tu EC2:
   ```ini
   VITE_API_URL=http://TU_IP_PUBLICA_EC2
   ```
2. Compila el frontend:
   ```bash
   cd frontend
   npm run build
   ```
3. Sube la carpeta `frontend/dist/` a tu Bucket 1 de S3:
   - Con el script: `.\deploy_s3_frontend.ps1 -BucketName "tu-bucket-frontend" -ApiUrl "http://TU_IP_PUBLICA_EC2"`
   - O manualmente: entra a la consola de S3 en tu Bucket 1 y arrastra todo lo que está dentro de `frontend/dist/`.

---

## 🎬 7. Guion Rápido para tu Video Explicativo

Cuando grabes el video para el profesor, puedes mostrar:
1. **Presentación:** Marcos Cumbajin (@kakozzz), proyecto de plataforma de videos en la nube para UIDE.
2. **Arquitectura:** Explicar cómo interactúan los 3 buckets S3, EC2 y RDS sin credenciales quemadas en el código.
3. **Prueba de Funcionamiento:**
   - Registro e inicio de sesión con tu usuario Marcos Cumbajin.
   - Catálogo de videos y filtro por categorías.
   - Reproducción de video, incremento de vistas (+1) y comentarios.
   - Perfil de usuario: publicación de video (demostrando restricción de MP4 y 100MB), edición y eliminación.
4. **Evidencias de AWS:** Mostrar consola de S3 (los 3 buckets), consola de EC2 (instancia corriendo) y consola de RDS (base de datos activa).
