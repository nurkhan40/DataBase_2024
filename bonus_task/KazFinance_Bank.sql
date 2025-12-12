/*
=============================================================================
 KBTU | Database Systems | Bonus Laboratory Work
 Student: KYRYKBAY NURKHAN
 Project: KazFinance Bank Transaction System
 
 OVERVIEW:
 This script implements a core banking system handling multi-currency accounts,
 ACID-compliant transfers, security reporting, and batched salary processing.
 
 STRUCTURE:
 1. DDL & Schema Setup (Tables)
 2. Data Seeding (Dummy Data)
 3. Task 1: Transaction Management (Stored Procedure with ACID & Locking)
 4. Task 2: Analytics & Reporting (Views with Window Functions)
 5. Task 3: Performance Optimization (Indexing Strategy)
 6. Task 4: Advanced Batch Processing (Salary Procedures with Advisory Locks)
=============================================================================
*/

-- ==========================================================================
-- SECTION 1: DATABASE SCHEMA (DDL)
-- Description: Creating tables with strict constraints to ensure data integrity.
-- ==========================================================================

-- 1.1 Customers Table
-- Design: Used CHECK constraints for 'status' to prevent invalid states.
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    iin VARCHAR(12) UNIQUE NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'blocked', 'frozen')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    daily_limit_kzt DECIMAL(15, 2) DEFAULT 500000.00
);

-- 1.2 Accounts Table
-- Design: Accounts are linked to customers. 'currency' is restricted to supported types[cite: 14].
CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    account_number VARCHAR(34) UNIQUE NOT NULL, -- IBAN length standard
    currency VARCHAR(3) CHECK (currency IN ('KZT', 'USD', 'EUR', 'RUB')),
    balance DECIMAL(15, 2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT TRUE,
    opened_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP
);

-- 1.3 Exchange Rates
-- Design: Stores conversion rates. 'valid_to' allows for historical rate tracking.
CREATE TABLE exchange_rates (
    rate_id SERIAL PRIMARY KEY,
    from_currency VARCHAR(3),
    to_currency VARCHAR(3),
    rate DECIMAL(10, 6),
    valid_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP
);

-- 1.4 Transactions
-- Design: Central ledger. Records both original currency amount and KZT equivalent for reporting.
CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    from_account_id INT REFERENCES accounts(account_id),
    to_account_id INT REFERENCES accounts(account_id),
    amount DECIMAL(15, 2),
    currency VARCHAR(3),
    amount_kzt DECIMAL(15, 2), -- Calculated field for uniform reporting
    type VARCHAR(20) CHECK (type IN ('transfer', 'deposit', 'withdrawal')),
    status VARCHAR(20) CHECK (status IN ('pending', 'completed', 'failed', 'reversed')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    description TEXT
);

-- 1.5 Audit Log
-- Design: JSONB columns store flexible data (old/new states) for forensic analysis[cite: 14].
CREATE TABLE audit_log (
    log_id SERIAL PRIMARY KEY,
    table_name VARCHAR(50),
    record_id INT,
    action VARCHAR(10),
    old_values JSONB,
    new_values JSONB,
    changed_by VARCHAR(50),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45)
);

-- ==========================================================================
-- SECTION 2: DATA SEEDING
-- Description: Populating tables with initial dummy data for testing purposes[cite: 15].
-- ==========================================================================

INSERT INTO customers (iin, full_name, status, daily_limit_kzt) VALUES
('111111111111', 'Aliya Nurlanova', 'active', 1000000),
('222222222222', 'Dmitry Ivanov', 'active', 500000),
('333333333333', 'John Doe', 'blocked', 0),
('999999999999', 'Tech Corp LLP', 'active'),
('888888888888', 'Hardworking Employee', 'active');

INSERT INTO accounts (customer_id, account_number, currency, balance) VALUES
(1, 'KZ01000001', 'KZT', 150000.00),
(1, 'KZ01000002', 'USD', 1000.00),
(2, 'KZ02000001', 'KZT', 50000.00),
(2, 'KZ02000002', 'EUR', 200.00),
(3, 'KZ03000001', 'KZT', 10000.00),
(4, 'KZ_COMP_MAIN', 'KZT', 10000000.00),
(5, 'KZ_EMP_01', 'KZT', 0.00); 

-- Exchange Rates (Mock values)
INSERT INTO exchange_rates (from_currency, to_currency, rate, valid_to) VALUES
('USD', 'KZT', 495.00, '2026-01-01'),
('KZT', 'USD', 0.0020, '2026-01-01'),
('EUR', 'KZT', 520.00, '2026-01-01'),
('KZT', 'EUR', 0.0019, '2026-01-01'),
('USD', 'EUR', 0.95, '2026-01-01'),
('EUR', 'USD', 1.05, '2026-01-01'),
('KZT', 'KZT', 1.00, '2026-01-01');

-- ==========================================================================
-- SECTION 3: TASK 1 - TRANSACTION MANAGEMENT (ACID)
-- Description: Stored procedure to handle transfers with strict validation and locking[cite: 18].
-- ==========================================================================

CREATE OR REPLACE PROCEDURE process_transfer(
    p_from_acc_num VARCHAR,
    p_to_acc_num VARCHAR,
    p_amount DECIMAL,
    p_currency VARCHAR,
    p_description TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_sender_acc_id INT; v_sender_cust_id INT; v_sender_balance DECIMAL;
    v_sender_currency VARCHAR; v_sender_status VARCHAR; v_sender_limit DECIMAL;
    v_receiver_acc_id INT; v_receiver_currency VARCHAR;
    
    v_deduct_amount DECIMAL; 
    v_add_amount DECIMAL;    
    v_amount_kzt DECIMAL;    
    v_exchange_rate DECIMAL;
    v_current_daily_total DECIMAL;
    
    v_old_sender_data JSONB;
    v_new_sender_data JSONB;
    
BEGIN
    IF p_amount <= 0 THEN RAISE EXCEPTION 'Invalid amount: Must be positive.'; END IF;

    -- 2. LOCKING STRATEGY (CRITICAL) [cite: 27]
    -- We use FOR UPDATE to lock the sender's row. This prevents Race Conditions
    -- (e.g., trying to spend the same money twice concurrently).
    SELECT a.account_id, a.customer_id, a.balance, a.currency, c.status, c.daily_limit_kzt
    INTO v_sender_acc_id, v_sender_cust_id, v_sender_balance, v_sender_currency, v_sender_status, v_sender_limit
    FROM accounts a
    JOIN customers c ON a.customer_id = c.customer_id
    WHERE a.account_number = p_from_acc_num
    FOR UPDATE; 

    IF NOT FOUND THEN RAISE EXCEPTION 'Sender account not found.'; END IF;
    IF v_sender_status != 'active' THEN RAISE EXCEPTION 'Sender customer status is %', v_sender_status; END IF;

    -- 3. Lock Receiver Account
    SELECT account_id, currency INTO v_receiver_acc_id, v_receiver_currency
    FROM accounts WHERE account_number = p_to_acc_num FOR UPDATE;

    IF NOT FOUND THEN RAISE EXCEPTION 'Receiver account not found.'; END IF;

    -- 4. Currency Conversion Logic
    IF p_currency = 'KZT' THEN v_amount_kzt := p_amount;
    ELSE
        SELECT rate INTO v_exchange_rate FROM exchange_rates WHERE from_currency = p_currency AND to_currency = 'KZT' LIMIT 1;
        v_amount_kzt := p_amount * COALESCE(v_exchange_rate, 0);
    END IF;

    IF v_sender_currency = p_currency THEN v_deduct_amount := p_amount;
    ELSE
        SELECT rate INTO v_exchange_rate FROM exchange_rates WHERE from_currency = p_currency AND to_currency = v_sender_currency LIMIT 1;
        v_deduct_amount := p_amount * v_exchange_rate;
    END IF;

    IF v_receiver_currency = p_currency THEN v_add_amount := p_amount;
    ELSE
        SELECT rate INTO v_exchange_rate FROM exchange_rates WHERE from_currency = p_currency AND to_currency = v_receiver_currency LIMIT 1;
        v_add_amount := p_amount * v_exchange_rate;
    END IF;

    -- 5. Business Rule Checks (Balance & Limits) [cite: 25, 26]
    IF v_sender_balance < v_deduct_amount THEN
        RAISE EXCEPTION 'Insufficient funds. Balance: %, Required: %', v_sender_balance, v_deduct_amount;
    END IF;

    SELECT COALESCE(SUM(amount_kzt), 0) INTO v_current_daily_total
    FROM transactions
    WHERE from_account_id = v_sender_acc_id AND created_at::DATE = CURRENT_DATE AND status = 'completed';

    IF (v_current_daily_total + v_amount_kzt) > v_sender_limit THEN
        RAISE EXCEPTION 'Daily limit exceeded. Limit: %, Used: %', v_sender_limit, v_current_daily_total;
    END IF;

    -- 6. EXECUTION (The "Savepoint" logic is handled by the wrapping Transaction)
    v_old_sender_data := jsonb_build_object('balance', v_sender_balance);

    UPDATE accounts SET balance = balance - v_deduct_amount WHERE account_id = v_sender_acc_id;
    UPDATE accounts SET balance = balance + v_add_amount WHERE account_id = v_receiver_acc_id;

    INSERT INTO transactions (from_account_id, to_account_id, amount, currency, amount_kzt, type, status, completed_at, description)
    VALUES (v_sender_acc_id, v_receiver_acc_id, p_amount, p_currency, v_amount_kzt, 'transfer', 'completed', CURRENT_TIMESTAMP, p_description);

    v_new_sender_data := jsonb_build_object('balance', v_sender_balance - v_deduct_amount);
    INSERT INTO audit_log (table_name, record_id, action, old_values, new_values, changed_by)
    VALUES ('accounts', v_sender_acc_id, 'UPDATE', v_old_sender_data, v_new_sender_data, 'system_process');

EXCEPTION WHEN OTHERS THEN
    INSERT INTO audit_log (table_name, action, old_values, changed_by, new_values)
    VALUES ('transactions', 'FAILURE', jsonb_build_object('error', SQLERRM), 'system_process', 
            jsonb_build_object('from', p_from_acc_num, 'amount', p_amount));
    
    INSERT INTO transactions (amount, currency, type, status, description, created_at)
    VALUES (p_amount, p_currency, 'transfer', 'failed', CONCAT(p_description, ' | Error: ', SQLERRM), CURRENT_TIMESTAMP);
    
    RAISE NOTICE 'Transaction Failed: %', SQLERRM;
END;
$$;

-- TEST CASE FOR TASK 1:
-- CALL process_transfer('KZ01000001', 'KZ02000001', 5000, 'KZT', 'Test Transfer');


-- ==========================================================================
-- SECTION 4: TASK 2 - VIEWS FOR REPORTING
-- Description: Analytical views for compliance and monitoring[cite: 30].
-- ==========================================================================

-- 4.1 Customer Balance Summary
-- Feature: Uses DENSE_RANK() to gamify/rank wealth and SUM() OVER for aggregation[cite: 33, 34].
CREATE OR REPLACE VIEW customer_balance_summary AS
WITH account_balances_kzt AS (
    SELECT 
        a.customer_id, a.account_number, a.currency, a.balance,
        CASE 
            WHEN a.currency = 'KZT' THEN a.balance
            ELSE a.balance * (SELECT rate FROM exchange_rates er WHERE er.from_currency = a.currency AND er.to_currency = 'KZT' ORDER BY valid_from DESC LIMIT 1)
        END AS balance_kzt
    FROM accounts a WHERE a.is_active = TRUE
)
SELECT 
    c.full_name, ab.account_number, ab.currency, ab.balance,
    SUM(ab.balance_kzt) OVER (PARTITION BY c.customer_id) as total_net_worth_kzt,
    DENSE_RANK() OVER (ORDER BY SUM(ab.balance_kzt) OVER (PARTITION BY c.customer_id) DESC) as wealth_rank
FROM customers c
JOIN account_balances_kzt ab ON c.customer_id = ab.customer_id;

-- 4.2 Daily Transaction Report
CREATE OR REPLACE VIEW daily_transaction_report AS
SELECT 
    created_at::DATE as report_date,
    type as txn_type,
    SUM(amount_kzt) as total_volume_kzt,
    COUNT(*) as txn_count,
    SUM(SUM(amount_kzt)) OVER (PARTITION BY type ORDER BY created_at::DATE) as running_total_volume,
    ROUND((SUM(amount_kzt) - LAG(SUM(amount_kzt)) OVER (PARTITION BY type ORDER BY created_at::DATE)) / 
    NULLIF(LAG(SUM(amount_kzt)) OVER (PARTITION BY type ORDER BY created_at::DATE), 0) * 100, 2) as growth_pct
FROM transactions
WHERE status = 'completed'
GROUP BY created_at::DATE, type;

-- 4.3 Suspicious Activity View
-- Feature: Uses SECURITY BARRIER to prevent info leakage before filtering[cite: 39, 40].
CREATE OR REPLACE VIEW suspicious_activity_view WITH (security_barrier = true) AS
SELECT transaction_id, created_at, 'High Value' as suspicion_type, amount_kzt as details
FROM transactions WHERE amount_kzt > 5000000
UNION ALL
SELECT NULL, date_trunc('hour', created_at), 'High Frequency', COUNT(*)
FROM transactions
GROUP BY from_account_id, date_trunc('hour', created_at) HAVING COUNT(*) > 10;


-- ==========================================================================
-- SECTION 5: TASK 3 - PERFORMANCE OPTIMIZATION (INDEXES)
-- Description: Strategic indexing to speed up critical queries[cite: 41].
-- ==========================================================================

-- 5.1 Expression Index
CREATE INDEX idx_customers_email_lower ON customers (lower(email));

-- 5.2 Partial Index
CREATE INDEX idx_accounts_active ON accounts (account_number) WHERE is_active = TRUE;

-- 5.3 Composite Covering Index (INCLUDE)
CREATE INDEX idx_transactions_history_cover ON transactions (from_account_id, created_at DESC) INCLUDE (amount, currency, type);

-- 5.4 Hash Index
CREATE INDEX idx_transactions_type_hash ON transactions USING HASH (type);

-- 5.5 GIN Index
CREATE INDEX idx_audit_log_new_values ON audit_log USING GIN (new_values);


-- ==========================================================================
-- SECTION 6: TASK 4 - ADVANCED BATCH PROCESSING
-- Description: Handling bulk salary payments with atomic requirements[cite: 49].
-- ==========================================================================

CREATE OR REPLACE PROCEDURE process_salary_batch(
    p_company_acc_num VARCHAR,
    p_batch_data JSONB,
    INOUT p_successful_count INT DEFAULT 0,
    INOUT p_failed_count INT DEFAULT 0,
    INOUT p_failed_details JSONB DEFAULT '[]'::jsonb
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_comp_acc_id INT; v_comp_balance DECIMAL; v_comp_currency VARCHAR;
    v_total_batch_amount DECIMAL := 0;
    v_total_processed_amount DECIMAL := 0;
    v_payment_record JSONB;
    v_emp_iin VARCHAR; v_emp_amount DECIMAL; v_emp_acc_id INT;
BEGIN
    -- 1. ADVISORY LOCK
    SELECT account_id, balance, currency INTO v_comp_acc_id, v_comp_balance, v_comp_currency
    FROM accounts WHERE account_number = p_company_acc_num FOR UPDATE;
    
    PERFORM pg_advisory_xact_lock(v_comp_acc_id);

    -- 2. Validate Total Batch Amount
    SELECT COALESCE(SUM((x->>'amount')::DECIMAL), 0) INTO v_total_batch_amount
    FROM jsonb_array_elements(p_batch_data) x;

    IF v_comp_balance < v_total_batch_amount THEN
        RAISE EXCEPTION 'Insufficient company funds for batch.';
    END IF;

    -- 3. Loop through Employees
    FOR v_payment_record IN SELECT * FROM jsonb_array_elements(p_batch_data)
    LOOP
        v_emp_iin := v_payment_record->>'iin';
        v_emp_amount := (v_payment_record->>'amount')::DECIMAL;

        BEGIN
            SELECT account_id INTO v_emp_acc_id FROM accounts a
            JOIN customers c ON a.customer_id = c.customer_id
            WHERE c.iin = v_emp_iin AND a.currency = v_comp_currency AND a.is_active = TRUE
            LIMIT 1;

            IF v_emp_acc_id IS NULL THEN RAISE EXCEPTION 'Employee account not found'; END IF;

            UPDATE accounts SET balance = balance + v_emp_amount WHERE account_id = v_emp_acc_id;
            
            INSERT INTO transactions (from_account_id, to_account_id, amount, currency, amount_kzt, type, status, completed_at, description)
            VALUES (v_comp_acc_id, v_emp_acc_id, v_emp_amount, v_comp_currency, v_emp_amount, 'deposit', 'completed', CURRENT_TIMESTAMP, 'Salary');

            v_total_processed_amount := v_total_processed_amount + v_emp_amount;
            p_successful_count := p_successful_count + 1;

        EXCEPTION WHEN OTHERS THEN
            p_failed_count := p_failed_count + 1;
            p_failed_details := p_failed_details || jsonb_build_object('iin', v_emp_iin, 'error', SQLERRM);
        END;
    END LOOP;

    -- 4. Final Atomic Update for Company [cite: 58]
    IF v_total_processed_amount > 0 THEN
        UPDATE accounts SET balance = balance - v_total_processed_amount WHERE account_id = v_comp_acc_id;
    END IF;
END;
$$;

-- Good Bye!