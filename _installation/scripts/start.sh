#!/usr/bin/env bash
# ============================================
# Start all POC infrastructure containers
# ============================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Starting GraphQL POC Infrastructure ==="
echo ""

# Start containers
cd "$INSTALL_DIR"
docker compose up -d

echo ""
echo "=== Waiting for services to be healthy ==="

# Wait for PostgreSQL instances
for i in {1..30}; do
    ACCOUNTS_OK=$(docker compose exec -T postgres-accounts pg_isready -U poc_user -d deposit_accounts 2>/dev/null && echo "yes" || echo "no")
    TRANSACTIONS_OK=$(docker compose exec -T postgres-transactions pg_isready -U poc_user -d deposit_transactions 2>/dev/null && echo "yes" || echo "no")

    if [[ "$ACCOUNTS_OK" == "yes" && "$TRANSACTIONS_OK" == "yes" ]]; then
        echo "  PostgreSQL instances: READY"
        break
    fi
    sleep 1
done

# Check Apollo Router
for i in {1..15}; do
    if curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:4000/ -H "Content-Type: application/json" -d '{"query":"{ __typename }"}' 2>/dev/null | grep -q "200"; then
        echo "  Apollo Router:        READY"
        break
    fi
    if [[ $i -eq 15 ]]; then
        echo "  Apollo Router:        STARTING (may need supergraph schema update)"
    fi
    sleep 1
done

echo ""
echo "=== Infrastructure Status ==="
echo "  PostgreSQL (accounts):      localhost:5432  (DB: deposit_accounts)"
echo "  PostgreSQL (transactions):  localhost:5433  (DB: deposit_transactions)"
echo "  Apollo Router:              localhost:4000"
echo "  Apollo Sandbox:             http://localhost:4000"
echo ""
echo "  DB Credentials:  poc_user / poc_pass"
echo ""
echo "  Next: Start the Spring Boot subgraph on :8081"
echo "=== Done ==="
