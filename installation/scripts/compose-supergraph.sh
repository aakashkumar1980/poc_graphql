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

# Check if Rover is installed
if ! command -v rover &> /dev/null; then
    echo "ERROR: Rover CLI is not installed."
    echo "       Install it with: curl -sSL https://rover.apollo.dev/nix/latest | sh"
    exit 1
fi

# Use native Rover to compose the supergraph
rover supergraph compose --config "$ROUTER_DIR/supergraph.yaml" --output "$ROUTER_DIR/supergraph.graphql"

echo ""
echo "  Supergraph schema written to: router/supergraph.graphql"
echo ""

# Restart the router to pick up the new schema
echo "  Restarting Apollo Router to load new schema..."
cd "$(dirname "$SCRIPT_DIR")"
docker compose restart apollo-router

echo ""
echo "=== Done — Router is now serving the composed supergraph ==="
