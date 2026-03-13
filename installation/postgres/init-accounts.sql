-- ============================================
-- DATABASE 1: deposit_accounts
-- Tables: accounts, balances
-- ============================================

CREATE TABLE IF NOT EXISTS accounts (
    id          VARCHAR(36) PRIMARY KEY,
    customer_id VARCHAR(36)    NOT NULL,
    account_number VARCHAR(20) NOT NULL,
    status      VARCHAR(20)    NOT NULL DEFAULT 'ACTIVE',
    created_at  TIMESTAMP      NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS balances (
    id          VARCHAR(36) PRIMARY KEY,
    account_id  VARCHAR(36) NOT NULL REFERENCES accounts(id),
    available   NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    current_bal NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    currency    VARCHAR(3)    NOT NULL DEFAULT 'USD',
    updated_at  TIMESTAMP     NOT NULL DEFAULT NOW()
);

-- ============================================
-- SEED DATA
-- ============================================

INSERT INTO accounts (id, customer_id, account_number, status) VALUES
    ('ACT-234', 'CUST-001', '****1234', 'ACTIVE'),
    ('ACT-567', 'CUST-002', '****5678', 'ACTIVE'),
    ('ACT-890', 'CUST-003', '****9012', 'DORMANT')
ON CONFLICT (id) DO NOTHING;

INSERT INTO balances (id, account_id, available, current_bal, currency) VALUES
    ('BAL-001', 'ACT-234', 4850.00, 5100.00, 'USD'),
    ('BAL-002', 'ACT-567', 12340.50, 12340.50, 'USD'),
    ('BAL-003', 'ACT-890', 200.00, 200.00, 'USD')
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- TEST DATA (Hello World demo)
-- ============================================

CREATE TABLE IF NOT EXISTS hello (
    id      SERIAL PRIMARY KEY,
    message VARCHAR(255) NOT NULL
);

INSERT INTO hello (message) VALUES ('Hello World from GraphQL POC!')
ON CONFLICT DO NOTHING;
