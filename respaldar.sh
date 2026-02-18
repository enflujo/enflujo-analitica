#!/bin/bash
set -euo pipefail

# ─── Cargar variables de entorno ──────────────────────────────────────────────
DIR_PROYECTO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_ARCHIVO="${DIR_PROYECTO}/.env"

if [ ! -f "${ENV_ARCHIVO}" ]; then
  echo "ERROR: No se encontró el archivo .env en ${DIR_PROYECTO}"
  exit 1
fi

# shellcheck source=.env
source "${ENV_ARCHIVO}"

# ─── Configuración ────────────────────────────────────────────────────────────
CONTENEDOR_BD="analitica-bd"
DIR_RESPALDOS="${DIR_PROYECTO}/respaldos"
ARCHIVO_LOG="${DIR_RESPALDOS}/respaldos.log"
DIAS_RETENCION_LOCAL=30
# ──────────────────────────────────────────────────────────────────────────────

FECHA=$(date +%Y-%m-%d_%H-%M)
ARCHIVO_RESPALDO="${DIR_RESPALDOS}/enflujo-analitica_${FECHA}.sql.gz"

mkdir -p "${DIR_RESPALDOS}"

registrar() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${ARCHIVO_LOG}"
}

registrar "=== Iniciando respaldo ==="

# Verificar que el contenedor de BD está corriendo
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTENEDOR_BD}$"; then
  registrar "ERROR: El contenedor ${CONTENEDOR_BD} no está corriendo."
  exit 1
fi

# Crear volcado comprimido de la base de datos
registrar "Creando volcado de la base de datos..."
if docker exec "${CONTENEDOR_BD}" pg_dump -U "${BD_USUARIO}" "${BD_NOMBRE}" | gzip > "${ARCHIVO_RESPALDO}"; then
  TAMANIO=$(du -sh "${ARCHIVO_RESPALDO}" | cut -f1)
  registrar "Volcado creado: $(basename ${ARCHIVO_RESPALDO}) (${TAMANIO})"
else
  registrar "ERROR: Falló el volcado de la base de datos. Abortando."
  rm -f "${ARCHIVO_RESPALDO}"
  exit 1
fi

# Sincronizar con servidor remoto (conserva historial completo allá)
registrar "Sincronizando con servidor remoto ${RESPALDO_SERVIDOR_REMOTO}..."
if rsync -az -e "ssh -i ${RESPALDO_LLAVE_SSH} -o StrictHostKeyChecking=accept-new" \
    "${DIR_RESPALDOS}/" \
    "${RESPALDO_USUARIO_REMOTO}@${RESPALDO_SERVIDOR_REMOTO}:${RESPALDO_DIR_REMOTO}/"; then
  registrar "Sincronización remota exitosa."
else
  registrar "ADVERTENCIA: Falló la sincronización remota. El respaldo local sí quedó guardado."
fi

# Limpiar respaldos locales antiguos (el historial completo queda en el servidor remoto)
ELIMINADOS=$(find "${DIR_RESPALDOS}" -name "*.sql.gz" -mtime +${DIAS_RETENCION_LOCAL} | wc -l)
find "${DIR_RESPALDOS}" -name "*.sql.gz" -mtime +${DIAS_RETENCION_LOCAL} -delete
if [ "${ELIMINADOS}" -gt 0 ]; then
  registrar "Limpieza local: ${ELIMINADOS} archivo(s) eliminados (mayores a ${DIAS_RETENCION_LOCAL} días)."
fi

registrar "=== Respaldo completado exitosamente ==="
