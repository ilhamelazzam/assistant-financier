#!/usr/bin/env pwsh
Set-Location -Path $PSScriptRoot
docker compose up -d
if ($LASTEXITCODE -ne 0) {
  Write-Error "Échec du démarrage du conteneur MySQL. Vérifie que Docker est installé et en cours d'exécution."
  exit $LASTEXITCODE
}
Write-Output "MySQL container started (af-mysql)."
