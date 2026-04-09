#!/bin/bash
set -e

echo "Stopping all OpenFMR modules..."
# Simple way to stop all in the current directory structure
for dir in openfmr-portal-ui openfmr-operations-ui openfmr-clinical-ui openfmr-admin-ui openfmr-core openfmr-module-cr openfmr-module-hfr openfmr-module-lmis openfmr-module-hwr openfmr-module-ts openfmr-module-shr; do
  if [ -d "$dir" ]; then
    echo "Stopping $dir..."
    (cd "$dir" && docker compose down)
  fi
done

echo "Step 1: Starting OpenFMR Core..."
(cd openfmr-core && docker compose --env-file .env.example up -d)
sleep 45

for dir in openfmr-module-cr openfmr-module-hfr openfmr-module-lmis openfmr-module-hwr openfmr-module-ts openfmr-module-shr openfmr-admin-ui openfmr-clinical-ui openfmr-operations-ui openfmr-portal-ui; do
  echo "Step: Starting $dir..."
  (cd "$dir" && docker compose --env-file ../.env.global up -d)
  echo "Waiting 60s for $dir to stabilize..."
  sleep 60
done

echo "All modules started. Checking status..."
docker ps --format "{{.Names}}: {{.Status}}"
