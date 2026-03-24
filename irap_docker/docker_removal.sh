#!/bin/bash
# =============================================================
# remove_docker_images.sh
# Auto-detects and removes ALL docker images on this machine.
# =============================================================
set -e

echo "==> Current Docker images:"
docker images
echo ""

# Get all image IDs
IMAGE_IDS=$(docker images -q)

if [ -z "$IMAGE_IDS" ]; then
  echo "==> No Docker images found. Nothing to remove."
  exit 0
fi

echo "==> Removing all Docker images..."
docker image rm -f $IMAGE_IDS

echo ""
echo "==> Done! Remaining images:"
docker images
