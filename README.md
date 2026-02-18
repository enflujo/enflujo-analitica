# Sitios Analítica

![Despliegue](https://github.com/enflujo/enflujo-analitica/actions/workflows/despliegue.yml/badge.svg)


Usamos la aplicación [Umami](https://umami.is/docs/about) que funciona como un reemplazo de Google Analytics. Umami es gratis, open-source, liviana y tiene un énfasis en la privacidad de los usuarios que visitan las páginas.

Para poder usarla se debe instalar en un servidor propio.

Este repositorio contiene lo necesario para instalar la aplicación en un servidor:

## Instalación

### Clonar

En el servidor:

```bash
git clone https://github.com/enflujo/enflujo-analitica.git
```

### Claves para contenedores

Hacer una copia del archivo `.env.ejemplo` y llamarlo `.env` (o crear uno con las siguientes variables).

```bash
# Nombre de la base de datos en Postgres
BD_NOMBRE=...
# Usuario dueño de la base de datos
BD_USUARIO=...
# Clave para conectarse a Postgres
BD_CLAVE=...
# Una llave única para Umami,
# puede ser generada con UUID4 https://www.uuidgenerator.net/version4
SALT=...
# El puerto por donde corre la instancia de Umami (NodeJS)
PUERTO=...

# Respaldos remotos
RESPALDO_USUARIO_REMOTO=...   # usuario en el servidor remoto
RESPALDO_SERVIDOR_REMOTO=...  # dominio o IP del servidor remoto
RESPALDO_DIR_REMOTO=...       # ruta absoluta donde se guardan los respaldos en el servidor remoto
RESPALDO_LLAVE_SSH=...        # ruta absoluta a la llave SSH privada en este servidor (ej: /home/usuario/.ssh/id_ed25519_respaldos)
```

### Iniciar con Docker

Umami es una aplicación de Node y se puede instalar directamente clonando el código desde su [repositorio](https://github.com/umami-software/umami). En nuestro caso vamos a usar Docker para no depender de una base de datos administrada en el servidor.

Ver el archivo `docker-compose.yml` para saber qué versión de Postgres y Umami se están instalando.

Teniendo Docker y Docker Compose instalados en el servidor, simplemente se puede iniciar con:

```bash
# Ir primero a la carpeta que se acaba de clonar
cd enflujo-analitica

# Descargar e iniciar contenedores
docker compose up -d
```

## Actualizar Umami

Desde este repositorio tenemos configurado un GitHub Action llamado [despliegue](./.github/workflows/despliegue.yml) que se encarga de mandarle las siguientes instrucciones al servidor:

1. Conectarse al servidor usando las credenciales guardadas en los "Secrets" del repositorio.
2. Descargar la versión más reciente de este repositorio.
3. Actualizar la imagen que usa Docker para Umami.
4. Reiniciar contenedores.

Esta acción sólo se activa cuando hay cambios en este repositorio. Si se quiere actualizar Umami sin hacer cambios a los archivos de configuración, simplemente cambiar algo en el archivo `version.md` para activar el GitHub Action.

## Respaldos

El script `respaldar.sh` genera un volcado comprimido de la base de datos y lo sincroniza con un servidor remoto. Se ejecuta automáticamente todos los días a las 3am mediante un cron job.

### Dónde quedan los respaldos

| Tipo | Ubicación | Retención |
|---|---|---|
| **Parciales** (locales) | `./respaldos/` en este servidor | Últimos 30 días |
| **Completos** (histórico) | Servidor remoto en `$RESPALDO_DIR_REMOTO` | Todo el histórico, nunca se borran |

Los archivos tienen el formato: `enflujo-analitica_YYYY-MM-DD_HH-MM.sql.gz`

El log de cada ejecución queda en `./respaldos/respaldos.log`.

### Configurar respaldos en un servidor nuevo

1. Generar llave SSH para conectarse al servidor remoto:
```bash
ssh-keygen -t ed25519 -C "respaldos" -f ~/.ssh/id_ed25519_respaldos -N ""
```

2. Copiar la llave pública al servidor remoto:
```bash
ssh-copy-id -i ~/.ssh/id_ed25519_respaldos.pub usuario@servidor-remoto
```

3. Crear la carpeta de destino en el servidor remoto:
```bash
ssh -i ~/.ssh/id_ed25519_respaldos usuario@servidor-remoto "mkdir -p /ruta/respaldos"
```

4. Agregar las variables `RESPALDO_*` al `.env` de este servidor.

5. Dar permisos de ejecución al script y configurar el cron:
```bash
chmod +x respaldar.sh
crontab -e
# Agregar: 0 3 * * * /ruta/absoluta/al/proyecto/respaldar.sh
```
