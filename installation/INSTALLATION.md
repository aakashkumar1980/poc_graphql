# GraphQL POC — Installation & Setup Guide (Ubuntu 22.04 / AWS WorkSpace)

This document covers all software installations and account creation required to run the GraphQL POC.

**Approach:** Docker Compose for infrastructure (PostgreSQL, Apollo Router, Rover). Only Java/Gradle and Postman installed natively on the host.

---

## Architecture Overview (Post-Meeting Changes)

| Component | Runs In | Tech | Port |
|---|---|---|---|
| **Test Client** | Host | Postman | — |
| **Deposit Subgraph** | Host | Spring Boot 3.3 + Java 21 | :8081 |
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

### 2. Java 21 (required by Spring Boot 3.3 — needs Java 17+)

```bash
sudo apt install -y openjdk-21-jdk

# Verify
java -version
# Expected: openjdk version "21.x.x"

# Set JAVA_HOME (add to ~/.bashrc for persistence)
echo 'export JAVA_HOME=/usr/lib/jvm/java-1.21.0-openjdk-amd64' >> ~/.bashrc
source ~/.bashrc
```

### 3. Gradle (build tool for Spring Boot)

Gradle uses a **wrapper** (`gradlew`) bundled in the project, so no system-wide install is needed.
Just ensure `unzip` is available (used by the wrapper on first run):

```bash
sudo apt install -y unzip

# Verify (run from the Spring Boot project root once it exists)
./gradlew --version
# Expected: Gradle 8.x
```

> **Note:** The Spring Boot project will include `gradlew` and `gradle/` wrapper files.
> You do NOT need to install Gradle system-wide.

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

## PART B — Apollo Studio Setup (FREE)

Apollo Studio is a cloud-based schema explorer that lets you browse your GraphQL schema and run live queries from a web UI. It connects to your self-hosted Apollo Router.

> **Note:** Apollo Studio is **optional** for initial development — the Router works without it.
> You also get a local sandbox explorer at `http://localhost:4000` once the Router is running.
> Apollo Studio adds cloud-based schema registry and a shareable query explorer.

### Step 1 — Create Apollo Studio Account

1. Go to **https://studio.apollographql.com/**
2. Click **"Create a free account"**
3. Sign up with **GitHub** or email (free tier, no credit card required)
4. Once logged in, you'll land on the **Graphs** page (e.g. `https://studio.apollographql.com/org/<your-org>/graphs`)

### Step 2 — Authenticate Rover CLI with Apollo Studio

Apollo Studio requires the **Rover CLI** to create and manage graphs. We run Rover via Docker.

```bash
# Authenticate Rover with your Apollo Studio account
docker run --rm -it ghcr.io/apollographql/rover:latest config auth
```

This will:
- Display a URL — open it in your browser
- Ask you to log in and authorize Rover
- Give you a **Personal API Key** — paste it back into the terminal when prompted

> **Tip:** The API key is stored inside the Docker container and won't persist across runs.
> For repeated use, you can set it as an environment variable instead (see Step 4).

### Step 3 — Create the Graph using Rover

From the Apollo Studio Graphs page, it will prompt you to use `rover init`. Run:

```bash
docker run --rm -it \
    -e APOLLO_KEY=<your-personal-api-key-from-step-2> \
    ghcr.io/apollographql/rover:latest \
    init
```

Follow the interactive prompts:
1. **Graph name:** `graphql-poc`
2. **Graph type:** Select **Supergraph** (Federation 2)
3. **Environment:** Select **Self-Hosted**

Once complete, Rover will output:
- **`APOLLO_KEY`** — a graph API key (starts with `service:graphql-poc:...`)
- **`APOLLO_GRAPH_REF`** — e.g. `graphql-poc@current`

> **Important:** Copy both values immediately. The `APOLLO_KEY` is shown only once.

### Step 4 — Save Credentials

Create the `.env` file in the `installation/` directory:

```bash
# installation/.env  (DO NOT commit this file — it's in .gitignore)
APOLLO_KEY=service:graphql-poc:xxxxxxxxxxxxx
APOLLO_GRAPH_REF=graphql-poc@current
```

### Step 5 — Verify in Apollo Studio Portal

1. Go back to **https://studio.apollographql.com/**
2. You should see the **`graphql-poc`** graph listed on your Graphs page
3. The graph will show as "not connected" until the Router is configured (Part C)

> **What's next:** In Part C, we'll start the Apollo Router and connect it to Apollo Studio using these credentials.

---

## PART C — Start Infrastructure (Docker Compose)

### Step 1 — Enable Apollo Studio Connection (optional but recommended)

If you completed Part B and have `APOLLO_KEY` and `APOLLO_GRAPH_REF`, enable the connection in `docker-compose.yml`:

```bash
cd installation/
```

Edit `docker-compose.yml` and **uncomment** the Apollo Studio environment variables in the `apollo-router` service:

```yaml
    environment:
      APOLLO_ROUTER_CONFIG_PATH: /dist/config/router.yaml
      APOLLO_ROUTER_SUPERGRAPH_PATH: /dist/config/supergraph.graphql
      # Uncomment these two lines:
      APOLLO_KEY: ${APOLLO_KEY}
      APOLLO_GRAPH_REF: ${APOLLO_GRAPH_REF}
```

> This tells the Router to read `APOLLO_KEY` and `APOLLO_GRAPH_REF` from the `.env` file you created in Part B.
> If you skip this, the Router still works — you just won't see the graph in Apollo Studio.

### Step 2 — Start All Containers

```bash
cd installation/

# Start everything (PostgreSQL x2 + Apollo Router)
./scripts/start.sh
```

This will:
- Pull Docker images (postgres:15-alpine, Apollo Router v1.57.1)
- Create two PostgreSQL databases with seed data
- Start Apollo Router on port 4000

### Step 3 — Verify Infrastructure

```bash
./scripts/status.sh
```

#### Verify each component individually:

**Databases:**
```bash
# Check both PostgreSQL containers are healthy
docker compose ps postgres-accounts postgres-transactions
# Expected: both show "running" with health status "healthy"

# Connect to databases to verify seed data
docker compose exec postgres-accounts psql -U poc_user -d deposit_accounts -c "SELECT count(*) FROM accounts;"
# Expected: 3

docker compose exec postgres-transactions psql -U poc_user -d deposit_transactions -c "SELECT count(*) FROM transactions;"
# Expected: 7
```

**Apollo Router:**
```bash
# Check Router container is running
docker compose ps apollo-router
# Expected: running

# Check Router is responding (serves Apollo Sandbox UI)
curl -sf http://localhost:4000/ -o /dev/null && echo "Router is UP" || echo "Router is DOWN"

# Check Router logs for errors
docker compose logs apollo-router --tail 20
```

> **Note:** The Router starts with a placeholder supergraph schema. It will return schema errors for real queries until the Spring Boot subgraph is running and the supergraph is composed (Part D).

**Apollo Studio (if configured):**
1. Go to **https://studio.apollographql.com/**
2. Open your **`graphql-poc`** graph
3. It should show as **connected** (green status)
4. The schema explorer will populate once the supergraph is composed (Part D)

### Step 4 — Explore Apollo Router Sandbox (local)

Even without Apollo Studio, you get a **local sandbox explorer**:

1. Open **http://localhost:4000** in your browser
2. This is Apollo Sandbox — a built-in GraphQL IDE
3. You can browse the schema, write queries, and test mutations here
4. It works the same as Apollo Studio Explorer, but runs locally

> **Sandbox vs Apollo Studio:** Sandbox is local and ephemeral. Apollo Studio is cloud-based, persists your queries, and provides schema version history.

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

## PART D — Compose Supergraph with Rover CLI

Rover CLI composes your subgraph schemas into a **supergraph schema** that the Apollo Router loads. It runs via Docker — no host installation needed.

> **When to run this:** After the Spring Boot subgraph is running on `:8081` (i.e., after the Spring Boot app is built and started).

### How it works

1. Rover introspects the running Spring Boot subgraph at `http://localhost:8081/graphql`
2. It composes the subgraph schema into a single **supergraph schema** using Federation 2.7.1
3. The output is written to `router/supergraph.graphql`
4. The Apollo Router is restarted to load the new schema

### Configuration

The composition is configured in `router/supergraph.yaml`:

```yaml
federation_version: =2.7.1

subgraphs:
  deposit:
    routing_url: http://host.docker.internal:8081/graphql
    schema:
      subgraph_url: http://host.docker.internal:8081/graphql
```

> This tells Rover where to find the subgraph and what Federation version to use.

### Run supergraph composition

```bash
cd installation/

# Ensure Spring Boot subgraph is running on :8081 first!
./scripts/compose-supergraph.sh
```

### Verify

```bash
# Check the generated supergraph has real schema content (not placeholder)
head -30 router/supergraph.graphql
# Expected: should contain your actual Query/Mutation types with @join directives

# Test a query through the Router
curl -s http://localhost:4000/ \
  -H "Content-Type: application/json" \
  -d '{"query":"{ __typename }"}' | jq .
# Expected: {"data":{"__typename":"Query"}}
```

> **Re-run after schema changes:** Whenever you modify the GraphQL schema in the Spring Boot app, re-run `./scripts/compose-supergraph.sh` to update the supergraph and restart the Router.

---

## PART E — Quick Verification Checklist

### Host tools

```bash
echo "=== Host Installation Verification ==="
echo -n "Docker:     "; docker --version
echo -n "Compose:    "; docker compose version
echo -n "Java:       "; java -version 2>&1 | head -1
echo -n "Gradle:     "; gradle --version 2>&1 | grep "Gradle" | head -1 || echo "Uses wrapper (gradlew)"
echo -n "Git:        "; git --version
echo -n "curl:       "; curl --version 2>&1 | head -1
echo -n "jq:         "; jq --version
echo "=== Done ==="
```

### Docker infrastructure

```bash
cd installation/
./scripts/status.sh
```

### Full end-to-end verification (after Spring Boot is running)

```bash
# 1. Databases are healthy
docker compose ps                    # All 3 containers running

# 2. Spring Boot subgraph responds
curl -sf http://localhost:8081/graphql -H "Content-Type: application/json" \
  -d '{"query":"{ __typename }"}' && echo " Subgraph OK"

# 3. Supergraph is composed
head -5 router/supergraph.graphql    # Should show real schema

# 4. Router routes queries to subgraph
curl -s http://localhost:4000/ -H "Content-Type: application/json" \
  -d '{"query":"{ __typename }"}' | jq .
# Expected: {"data":{"__typename":"Query"}}

# 5. Apollo Studio shows graph (if configured)
#    → Check https://studio.apollographql.com/ — graph should be "connected"
```

---

## Summary

### What runs where

| Where | What |
|---|---|
| **Docker** | PostgreSQL x2, Apollo Router, Rover CLI |
| **Host** | Java 21, Gradle (wrapper), Spring Boot app, Postman, Git |
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

---

## What's Next

Once all installations are verified:
1. Create the Spring Boot subgraph project with multi-datasource configuration
2. Define the GraphQL schema (`schema.graphqls`)
3. Start the Spring Boot app on `:8081`
4. Run `./scripts/compose-supergraph.sh` to generate the supergraph
5. Test end-to-end: Postman → Router (:4000) → Subgraph (:8081) → DBs
6. (Optional) Open Apollo Studio to explore the schema from the cloud UI
