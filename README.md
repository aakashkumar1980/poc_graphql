# GraphQL POC — Federated GraphQL with Apollo & Spring Boot

A proof-of-concept demonstrating **Apollo Federation 2** with a **Spring Boot GraphQL subgraph**, two PostgreSQL databases, and the Apollo Router as the gateway.

---

## Quick Start

| Step | Command | When |
|---|---|---|
| **1. Install tools** | `./installation/scripts/install-host-prerequisites.sh` | Once per machine |
| **2. Start infra** | `cd installation && ./scripts/start.sh` | Each work session |
| **3. Run subgraph** | `cd deposit-subgraph && ./gradlew bootRun` | Each work session |
| **4. Compose schema** | `cd installation && ./scripts/compose-supergraph.sh` | After schema changes |
| **5. Test** | `curl -s http://localhost:4000/ -H "Content-Type: application/json" -d '{"query":"{ hello }"}'` | Anytime |

> For detailed installation steps, see [installation/INSTALLATION.md](installation/INSTALLATION.md).

---

## Architecture

### High-Level Data Flow

<p align="center">
  <img src="graphql_poc_data_flow.svg" alt="GraphQL POC Data Flow" width="100%"/>
</p>

### How a GraphQL Query Travels

A client sends a GraphQL query. Here's how it flows through the system:

```
 ┌─────────────┐     ┌──────────────────┐     ┌─────────────────┐     ┌──────────────┐
 │   POSTMAN    │────▶│  APOLLO ROUTER   │────▶│  SPRING BOOT    │────▶│  POSTGRESQL   │
 │  (client)    │◀────│  :4000 (Docker)  │◀────│  :8081 (Host)   │◀────│  :5432/:5433  │
 └─────────────┘     └──────────────────┘     └─────────────────┘     └──────────────┘
      Step 1               Step 2                   Step 3                 Step 4
   Send query         Validate & route          Resolve fields         Fetch data
```

**Step 1 — Client sends query:**
The client (Postman, Apollo Studio, or any HTTP client) sends a GraphQL query to the Apollo Router at `localhost:4000`.

**Step 2 — Router validates and routes:**
Apollo Router receives the query, validates it against the composed supergraph schema, and routes it to the correct subgraph (our Spring Boot app).

**Step 3 — Subgraph resolves fields:**
Spring Boot receives the query, matches it to a resolver (`@QueryMapping`), which calls a service/repository to fetch data via JPA.

**Step 4 — Database returns data:**
PostgreSQL executes the SQL query and returns rows. The data flows back: DB → JPA Entity → Resolver → Router → Client.

### Detailed Architecture Diagram

<p align="center">
  <img src="graphql_poc_architecture.svg" alt="GraphQL POC Full Architecture" width="100%"/>
</p>

---

## Project Structure

```
poc_graphql/
├── README.md                        ← this file
├── graphql_poc_architecture.svg     ← full architecture diagram
├── graphql_poc_data_flow.svg        ← data flow diagram
├── installation/                    ← infrastructure setup (see INSTALLATION.md)
│   ├── INSTALLATION.md              ← Phase 1 & 2: install tools, start infra
│   ├── docker-compose.yml           ← PostgreSQL x2 + Apollo Router
│   ├── postgres/                    ← DB init scripts & seed data
│   ├── router/                      ← Apollo Router & Rover config
│   └── scripts/                     ← Start/stop/status/compose scripts
└── deposit-subgraph/                ← Spring Boot GraphQL subgraph
    ├── build.gradle                 ← Dependencies (Spring GraphQL, JPA, PostgreSQL)
    ├── gradlew                      ← Gradle wrapper
    └── src/main/
        ├── java/com/poc/graphql/
        │   ├── DepositSubgraphApplication.java
        │   ├── entity/Hello.java           ← JPA entity (@Table)
        │   ├── repository/HelloRepository.java  ← Spring Data JPA
        │   └── resolver/HelloResolver.java      ← GraphQL resolver (@QueryMapping)
        └── resources/
            ├── application.yml              ← DB connection, port 8081
            └── graphql/schema.graphqls      ← GraphQL schema definition
```

---

## Develop the Spring Boot Subgraph

> **Prerequisite:** Infrastructure must be running (Phase 2 in [INSTALLATION.md](installation/INSTALLATION.md)).

### How the Subgraph Works

The Spring Boot subgraph is a standard Spring Boot app with **Spring for GraphQL**. Here's how the pieces connect:

```
schema.graphqls          →  Defines what queries/mutations are available
        ↓
HelloResolver.java       →  Maps GraphQL queries to Java methods (@QueryMapping)
        ↓
HelloRepository.java     →  Spring Data JPA interface (auto-generates SQL)
        ↓
Hello.java (Entity)      →  Maps to the "hello" table in PostgreSQL
        ↓
PostgreSQL               →  Stores the actual data
```

### The Hello World Example

**GraphQL Schema** (`schema.graphqls`):
```graphql
type Query {
    hello: String
}
```

**Resolver** (`HelloResolver.java`):
```java
@Controller
public class HelloResolver {
    private final HelloRepository helloRepository;

    @QueryMapping
    public String hello() {
        return helloRepository.findAll()
                .stream().findFirst()
                .map(Hello::getMessage)
                .orElse("No message found");
    }
}
```

**Entity** (`Hello.java`):
```java
@Entity
@Table(name = "hello")
public class Hello {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String message;
}
```

**Database table** (auto-created by `init-accounts.sql`):
```sql
CREATE TABLE hello (
    id      SERIAL PRIMARY KEY,
    message VARCHAR(255) NOT NULL
);
INSERT INTO hello (message) VALUES ('Hello World from GraphQL POC!');
```

### Build & Run

```bash
cd deposit-subgraph/
./gradlew bootRun
```

Wait for: `Started DepositSubgraphApplication`

Test directly:
```bash
curl -s http://localhost:8081/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ hello }"}' | jq .
```
Expected: `{"data":{"hello":"Hello World from GraphQL POC!"}}`

---

## Compose Supergraph & Test End-to-End

> **Prerequisite:** Spring Boot subgraph must be running on `:8081`.

### Compose the Supergraph

```bash
cd installation/
./scripts/compose-supergraph.sh
```

This uses **Rover CLI** to:
1. Introspect the Spring Boot subgraph at `localhost:8081/graphql`
2. Compose a **supergraph schema** using Apollo Federation 2.7.1
3. Restart the Apollo Router with the new schema

> Re-run this after any changes to `schema.graphqls`.

### Test the Full Flow

```bash
# Query through the Apollo Router (full path: Client → Router → Subgraph → DB)
curl -s http://localhost:4000/ \
  -H "Content-Type: application/json" \
  -d '{"query":"{ hello }"}' | jq .
```
Expected: `{"data":{"hello":"Hello World from GraphQL POC!"}}`

### Explore with Apollo Tools

| Tool | URL | What it does |
|---|---|---|
| **Apollo Sandbox** | http://localhost:4000 | Local GraphQL IDE (built into Router) |
| **GraphiQL** | http://localhost:8081/graphiql | Spring Boot's built-in GraphQL IDE |
| **Apollo Studio** | https://studio.apollographql.com/ | Cloud-based schema explorer (optional) |

---

## Component Summary

| Component | Tech | Port | Runs In | Purpose |
|---|---|---|---|---|
| **Test Client** | Postman | — | Host | Send GraphQL queries |
| **Apollo Router** | Apollo Router v1.57.1 | :4000 | Docker | GraphQL Gateway (Federation) |
| **Deposit Subgraph** | Spring Boot 3.3 + Java 21 | :8081 | Host | GraphQL subgraph + business logic |
| **Database 1** | PostgreSQL 15 | :5432 | Docker | accounts, balances, hello |
| **Database 2** | PostgreSQL 15 | :5433 | Docker | transactions, disputes |
| **Rover CLI** | Apollo Rover | — | Host | Schema composition tooling |
| **Apollo Studio** | Cloud | — | Browser | Schema explorer (optional) |

---

## What's Next

After the Hello World demo, the full POC will add:
1. Multi-datasource configuration (connecting to both DBs)
2. Full GraphQL schema with Account, Balance, Transaction, Dispute types
3. Query: `getAccount(id)` — returns account with balance and recent transactions
4. Mutation: `openDispute(transactionId, reason)` — creates a dispute case
5. Apollo Federation 2 directives (`@key`, `@shareable`, etc.)
