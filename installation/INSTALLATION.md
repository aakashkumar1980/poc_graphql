# GraphQL POC — Installation & Setup Guide (Ubuntu 22.04 / AWS WorkSpace)

This document covers all software installations and account creation required to run the GraphQL POC.

**Approach:** Docker Compose for infrastructure (PostgreSQL, Apollo Router, Rover). Only Java/Maven and Postman installed natively on the host.

---

## Architecture Overview (Post-Meeting Changes)

| Component | Runs In | Tech | Port |
|---|---|---|---|
| **Test Client** | Host | Postman | — |
| **Deposit Subgraph** | Host | Spring Boot 3.3 + Java 17 | :8081 |
| **Apollo Router** | Docker | GraphQL Gateway | :4000 |
| **Database 1** | Docker | PostgreSQL 15 (accounts, balances) | :5432 |
| **Database 2** | Docker | PostgreSQL 15 (transactions, disputes) | :5433 |
| **Schema Tooling** | Docker | Rover CLI (on-demand) | — |
| **Schema Explorer** | Cloud | Apollo Studio | — |

> **Removed from original diagram:** External Systems (WireMock / FIS / Deluxe TRIPs) — not needed for this POC.
> **Changed:** Single database split into two PostgreSQL instances to demonstrate multi-datasource configuration.

---

## Folder Structure

```
installation/
├── INSTALLATION.md              ← this file
├── docker-compose.yml           ← PostgreSQL x2 + Apollo Router
├── .env                         ← (create manually) Apollo Studio keys
├── postgres/
│   ├── init-accounts.sql        ← DDL + seed data for DB1
│   └── init-transactions.sql    ← DDL + seed data for DB2
├── router/
│   ├── router.yaml              ← Apollo Router config
│   ├── supergraph.yaml          ← Rover composition config
│   └── supergraph.graphql       ← Composed supergraph schema
└── scripts/
    ├── start.sh                 ← Start all containers
    ├── stop.sh                  ← Stop all containers
    ├── status.sh                ← Health check all services
    ├── compose-supergraph.sh    ← Re-compose supergraph via Rover
    └── reset-databases.sh       ← Wipe and re-seed databases
```

---

## PART A — Install on Host (native)

### 1. Docker & Docker Compose

```bash
# Install Docker
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

# Allow current user to run Docker without sudo
sudo usermod -aG docker $USER
newgrp docker

# Verify
docker --version          # Expected: Docker version 24.x or later
docker compose version    # Expected: Docker Compose version v2.x
```

### 2. Java 17 (required by Spring Boot 3.3)

```bash
sudo apt install -y openjdk-17-jdk

# Verify
java -version
# Expected: openjdk version "17.x.x"

# Set JAVA_HOME (add to ~/.bashrc for persistence)
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.bashrc
source ~/.bashrc
```

### 3. Maven (build tool for Spring Boot)

```bash
sudo apt install -y maven

# Verify
mvn -version
# Expected: Apache Maven 3.x.x
```

### 4. Postman (Test Client)

#### Option A — Snap install (easiest)
```bash
sudo snap install postman
```

#### Option B — Download from website
1. Go to https://www.postman.com/downloads/
2. Download the Linux x64 version
3. Extract and run

#### Account creation
- Open Postman and sign up for a **free account** (or use without signing in for basic testing).

### 5. Git, curl, jq (utilities)

```bash
sudo apt install -y git curl jq

# Verify
git --version
curl --version | head -1
jq --version
```

---

## PART B — Apollo Studio Account Creation (FREE)

Apollo Studio lets you browse the schema and run live queries from a web UI.

### Steps:
1. Go to **https://studio.apollographql.com/**
2. Click **"Create a free account"**
3. Sign up with GitHub or email
4. Once logged in, create a new **Graph**:
   - Graph name: `graphql-poc`
   - Graph type: select **"Self-Hosted"** (Supergraph)
   - Architecture: **"Federation 2"**
5. Apollo Studio will give you:
   - **`APOLLO_KEY`** — an API key (starts with `service:...`)
   - **`APOLLO_GRAPH_REF`** — e.g. `graphql-poc@current`
6. Save these values in `installation/.env`:

```bash
# installation/.env  (DO NOT commit this file)
APOLLO_KEY=service:graphql-poc:xxxxxxxxxxxxx
APOLLO_GRAPH_REF=graphql-poc@current
```

> **Note:** Apollo Studio free tier is sufficient for this POC. No credit card required.
> Apollo Studio is optional for initial development — the Router works without it.

---

## PART C — Start Infrastructure (Docker Compose)

### First-time setup

```bash
cd installation/

# Start everything (PostgreSQL x2 + Apollo Router)
./scripts/start.sh
```

This will:
- Pull Docker images (postgres:15-alpine, Apollo Router)
- Create two PostgreSQL databases with seed data
- Start Apollo Router on port 4000

### Verify

```bash
./scripts/status.sh
```

### Available scripts

| Script | What it does |
|---|---|
| `./scripts/start.sh` | Start all containers |
| `./scripts/stop.sh` | Stop all containers (data preserved) |
| `./scripts/status.sh` | Health check all services |
| `./scripts/compose-supergraph.sh` | Re-compose supergraph after schema changes (requires Spring Boot running on :8081) |
| `./scripts/reset-databases.sh` | Wipe all data and re-seed from init SQL scripts |

### Connect to databases manually

```bash
# Database 1 — accounts & balances
docker compose exec postgres-accounts psql -U poc_user -d deposit_accounts

# Database 2 — transactions & disputes
docker compose exec postgres-transactions psql -U poc_user -d deposit_transactions
```

---

## PART D — Quick Verification Checklist

Run this to verify all host-level tools are installed:

```bash
echo "=== Host Installation Verification ==="
echo -n "Docker:     "; docker --version
echo -n "Compose:    "; docker compose version
echo -n "Java:       "; java -version 2>&1 | head -1
echo -n "Maven:      "; mvn -version 2>&1 | head -1
echo -n "Git:        "; git --version
echo -n "curl:       "; curl --version 2>&1 | head -1
echo -n "jq:         "; jq --version
echo "=== Done ==="
```

Then verify Docker infrastructure:

```bash
cd installation/
./scripts/status.sh
```

---

## Summary

### What runs where

| Where | What |
|---|---|
| **Docker** | PostgreSQL x2, Apollo Router, Rover CLI |
| **Host** | Java 17, Maven, Spring Boot app, Postman, Git |
| **Cloud** | Apollo Studio (optional, browser-based) |

### Accounts needed

| Service | Account Type | Cost | Purpose |
|---|---|---|---|
| **Apollo Studio** | Free tier | $0 | Schema registry, live query explorer |
| **Postman** | Free (optional) | $0 | API testing |

### Database credentials

| Database | Host | Port | DB Name | User | Password |
|---|---|---|---|---|---|
| DB1 (accounts) | localhost | 5432 | deposit_accounts | poc_user | poc_pass |
| DB2 (transactions) | localhost | 5433 | deposit_transactions | poc_user | poc_pass |

---

## What's Next

Once all installations are verified:
1. Create the Spring Boot subgraph project with multi-datasource configuration
2. Define the GraphQL schema (`schema.graphqls`)
3. Run `./scripts/compose-supergraph.sh` to generate the supergraph
4. Test end-to-end with Postman → Router(:4000) → Subgraph(:8081) → DBs
