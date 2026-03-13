#!/usr/bin/env bash
# ============================================
# Reset databases — drops volumes and recreates
# with fresh seed data
# ============================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Resetting POC Databases ==="
echo "WARNING: This will destroy all data and re-seed from init scripts."
read -p "Continue? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

cd "$INSTALL_DIR"

# Stop and remove volumes
docker compose down -v

# Restart with fresh data
docker compose up -d

echo ""
echo "=== Databases reset with fresh seed data ==="
