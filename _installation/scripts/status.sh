#!/usr/bin/env bash
# ============================================
# Check status of all POC infrastructure
# ============================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== GraphQL POC Infrastructure Status ==="
echo ""

cd "$INSTALL_DIR"
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "--- Connectivity Checks ---"

# PostgreSQL 1
if docker compose exec -T postgres-accounts pg_isready -U poc_user -d deposit_accounts > /dev/null 2>&1; then
    echo "  DB1 (accounts):      CONNECTED"
else
    echo "  DB1 (accounts):      NOT REACHABLE"
fi

# PostgreSQL 2
if docker compose exec -T postgres-transactions pg_isready -U poc_user -d deposit_transactions > /dev/null 2>&1; then
    echo "  DB2 (transactions):  CONNECTED"
else
    echo "  DB2 (transactions):  NOT REACHABLE"
fi

# Apollo Router
if curl -sf http://localhost:4000/health > /dev/null 2>&1; then
    echo "  Apollo Router:       HEALTHY"
else
    echo "  Apollo Router:       NOT REACHABLE"
fi

# Spring Boot subgraph
if curl -sf http://localhost:8081/actuator/health > /dev/null 2>&1; then
    echo "  Spring Boot (8081):  HEALTHY"
else
    echo "  Spring Boot (8081):  NOT RUNNING (start it separately)"
fi

echo ""
