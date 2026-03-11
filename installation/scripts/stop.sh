#!/usr/bin/env bash
# ============================================
# Stop all POC infrastructure containers
# ============================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Stopping GraphQL POC Infrastructure ==="

cd "$INSTALL_DIR"
docker compose down

echo "=== All containers stopped ==="
echo ""
echo "Note: Database volumes are preserved."
echo "To also delete all data, run:  docker compose down -v"
