#!/usr/bin/env bash
# ============================================
# Compose supergraph schema using Rover CLI
# ============================================
# Run this AFTER the Spring Boot subgraph is running on :8081
# so Rover can introspect the subgraph's schema.
# ============================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROUTER_DIR="$(dirname "$SCRIPT_DIR")/router"

echo "=== Composing Supergraph Schema ==="
echo ""

# Check if Spring Boot subgraph is running
if ! curl -sf http://localhost:8081/graphql -H "Content-Type: application/json" -d '{"query":"{__typename}"}' > /dev/null 2>&1; then
    echo "ERROR: Spring Boot subgraph is not running on :8081"
    echo "       Start it first, then re-run this script."
    exit 1
fi

echo "  Subgraph detected on :8081"

# Use Rover via Docker to compose the supergraph
docker run --rm \
    --network host \
    -v "$ROUTER_DIR:/config" \
    ghcr.io/apollographql/rover:latest \
    supergraph compose --config /config/supergraph.yaml --output /config/supergraph.graphql

echo ""
echo "  Supergraph schema written to: router/supergraph.graphql"
echo ""

# Restart the router to pick up the new schema
echo "  Restarting Apollo Router to load new schema..."
cd "$(dirname "$SCRIPT_DIR")"
docker compose restart apollo-router

echo ""
echo "=== Done — Router is now serving the composed supergraph ==="
