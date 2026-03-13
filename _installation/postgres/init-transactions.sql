-- ============================================
-- DATABASE 2: deposit_transactions
-- Tables: transactions, disputes
-- ============================================

CREATE TABLE IF NOT EXISTS transactions (
    id          VARCHAR(36) PRIMARY KEY,
    account_id  VARCHAR(36)    NOT NULL,
    amount      NUMERIC(15,2)  NOT NULL,
    description VARCHAR(255)   NOT NULL,
    merchant    VARCHAR(255),
    txn_date    TIMESTAMP      NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS disputes (
    id                       VARCHAR(36) PRIMARY KEY,
    transaction_id           VARCHAR(36)  NOT NULL REFERENCES transactions(id),
    account_id               VARCHAR(36)  NOT NULL,
    amount                   NUMERIC(15,2) NOT NULL,
    reason                   VARCHAR(500)  NOT NULL,
    status                   VARCHAR(20)   NOT NULL DEFAULT 'OPENED',
    provisioned_amount       NUMERIC(15,2),
    estimated_resolution_date DATE,
    created_at               TIMESTAMP     NOT NULL DEFAULT NOW()
);

-- ============================================
-- SEED DATA
-- ============================================

INSERT INTO transactions (id, account_id, amount, description, merchant, txn_date) VALUES
    ('TXN-8821', 'ACT-234', -42.50,  'Starbucks #4421',       'Starbucks',        '2026-03-01 08:15:00'),
    ('TXN-8822', 'ACT-234', -125.00, 'Amazon.com',            'Amazon',           '2026-02-28 14:30:00'),
    ('TXN-8823', 'ACT-234',  2500.00, 'Direct Deposit - Payroll', NULL,            '2026-02-27 06:00:00'),
    ('TXN-8824', 'ACT-234', -18.75,  'Netflix Subscription',  'Netflix',          '2026-02-26 00:00:00'),
    ('TXN-8825', 'ACT-234', -65.30,  'Shell Gas Station',     'Shell',            '2026-02-25 17:45:00'),
    ('TXN-9901', 'ACT-567', -200.00, 'Walmart Supercenter',   'Walmart',          '2026-03-02 11:00:00'),
    ('TXN-9902', 'ACT-567',  5000.00, 'Wire Transfer In',      NULL,              '2026-03-01 09:00:00')
ON CONFLICT (id) DO NOTHING;
