#!/bin/bash
# =============================================================
# docker_build_and_up.sh
# Builds and starts all services in detached mode.
# =============================================================
set -e

COMPOSE_FILE="${1:-docker-compose.yml}"

echo "==> [1/2] Building Docker images..."
docker compose -f "$COMPOSE_FILE" build

echo ""
echo "==> [2/2] Starting services in detached mode..."
docker compose -f "$COMPOSE_FILE" up -d

echo ""
echo "==> Done! Running containers:"
docker compose -f "$COMPOSE_FILE" ps
