# GraphQL POC — Installation & Setup Guide (Ubuntu 22.04)

This document covers all software installations and account creation required to run the GraphQL POC.

---

## Architecture Overview (Post-Meeting Changes)

| Component | Tech | Port |
|---|---|---|
| **Test Client** | Postman | — |
| **Apollo Router** | GraphQL Gateway | :4000 |
| **Deposit Subgraph** | Spring Boot 3.3 | :8081 |
| **Database 1** | PostgreSQL (accounts, balances) | :5432 |
| **Database 2** | PostgreSQL (transactions, disputes) | :5433 |
| **Schema Tooling** | Rover CLI | — |
| **Schema Explorer** | Apollo Studio (cloud) | — |

> **Removed from original diagram:** External Systems (WireMock / FIS / Deluxe TRIPs) — not needed for this POC.
> **Changed:** Single database split into two PostgreSQL instances to demonstrate multi-datasource configuration.

---

## 1. Java 17 (required by Spring Boot 3.3)

```bash
# Install OpenJDK 17
sudo apt update
sudo apt install -y openjdk-17-jdk

# Verify
java -version
# Expected: openjdk version "17.x.x"

# Set JAVA_HOME (add to ~/.bashrc for persistence)
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.bashrc
source ~/.bashrc
```

---

## 2. Maven (build tool for Spring Boot)

```bash
sudo apt install -y maven

# Verify
mvn -version
# Expected: Apache Maven 3.x.x
```

---

## 3. Node.js 18+ & npm (required for Rover CLI)

```bash
# Install Node.js 18 LTS via NodeSource
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Verify
node -v    # Expected: v18.x.x
npm -v     # Expected: 9.x.x or higher
```

---

## 4. PostgreSQL (two instances)

### 4a. Install PostgreSQL

```bash
sudo apt install -y postgresql postgresql-client

# Start the service
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### 4b. Create Database 1 — `deposit_accounts` (port 5432)

This is the default PostgreSQL instance. It will hold `accounts` and `balances` tables.

```bash
# Switch to postgres user and create the database + app user
sudo -u postgres psql <<'SQL'
CREATE USER poc_user WITH PASSWORD 'poc_pass';
CREATE DATABASE deposit_accounts OWNER poc_user;
GRANT ALL PRIVILEGES ON DATABASE deposit_accounts TO poc_user;
\q
SQL
```

### 4c. Create Database 2 — `deposit_transactions` (port 5433)

We run a second PostgreSQL instance on a different port. It will hold `transactions` and `disputes` tables.

```bash
# Create a separate data directory for the second instance
sudo mkdir -p /var/lib/postgresql/15/poc2
sudo chown postgres:postgres /var/lib/postgresql/15/poc2

# Initialize the second cluster
sudo -u postgres /usr/lib/postgresql/15/bin/initdb -D /var/lib/postgresql/15/poc2

# Configure it to run on port 5433
sudo -u postgres sed -i "s/#port = 5432/port = 5433/" /var/lib/postgresql/15/poc2/postgresql.conf

# Start the second instance
sudo -u postgres /usr/lib/postgresql/15/bin/pg_ctl -D /var/lib/postgresql/15/poc2 -l /var/log/postgresql/poc2.log start

# Create the database and user on the second instance
sudo -u postgres psql -p 5433 <<'SQL'
CREATE USER poc_user WITH PASSWORD 'poc_pass';
CREATE DATABASE deposit_transactions OWNER poc_user;
GRANT ALL PRIVILEGES ON DATABASE deposit_transactions TO poc_user;
\q
SQL
```

> **Note:** Check your installed PostgreSQL version with `pg_lsclusters`. Replace `15` in paths above with your actual version (e.g., `14`) if different.

### 4d. Verify both databases

```bash
# Database 1 (port 5432)
psql -h localhost -p 5432 -U poc_user -d deposit_accounts -c "SELECT 1;"

# Database 2 (port 5433)
psql -h localhost -p 5433 -U poc_user -d deposit_transactions -c "SELECT 1;"
```

---

## 5. Apollo Router

The Apollo Router is the GraphQL gateway that sits in front of the Spring Boot subgraph.

```bash
# Download and install the Apollo Router binary
curl -sSL https://router.apollo.dev/download/nix/latest | sh

# Move to a location on PATH
sudo mv router /usr/local/bin/router

# Verify
router --version
```

---

## 6. Rover CLI (Apollo schema composition tool)

Rover is used to compose subgraph schemas into a supergraph schema that the Apollo Router uses.

```bash
# Install Rover
curl -sSL https://rover.apollo.dev/nix/latest | sh

# Add to PATH (the installer prints the exact path — typically ~/.rover/bin)
echo 'export PATH="$HOME/.rover/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify
rover --version
```

---

## 7. Postman (Test Client)

### Option A — Snap install (easiest)
```bash
sudo snap install postman
```

### Option B — Download .deb from website
1. Go to https://www.postman.com/downloads/
2. Download the Linux x64 version
3. Extract and run

### Account creation
- Open Postman and sign up for a **free account** (or use without signing in for basic testing).

---

## 8. Apollo Studio — Account Creation (FREE)

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
6. Save these values — they will be needed in `router.yaml` for schema hot-reload.

```bash
# Add to your environment (or a .env file — never commit this)
export APOLLO_KEY="service:graphql-poc:xxxxxxxxxxxxx"
export APOLLO_GRAPH_REF="graphql-poc@current"
```

> **Note:** Apollo Studio free tier is sufficient for this POC. No credit card required.

---

## 9. Git (likely already installed)

```bash
sudo apt install -y git
git --version
```

---

## 10. curl & jq (utility tools)

```bash
sudo apt install -y curl jq
```

---

## Quick Verification Checklist

Run this script to verify all tools are installed:

```bash
echo "=== Installation Verification ==="
echo -n "Java:       "; java -version 2>&1 | head -1
echo -n "Maven:      "; mvn -version 2>&1 | head -1
echo -n "Node.js:    "; node -v
echo -n "npm:        "; npm -v
echo -n "Router:     "; router --version 2>&1 | head -1
echo -n "Rover:      "; rover --version 2>&1 | head -1
echo -n "PostgreSQL: "; psql --version
echo -n "Git:        "; git --version
echo -n "curl:       "; curl --version 2>&1 | head -1
echo -n "jq:         "; jq --version
echo ""
echo "=== PostgreSQL Instances ==="
echo -n "DB1 (5432): "; psql -h localhost -p 5432 -U poc_user -d deposit_accounts -c "SELECT 'OK';" -t 2>/dev/null || echo "NOT CONNECTED"
echo -n "DB2 (5433): "; psql -h localhost -p 5433 -U poc_user -d deposit_transactions -c "SELECT 'OK';" -t 2>/dev/null || echo "NOT CONNECTED"
echo "=== Done ==="
```

---

## Summary of Accounts Needed

| Service | Account Type | Cost | Purpose |
|---|---|---|---|
| **Apollo Studio** | Free tier | $0 | Schema registry, live query explorer |
| **Postman** | Free (optional) | $0 | API testing (can also use without account) |

---

## What's Next

Once all installations are complete, the next step will be:
1. Create the Spring Boot subgraph project with multi-datasource configuration
2. Define the GraphQL schema (`schema.graphqls`)
3. Set up Apollo Router with `supergraph.yaml` and `router.yaml`
4. Seed both databases with sample data
5. Test end-to-end with Postman
