#!/bin/bash
# docker-entrypoint.sh

# Vuelca todas las variables de entorno actuales a un fichero
# que el crontab cargará con `source` antes de ejecutar el script
printenv | grep -v "^no_proxy=" > /etc/environment

# Arranca cron en foreground
exec cron -f -L /dev/stdout