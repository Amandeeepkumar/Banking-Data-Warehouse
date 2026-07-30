USE banking_oltp;
INSERT INTO branch (branch_id, branch_name, branch_state)
SELECT branch_id, branch_name, TRIM(branch_state)
FROM (
    SELECT
        TRIM(branch_id)   AS branch_id,
        TRIM(branch_name) AS branch_name,
        branch_state,
        ROW_NUMBER() OVER (PARTITION BY TRIM(branch_id) ORDER BY stg_id) AS rn
    FROM stg_branch
    WHERE branch_id IS NOT NULL AND TRIM(branch_id) <> ''
) d
WHERE rn = 1;

INSERT INTO customer (customer_id, first_name, last_name, city, phone_number, occupation, dob)
                      
SELECT customer_id, first_name, last_name, city, phone_number, occupation, dob
FROM (
    SELECT
        TRIM(customer_id)AS customer_id,
        TRIM(first_name)  AS first_name,
        TRIM(last_name)  AS last_name,
        TRIM(city)  AS city,
        TRIM(phone_number)  AS phone_number,
        TRIM(occupation)  AS occupation,
        STR_TO_DATE(dob, '%Y-%m-%d')    AS dob,
        ROW_NUMBER() OVER (PARTITION BY TRIM(customer_id) ORDER BY stg_id) AS rn
    FROM stg_customer
    WHERE customer_id IS NOT NULL AND TRIM(customer_id) <> ''
) d
WHERE rn = 1
  AND (dob IS NULL OR dob BETWEEN '1900-01-01' AND CURDATE());


INSERT INTO account (account_id, customer_id, branch_id,opening_balance, account_open_date, account_type, account_status)
SELECT account_id, customer_id, branch_id, opening_balance,account_open_date, account_type, account_status
FROM (
    SELECT
        TRIM(a.account_id)  AS account_id,
        TRIM(a.customer_id)  AS customer_id,
        TRIM(a.branch_id)   AS branch_id,
        CAST(a.opening_balance AS DECIMAL(15,2))     AS opening_balance,
        STR_TO_DATE(a.account_open_date, '%Y-%m-%d') AS account_open_date,
        TRIM(a.account_type)    AS account_type,
        TRIM(a.account_status)  AS account_status,
        ROW_NUMBER() OVER (PARTITION BY TRIM(a.account_id) ORDER BY a.stg_id) AS rn
    FROM stg_account a
    WHERE a.account_id IS NOT NULL AND TRIM(a.account_id) <> ''
) d
WHERE rn = 1
  AND opening_balance >= 0
  AND customer_id IN (SELECT customer_id FROM customer)
  AND branch_id IN (SELECT branch_id FROM branch);

INSERT INTO loan (loan_id, customer_id, branch_id, loan_amount)
SELECT loan_id, customer_id, branch_id, loan_amount
FROM (
    SELECT
        TRIM(l.loan_id)  AS loan_id,
        TRIM(l.customer_id)  AS customer_id,
        TRIM(l.branch_id)   AS branch_id,
        CAST(l.loan_amount AS DECIMAL(15,2))  AS loan_amount,
        ROW_NUMBER() OVER (PARTITION BY TRIM(l.loan_id) ORDER BY l.stg_id) AS rn
    FROM stg_loan l
    WHERE l.loan_id IS NOT NULL AND TRIM(l.loan_id) <> ''
) d
WHERE rn = 1
  AND loan_amount > 0
  AND customer_id IN (SELECT customer_id FROM customer)
  AND branch_id IN (SELECT branch_id FROM branch);


INSERT INTO transaction (transaction_id, account_id, transaction_date, transaction_media, transaction_type, transaction_amount)
SELECT transaction_id, account_id, transaction_date, transaction_media, transaction_type, transaction_amount
FROM (
    SELECT
        TRIM(t.transaction_id) AS transaction_id,
        TRIM(t.account_id) AS account_id,
        STR_TO_DATE(t.transaction_date, '%Y-%m-%d')   AS transaction_date,
        TRIM(t.transaction_media)  AS transaction_media,
        TRIM(t.transaction_type)  AS transaction_type,
        CAST(t.transaction_amount AS DECIMAL(15,2)) AS transaction_amount,
        ROW_NUMBER() OVER (PARTITION BY TRIM(t.transaction_id) ORDER BY t.stg_id) AS rn
    FROM stg_transaction t
    WHERE t.transaction_id IS NOT NULL AND TRIM(t.transaction_id) <> ''
) d
WHERE rn = 1
  AND transaction_amount > 0
  AND account_id IN (SELECT account_id FROM account);

SELECT 'branch'  AS tbl, (SELECT COUNT(*) FROM stg_branch)  AS raw_rows, (SELECT COUNT(*) FROM branch) AS clean_rows
UNION ALL
SELECT 'customer', (SELECT COUNT(*) FROM stg_customer),(SELECT COUNT(*) FROM customer)
UNION ALL
SELECT 'account', (SELECT COUNT(*) FROM stg_account), (SELECT COUNT(*) FROM account)
UNION ALL
SELECT 'loan',  (SELECT COUNT(*) FROM stg_loan),  (SELECT COUNT(*) FROM loan)
UNION ALL
SELECT 'transaction', (SELECT COUNT(*) FROM stg_transaction), (SELECT COUNT(*) FROM transaction);

