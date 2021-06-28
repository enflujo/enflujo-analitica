# Sitios Analítica

![Despliegue](https://github.com/enflujo/sitios-analitica/actions/workflows/despliegue.yml/badge.svg)


Usamos la aplicación [Umami](https://umami.is/docs/about) que funciona como un reemplazo de Google Analytics. Umami es gratis, open-source, liviana y tiene un énfasis en la privacidad de los usuarios que visitan las páginas. 

Para poder usarla se debe instalar en un servidor propio. 

Este repositorio contiene lo necesario para instalar la aplicación en un servidor:

## Instalación

### Clonar
En el servidor:

```bash
git clone https://github.com/enflujo/sitios-analitica.git
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
```

### Iniciar con Docker
Umami es una aplicación de Node y se puede instalar directamente clonano el código desde su [repositorio](https://github.com/mikecao/umami). En nuestro caso vamos a usar Docker para no depender de una base de datos administrada en el servidor. 

Ver el archivo `docker-compose.yml` para saber que versión de Postgres y Umami se están instalando (de manera predeterminada se usan las mas recientes de cada una).

Teniendo Docker y Docker Compose instalados en el servidor, simplemente se puede iniciar con:

```bash
# ir primero a la carpeta que se acaba de clonar
cd sitios-analitica

# Descargar e iniciar contenedores
docker-compose up -d
```

## Actualizar Umami

Desde este repositorio tenemos configurado un Github Action llamado [despliegue](./.github/workflows/despliegue.yml) que se encarga de mandarle las siguientes instrucciones al servidor:

1. Conectarse al servidor usando las credenciales guardadas en los "Secrets" del repositorio.
2. Descargar la versión más reciente de este repositorio.
3. Actualizar la imagen que usa Docker para umami
4. Reiniciar contenedores.

Esta acción sólo se activa cuando hay cambios en este repositorio así que si se quiere actualizar Umami sin hacer cambios a los archivos de configuración, simplemente cambiar algo en el archivo `version.md`. (no importa lo que se cambie en este archivo, se usa simplemente para hacer un push al repositorio y activar el Github Action).

