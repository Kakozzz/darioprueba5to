# 🎬 CloudStream - Plataforma de Videos en la Nube
### Proyecto: React (SPA) + FastAPI + Amazon Web Services (S3, EC2, RDS)

---

## 📌 1. Descripción y Arquitectura del Sistema

Esta plataforma es una aplicación web tipo **Single Page Application (SPA)** de streaming y publicación de videos construida con una arquitectura desacoplada y nativa de la nube en **Amazon Web Services (AWS)**:

- **Frontend:** Single Page Application (SPA) desarrollada con **React 18 + Vite + Tailwind CSS**, compilada y alojada en **Amazon S3** con *Static Website Hosting*.
- **Backend API:** Desarrollado con **FastAPI (Python 3.12)** y desplegado en una instancia **Amazon EC2** con Nginx como proxy inverso y Systemd para alta disponibilidad. Documentación interactiva Swagger disponible en `/docs`.
- **Base de Datos Estructurada:** Instancia de **Amazon RDS** (PostgreSQL o MySQL) para usuarios, metadatos de videos y comentarios.
- **Almacenamiento Multimedia (3 Buckets de Amazon S3):**
  1. `Bucket 1: Frontend`: Aloja los archivos estáticos de la aplicación React compilada (`dist/`).
  2. `Bucket 2: Videos`: Almacena exclusivamente videos en formato `.mp4` (máx. 100 MB).
  3. `Bucket 3: Miniaturas`: Almacena imágenes de portada en formato `.jpg`, `.jpeg` o `.png`.
- **Seguridad e Integración:** Conexión mediante IAM Roles en EC2 (sin credenciales quemadas en el código), Security Groups dedicados y variables de entorno (`.env`).

```mermaid
flowchart TD
    subgraph Cliente["Navegador Web / Usuario"]
        Browser["SPA en React (Navegador)"]
    end

    subgraph AWS_Cloud["Amazon Web Services (AWS)"]
        subgraph S3_Section["Amazon S3 (Almacenamiento de Objetos)"]
            S3_Front["Bucket 1: S3 Frontend\n(dist/ - SPA Compilada)"]
            S3_Videos["Bucket 2: S3 Videos\n(*.mp4 - max 100MB)"]
            S3_Thumbs["Bucket 3: S3 Miniaturas\n(*.jpg, *.png)"]
        end

        subgraph EC2_Section["Amazon EC2 (Cómputo Backend)"]
            Nginx["Nginx (Puerto 80)\nReverse Proxy"]
            FastAPI["FastAPI / Uvicorn (Puerto 8000)\nEndpoints REST & /docs"]
            IAM["IAM Role\nPermisos S3 automáticos"]
            Nginx --> FastAPI
            IAM -.->|Autorización| FastAPI
        end

        subgraph RDS_Section["Amazon RDS (Base de Datos Relacional)"]
            RDS[("Amazon RDS\nPostgreSQL / MySQL\nUsuarios, Videos, Comentarios")]
        end
    end

    Browser -->|1. Carga SPA (HTML/JS/CSS)| S3_Front
    Browser -->|2. Peticiones REST / Login / CRUD| Nginx
    Browser -->|3. Streaming de Video Directo| S3_Videos
    Browser -->|4. Descarga de Miniaturas| S3_Thumbs
    FastAPI -->|5. Consultas SQL ORM| RDS
    FastAPI -->|6. Subida de Archivos / Presigned URLs| S3_Videos
    FastAPI -->|6. Subida de Archivos / Presigned URLs| S3_Thumbs
```

---

## 🚀 2. Páginas de la SPA (Frontend)

La aplicación implementa exactamente las 4 páginas especificadas:

| Página | Ruta | Funcionalidades |
| :--- | :--- | :--- |
| **Página 1: Registro / Login** | `/auth` | Formulario interactivo para crear una cuenta (Nombre, Correo, Contraseña) e iniciar sesión con validación de credenciales y generación de JWT. |
| **Página 2: Principal** | `/` | Catálogo dinámico con cuadrícula de videos obtenidos desde FastAPI. Muestra miniatura, título, usuario que publicó, vistas y fecha. Incluye buscador en tiempo real. |
| **Página 3: Reproductor** | `/video/:id` | Reproductor de video HTML5 para MP4, título, descripción, autor, contador de vistas interactivo (+1 al reproducir), sección de comentarios y barra lateral de videos recomendados cargados dinámicamente desde la API. |
| **Página 4: Perfil de Usuario** | `/profile/:id` | Información básica del usuario, contador de videos publicados, lista de videos subidos. Permite **publicar videos**, **consultar**, **actualizar (editar)** y **eliminar** videos. |

---

## 🛠️ 3. Endpoints de la API FastAPI

La API cumple con todos los métodos y rutas requeridos (documentación Swagger disponible en `/docs`):

### 👤 Usuarios
- `POST /users`: Registra un nuevo usuario (`name`, `email`, `password`). Almacena la contraseña con salting y hash seguro PBKDF2-SHA256.
- `POST /login`: Autentica al usuario y devuelve el token de acceso JWT y datos de sesión.
- `GET /users/{id}`: Obtiene el perfil de un usuario y la cantidad de videos publicados.
- `GET /users/{id}/videos`: Obtiene la lista de videos subidos por un usuario (para la Página 4 de Perfil).
- `GET /users/me`: Obtiene el usuario autenticado actualmente mediante Bearer Token.

### 🎥 Videos
- `POST /videos`: Registra un video mediante JSON (`title`, `description`, `video_url`, `thumbnail_url`, `user_id`).
- `POST /videos/upload`: Permite subir directamente los archivos `.mp4` y `.jpg/.png` como `multipart/form-data`. La API los sube a sus respectivos buckets de S3 y guarda el registro en la BD.
- `GET /videos`: Lista todos los videos almacenados (soporta filtro `?search=...`).
- `GET /videos/{id}`: Detalle del video, autor, lista de comentarios y videos recomendados.
- `PUT /videos/{id}`: Actualiza título, descripción o miniatura del video.
- `DELETE /videos/{id}`: Elimina el video y sus comentarios asociados de forma segura.
- `POST /videos/{id}/view`: Incrementa en +1 el contador de vistas al iniciar la reproducción.
- `GET /videos/{id}/recommended`: Retorna lista de videos recomendados distintos al actual.

### 💬 Comentarios
- `POST /videos/{id}/comments`: Publica un comentario (`content`, `user_id`).
- `GET /videos/{id}/comments`: Lista los comentarios de un video en orden cronológico descendente.
- `DELETE /comments/{comment_id}`: Elimina un comentario específico.

### 🩺 Sistema
- `GET /health`: Healthcheck para balanceadores de carga y monitoreo de EC2.
- `GET /docs`: Documentación Swagger UI interactiva.

---

## 🗄️ 4. Modelos de Base de Datos (Amazon RDS)

Entidades implementadas en SQLAlchemy (PostgreSQL / MySQL):

```mermaid
erDiagram
    USER ||--o{ VIDEO : "publica"
    USER ||--o{ COMMENT : "escribe"
    VIDEO ||--o{ COMMENT : "contiene"

    USER {
        int id PK
        string name
        string email UK
        string password_hash
        datetime created_at
    }

    VIDEO {
        int id PK
        string title
        text description
        string video_url
        string thumbnail_url
        int views
        int user_id FK
        datetime created_at
    }

    COMMENT {
        int id PK
        text content
        int user_id FK
        int video_id FK
        datetime created_at
    }
```

---

## ☁️ 5. Guía de Despliegue en AWS (Paso a Paso)

Esta sección detalla los pasos para desplegar en tu cuenta de AWS.

### Paso 1: Crear los 3 Buckets en Amazon S3

1. **Bucket 1: Frontend (SPA)**
   - Nombre sugerido: `mi-plataforma-video-frontend-tu-nombre`
   - Región: `us-east-1`
   - En la pestaña **Propiedades (Properties)**:
     - Habilitar **Alojamiento de sitios web estáticos (Static website hosting)**.
     - Documento de índice: `index.html`.
     - Documento de error: `index.html` (necesario para SPA React Router).
   - En la pestaña **Permisos (Permissions)**:
     - Desactivar *Bloquear acceso público (Block Public Access)*.
     - Agregar la siguiente **Política de Bucket (Bucket Policy)**:
     ```json
     {
       "Version": "2012-10-17",
       "Statement": [
         {
           "Sid": "PublicReadGetObject",
           "Effect": "Allow",
           "Principal": "*",
           "Action": "s3:GetObject",
           "Resource": "arn:aws:s3:::NOMBRE_DE_TU_BUCKET_FRONTEND/*"
         }
       ]
     }
     ```

2. **Bucket 2: Videos**
   - Nombre sugerido: `mi-plataforma-videos-storage-tu-nombre`
   - Configuración de CORS (Pestaña Permisos -> Cross-origin resource sharing):
     ```json
     [
       {
         "AllowedHeaders": ["*"],
         "AllowedMethods": ["GET", "PUT", "POST", "HEAD"],
         "AllowedOrigins": ["*"],
         "ExposeHeaders": ["ETag"]
       }
     ]
     ```

3. **Bucket 3: Miniaturas**
   - Nombre sugerido: `mi-plataforma-miniaturas-storage-tu-nombre`
   - Misma configuración de CORS del Bucket 2.

---

### Paso 2: Crear la Base de Datos en Amazon RDS

1. Ir a la consola de **Amazon RDS** -> **Crear base de datos (Create database)**.
2. Motor: **PostgreSQL** (versión 15 o 16) o **MySQL** (versión 8.0).
3. Plantilla: **Capa gratuita (Free Tier)**.
4. Identificador: `videodb-instance`.
5. Usuario maestro: `postgres` (o `admin`).
6. Contraseña maestra: Definir una contraseña segura (ej. `PasswordSeguro123!`).
7. Conectividad:
   - VPC: Predeterminada.
   - Acceso público: **Sí** (para facilitar pruebas iniciales) o **No** si la instancia EC2 está en la misma VPC.
8. En **Configuración adicional**:
   - Nombre de la base de datos inicial: `videodb`.
9. En el **Security Group** de RDS:
   - Permitir regla de entrada (Inbound Rule) en el puerto `5432` (PostgreSQL) o `3306` (MySQL) desde la IP o Security Group de la instancia EC2.
10. Una vez creada, copia el **Endpoint** de la base de datos (ej: `videodb-instance.c123456789.us-east-1.rds.amazonaws.com`).

---

### Paso 3: Configurar IAM Role para la Instancia EC2

Para cumplir con la directiva **"No se deberán incluir credenciales en el código"**:
1. Ir a la consola de **IAM** -> **Roles** -> **Crear rol**.
2. Tipo de entidad de confianza: **Servicio de AWS (AWS Service)** -> **EC2**.
3. Permisos: Asignar la política gestionada `AmazonS3FullAccess` (o crear una política con acceso a los buckets de Videos y Miniaturas).
4. Nombre del rol: `EC2-VideoPlatform-S3-Role`.
5. Asignar este rol a tu instancia EC2 (Acciones -> Seguridad -> Modificar rol de IAM).
*De este modo, `boto3` detectará automáticamente las credenciales temporales sin necesidad de access keys.*

---

### Paso 4: Desplegar FastAPI en Amazon EC2

1. Lanzar una instancia EC2:
   - AMI: **Amazon Linux 2023** o **Ubuntu 24.04 LTS** (t2.micro / t3.micro).
   - Security Group:
     - Puerto `22` (SSH).
     - Puerto `80` (HTTP).
     - Puerto `8000` (FastAPI).
   - Asignar el IAM Role creado en el Paso 3.
2. Conectarse por SSH a la instancia EC2:
   ```bash
   ssh -i "tu-llave.pem" ec2-user@TU_EC2_IP_PUBLICA
   ```
3. Clonar el repositorio del proyecto:
   ```bash
   git clone https://github.com/TU_USUARIO/TU_REPOSITORIO.git
   cd TU_REPOSITORIO/backend
   ```
4. Configurar el archivo `.env`:
   ```bash
   cp .env.example .env
   nano .env
   ```
   Configura las variables con tus datos reales:
   ```ini
   DATABASE_URL=postgresql://postgres:TuPasswordSeguro123@videodb-instance.c123456789.us-east-1.rds.amazonaws.com:5432/videodb
   SECRET_KEY=clave-secreta-produccion-uide-2026
   AWS_REGION=us-east-1
   S3_BUCKET_VIDEOS=mi-plataforma-videos-storage-tu-nombre
   S3_BUCKET_THUMBNAILS=mi-plataforma-miniaturas-storage-tu-nombre
   ```
5. Ejecutar el script automatizado de despliegue:
   ```bash
   chmod +x deploy_ec2.sh
   ./deploy_ec2.sh
   ```
6. Verificar el estado del servicio:
   ```bash
   sudo systemctl status videoplatform
   ```
7. Probar la API en tu navegador:
   - Swagger Docs: `http://TU_EC2_IP_PUBLICA/docs` (o puerto 8000).

---

### Paso 5: Compilar y Desplegar la SPA React en S3 Frontend

1. En tu máquina local, configurar la variable de la URL de la API apuntando a tu EC2:
   En `frontend/.env.production`:
   ```ini
   VITE_API_URL=http://TU_EC2_IP_PUBLICA
   ```
2. Compilar la aplicación React:
   ```bash
   cd frontend
   npm install
   npm run build
   ```
   Esto generará la carpeta `dist/`.
3. Subir **únicamente el contenido de `dist/`** al Bucket 1 de S3:
   - **Opción A (Con AWS CLI):**
     ```bash
     aws s3 sync dist/ s3://NOMBRE_DE_TU_BUCKET_FRONTEND --delete
     ```
   - **Opción B (Con script incluido):**
     ```bash
     # En PowerShell:
     .\deploy_s3_frontend.ps1 -BucketName "NOMBRE_DE_TU_BUCKET_FRONTEND" -ApiUrl "http://TU_EC2_IP_PUBLICA"
     ```
   - **Opción C (Manual desde la consola web de AWS):**
     - Abrir la consola de S3 -> Entrar a tu bucket de Frontend.
     - Dar clic en **Cargar (Upload)**.
     - Seleccionar y arrastrar todos los archivos y carpetas que están **dentro** de `frontend/dist/` (`index.html`, `assets/`, etc.).
     - *No subir node_modules, src ni package.json.*
4. Acceder a la URL pública del sitio web estático:
   `http://NOMBRE_DE_TU_BUCKET_FRONTEND.s3-website-us-east-1.amazonaws.com`

---

## 💻 6. Ejecución y Pruebas en Entorno Local (Sin AWS)

El proyecto está diseñado para funcionar al 100% de manera inmediata en entorno local para desarrollo y evaluación:

### 1. Iniciar Backend (FastAPI):
```powershell
# En PowerShell (desde la raíz del proyecto):
.\backend\.venv\Scripts\python.exe backend\run_local.py
```
- API Docs: [http://localhost:8000/docs](http://localhost:8000/docs)
- Base de datos local SQLite precargada con datos iniciales (3 usuarios, 6 videos, 4 comentarios).

### 2. Iniciar Frontend (React + Vite):
```powershell
cd frontend
npm run dev
```
- SPA interactiva: [http://localhost:5173](http://localhost:5173)

### 3. Ejecutar Pruebas Automatizadas (Pytest):
```powershell
$env:PYTHONPATH="backend"
.\backend\.venv\Scripts\python.exe -m pytest backend/tests/test_api.py -v
```

---

## 📋 7. Lista de Chequeo de Entregables

- [x] Repositorio estructurado con frontend, backend, docker y scripts.
- [x] API FastAPI completa con `/users`, `/login`, `/videos`, `/comments` y `/docs`.
- [x] SPA React con las 4 páginas requeridas y diseño responsive.
- [x] Soporte para Amazon S3 (Bucket Frontend, Bucket Videos, Bucket Miniaturas).
- [x] Soporte para Amazon RDS (PostgreSQL / MySQL) mediante SQLAlchemy.
- [x] Soporte para IAM Roles en Amazon EC2 (sin credenciales quemadas en el código).
- [x] Validación de restricciones (videos solo MP4 máx. 100MB; miniaturas JPG/JPEG/PNG).
- [x] Guías paso a paso para evidencia de EC2, RDS y los 3 Buckets S3.
