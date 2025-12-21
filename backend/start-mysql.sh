#!/bin/sh
cd "$(dirname "$0")"
docker compose up -d
if [ $? -ne 0 ]; then
  echo "Échec du démarrage du conteneur MySQL. Vérifie que Docker est installé et en cours d'exécution."
  exit 1
fi
echo "MySQL container started (af-mysql)."
