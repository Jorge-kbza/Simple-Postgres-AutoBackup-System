# 🐘 PostgreSQL Backup System (Docker + Rclone)

Sistema automatizado de backups para PostgreSQL usando Docker.  
Genera copias periódicas, las guarda localmente y las sincroniza con Google Drive.

---

## 🚀 Características

- Backups automáticos con `pg_dump + gzip`
- Ejecución cada 10 minutos (cron)
- Retención local: últimos 7 backups
- Sincronización a Google Drive con rclone
- Retención remota: últimos 7 días
- Arquitectura con Docker Compose
- Configuración por variables de entorno

---

## 🧱 Arquitectura

```
PostgreSQL Container
↓
Backup Container (cron + pg_dump)
↓
├── /backups (local → últimos 7 archivos)
└── Google Drive (→ últimos 7 días)
```

---

## ⚙️ Requisitos

- Docker
- Docker Compose
- Cuenta de Google Drive
- rclone configurado

---

## 📦 Instalación

### 1. Clonar el repositorio

```env
git clone https://github.com/Jorge-kbza/Simple-Postgres-AutoBackup-System.git
```

---

### 2. Configurar variables de entorno

cp .env.example .env

Editar `.env`:

```env
POSTGRES_HOST=postgres
POSTGRES_DB=change_me
POSTGRES_USER=change_me
POSTGRES_PASSWORD=change_me


RCLONE_REMOTE=drive
RCLONE_PATH=backup/postgres
```

---

### 3. Configurar rclone

rclone config

* Crear remote: `drive`
* Autorizar acceso a Google Drive


---

### 4. Levantar el sistema

```env
docker-compose up -d --build
```

---

## 🧠 Funcionamiento

### Backups locales

* Se genera un backup cada X minutos (Segun el crontab)
* Formato:

  * backup_<db>_YYYY-MM-DD_HH-MM.sql.gz

* Se conservan solo los últimos **7 backups**

---

### ☁️ Backups en Google Drive

* Subida automática con `rclone copy`

* Se eliminan backups con más de **7 días**

---

## 🧹 Política de retención

| Ubicación        | Retención         |
| ---------------- | ----------------- |
| Local (/backups) | Últimos 7 backups |
| Google Drive     | Últimos 7 días    |

---

## 📁 Estructura del proyecto

```env
.
├── backup.sh
├── Dockerfile
├── docker-compose.yml
├── crontab
├── .env.example
└── README.md
```

---

## 🔄 Restauración

### Descargar backup

```env
rclone copy drive:/backup/postgres ./restore
```

### Descomprimir

```env
gunzip backup.sql.gz
```

### Restaurar en PostgreSQL

```env
psql -h localhost -U admin -d testdb < backup.sql
```

---

## 🗒️ Notas

* Diseñado para entornos Docker (homelab / dev)
* Backup container independiente del PostgreSQL
* No usa `rclone sync` para evitar pérdida de histórico

---