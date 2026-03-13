# GraphQL POC — Installation & Setup Guide (Ubuntu 22.04 / AWS WorkSpace)

This document covers all software installations and account creation required to run the GraphQL POC.

**Approach:** Docker Compose for infrastructure (PostgreSQL, Apollo Router). Java/Gradle, Rover CLI, and Postman installed natively on the host.

---

## Architecture Overview

| Component | Runs In | Tech | Port |
|---|---|---|---|
| **Test Client** | Host | Postman | — |
| **Deposit Subgraph** | Host | Spring Boot 3.3 + Java 21 | :8081 |
| **Apollo Router** | Docker | GraphQL Gateway | :4000 |
| **Database 1** | Docker | PostgreSQL 15 (accounts, balances) | :5432 |
| **Database 2** | Docker | PostgreSQL 15 (transactions, disputes) | :5433 |
| **Schema Tooling** | Host | Rover CLI (native install) | — |
| **Schema Explorer** | Cloud | Apollo Studio | — |

### End-to-end request flow

```
Postman / Apollo Studio
        │
        ▼
Apollo Router (:4000)          ← GraphQL Gateway (Docker)
        │
        ▼
Deposit Subgraph (:8081)       ← Spring Boot app (Host)
        │
   ┌────┴────┐
   ▼         ▼
 DB1       DB2                 ← PostgreSQL x2 (Docker)
(:5432)   (:5433)
```

> **Removed from original diagram:** External Systems (WireMock / FIS / Deluxe TRIPs) — not needed for this POC.
> **Changed:** Single database split into two PostgreSQL instances to demonstrate multi-datasource configuration.

---

## Folder Structure

```
installation/
├── INSTALLATION.md                  ← this file
├── docker-compose.yml               ← PostgreSQL x2 + Apollo Router
├── .env                             ← (create in Phase 2) Apollo Studio keys
├── postgres/
│   ├── init-accounts.sql            ← DDL + seed data for DB1
│   └── init-transactions.sql        ← DDL + seed data for DB2
├── router/
│   ├── router.yaml                  ← Apollo Router config
│   ├── supergraph.yaml              ← Rover composition config
│   └── supergraph.graphql           ← Composed supergraph schema (placeholder until Phase 4)
└── scripts/
    ├── install-host-prerequisites.sh ← One-time host setup (Phase 1)
    ├── start.sh                      ← Start all containers
    ├── stop.sh                       ← Stop all containers
    ├── status.sh                     ← Health check all services
    ├── compose-supergraph.sh         ← Re-compose supergraph via Rover
    └── reset-databases.sh            ← Wipe and re-seed databases
```

---

# PHASE 1 — ONE-TIME SETUP (do once on a fresh machine)

Everything in this phase is done **once**. After this, your machine is ready for development.

---

## 1.1 — Install Host Prerequisites

### Option A — Automated (recommended)
```bash
chmod +x installation/scripts/install-host-prerequisites.sh
./installation/scripts/install-host-prerequisites.sh
```

### Option B — Manual (step by step)

#### Docker & Docker Compose
```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker $USER
newgrp docker
```

#### Java 21
```bash
sudo apt install -y openjdk-21-jdk
echo 'export JAVA_HOME=/usr/lib/jvm/java-1.21.0-openjdk-amd64' >> ~/.bashrc
source ~/.bashrc
```

#### Gradle
```bash
sudo apt install -y unzip
# No system-wide install needed — uses wrapper (gradlew) from the project
```

#### Postman
```bash
sudo snap install postman
# OR download from https://www.postman.com/downloads/
```

#### Rover CLI
```bash
curl -sSL https://rover.apollo.dev/nix/latest | sh
echo 'export PATH="$HOME/.rover/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

#### Utilities
```bash
sudo apt install -y git curl jq
```

### Verify all host tools
```bash
docker --version && docker compose version && java -version && rover --version && git --version
```

---

## 1.2 — Apollo Studio Account & Graph Creation

> **Optional** — the Router works without Apollo Studio. Skip to Phase 2 if short on time.

### Create account
1. Go to **https://studio.apollographql.com/** → Create a free account (GitHub or email)

### Authenticate Rover
```bash
rover config auth
# Opens a URL in browser → log in → paste API key back into terminal
```

### Create the graph
```bash
mkdir -p /tmp/rover-init && rover init --path /tmp/rover-init
```
Follow prompts:
1. `Create a new graph`
2. `Start a graph with GraphQL APIs`
3. Name: `graphql-poc`
4. Accept graph ID → `Y`

**Copy the credentials** from the output:
- `APOLLO_KEY=service:graphql-poc-xxxxxxx:xxxxxxxxxxxxx`
- `APOLLO_GRAPH_REF=graphql-poc-xxxxxxx@current`

### Save credentials
```bash
cat > installation/.env << 'EOF'
APOLLO_KEY=service:graphql-poc-xxxxxxx:xxxxxxxxxxxxx
APOLLO_GRAPH_REF=graphql-poc-xxxxxxx@current
EOF
```

### Cleanup
```bash
rm -rf /tmp/rover-init
```

---

## 1.3 — Verify One-Time Setup is Complete

At this point you should have:

| Item | How to verify |
|---|---|
| Docker | `docker --version` |
| Java 21 | `java -version` |
| Rover CLI | `rover --version` |
| Postman | Open the app |
| Apollo Studio graph | Check https://studio.apollographql.com/ (optional) |
| `.env` file | `cat installation/.env` (optional) |

**Phase 1 is DONE.** You never need to repeat these steps.

---

# PHASE 2 — START INFRASTRUCTURE (do each work session)

Run this each time you start working on the POC (e.g., after a reboot).

---

## 2.1 — Start Docker Containers

```bash
cd installation/
./scripts/start.sh
```

This starts:
- PostgreSQL x2 (ports 5432, 5433) with seed data
- Apollo Router (port 4000) with placeholder schema

> The `docker-compose.yml` auto-reads `.env` for Apollo Studio credentials. If `.env` is missing, Router runs standalone.

## 2.2 — Verify Infrastructure is Running

```bash
./scripts/status.sh
```

Or manually:
```bash
# Databases
docker compose exec postgres-accounts psql -U poc_user -d deposit_accounts -c "SELECT count(*) FROM accounts;"
# Expected: 3

# Router
curl -sf http://localhost:4000/ -o /dev/null && echo "Router is UP" || echo "Router is DOWN"
```

**Phase 2 is DONE.** Infrastructure is running. Proceed to development.

---

## Useful Infrastructure Commands

| Script | What it does |
|---|---|
| `./scripts/start.sh` | Start all containers |
| `./scripts/stop.sh` | Stop all containers (data preserved) |
| `./scripts/status.sh` | Health check all services |
| `./scripts/compose-supergraph.sh` | Re-compose supergraph (after schema changes) |
| `./scripts/reset-databases.sh` | Wipe all data and re-seed |

### Connect to databases manually
```bash
docker compose exec postgres-accounts psql -U poc_user -d deposit_accounts
docker compose exec postgres-transactions psql -U poc_user -d deposit_transactions
```

### Database credentials

| Database | Port | DB Name | User | Password |
|---|---|---|---|---|
| DB1 (accounts) | 5432 | deposit_accounts | poc_user | poc_pass |
| DB2 (transactions) | 5433 | deposit_transactions | poc_user | poc_pass |

---

# PHASE 3 — DEVELOP THE SPRING BOOT SUBGRAPH

> **Prerequisite:** Phase 2 must be complete (infrastructure running).

This is the main development work — building the Spring Boot GraphQL subgraph.

1. Create the Spring Boot project with multi-datasource configuration
2. Define the GraphQL schema (`schema.graphqls`)
3. Implement resolvers, services, and repositories
4. Start the app on `:8081`

---

# PHASE 4 — COMPOSE SUPERGRAPH & TEST END-TO-END

> **Prerequisite:** Phase 3 must be complete (Spring Boot running on :8081).

## 4.1 — Compose the Supergraph

```bash
cd installation/
./scripts/compose-supergraph.sh
```

This uses Rover to:
1. Introspect the Spring Boot subgraph at `http://localhost:8081/graphql`
2. Compose the supergraph schema using Federation 2.7.1
3. Write `router/supergraph.graphql`
4. Restart the Router to load the new schema

### Configuration reference

`router/supergraph.yaml`:
```yaml
federation_version: =2.7.1
subgraphs:
  deposit:
    routing_url: http://host.docker.internal:8081/graphql   # Router (Docker) → Host
    schema:
      subgraph_url: http://localhost:8081/graphql            # Rover (Host) → Host
```

> Re-run `compose-supergraph.sh` after any GraphQL schema changes.

## 4.2 — Test End-to-End

```bash
# Via Router (the full path: Postman → Router → Subgraph → DB)
curl -s http://localhost:4000/ \
  -H "Content-Type: application/json" \
  -d '{"query":"{ hello }"}' | jq .
```

## 4.3 — Explore with Apollo Tools

- **Local Sandbox:** Open http://localhost:4000 in browser (built-in GraphQL IDE)
- **Apollo Studio:** Check https://studio.apollographql.com/ — graph should now show as connected with full schema

---

## Summary

| Phase | What | When |
|---|---|---|
| **Phase 1** | Install tools, create Apollo account | Once per machine |
| **Phase 2** | `./scripts/start.sh` | Each work session |
| **Phase 3** | Build Spring Boot subgraph | Development |
| **Phase 4** | `./scripts/compose-supergraph.sh` + test | After each schema change |
