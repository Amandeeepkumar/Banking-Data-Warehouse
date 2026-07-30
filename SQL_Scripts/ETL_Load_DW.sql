USE banking_dw;
SET @start_date = (
    SELECT LEAST(MIN(account_open_date), MIN(transaction_date))
    FROM (
        SELECT account_open_date, NULL AS transaction_date FROM banking_oltp.account
        UNION ALL
        SELECT NULL, transaction_date FROM banking_oltp.transaction
    ) x
);
SET @end_date = (
    SELECT GREATEST(MAX(account_open_date), MAX(transaction_date))
    FROM (
        SELECT account_open_date, NULL AS transaction_date FROM banking_oltp.account
        UNION ALL
        SELECT NULL, transaction_date FROM banking_oltp.transaction
    ) x
);

SET SESSION cte_max_recursion_depth = 20000;
INSERT INTO dim_date (date_key, full_date, day_num, month_num, month_name,
                       quarter_num, year_num, weekday_name, is_weekend)
WITH RECURSIVE calendar AS (
    SELECT @start_date AS dt
    UNION ALL
    SELECT dt + INTERVAL 1 DAY FROM calendar WHERE dt + INTERVAL 1 DAY <= @end_date
)
SELECT
    CAST(DATE_FORMAT(dt, '%Y%m%d') AS UNSIGNED) AS date_key,
    dt,
    DAY(dt),
    MONTH(dt),
    MONTHNAME(dt),
    QUARTER(dt),
    YEAR(dt),
    DAYNAME(dt),
    CASE WHEN DAYOFWEEK(dt) IN (1,7) THEN 1 ELSE 0 END
FROM calendar;
INSERT INTO dim_customer (customer_id, first_name, last_name, city,
                           occupation, dob, age_band)
SELECT
    customer_id, first_name, last_name, city, occupation, dob,
    CASE
        WHEN TIMESTAMPDIFF(YEAR, dob, CURDATE()) < 26 THEN '18-25'
        WHEN TIMESTAMPDIFF(YEAR, dob, CURDATE()) < 36 THEN '26-35'
        WHEN TIMESTAMPDIFF(YEAR, dob, CURDATE()) < 51 THEN '36-50'
        WHEN TIMESTAMPDIFF(YEAR, dob, CURDATE()) < 66 THEN '51-65'
        ELSE '66+'
    END AS age_band
FROM banking_oltp.customer;


INSERT INTO dim_branch (branch_id, branch_name, branch_state)
SELECT branch_id, branch_name, branch_state
FROM banking_oltp.branch;
INSERT INTO dim_account (account_id, account_type, account_status,
                          opening_balance, account_open_date)
SELECT account_id, account_type, account_status, opening_balance,
       account_open_date
FROM banking_oltp.account;
INSERT INTO fact_transaction (transaction_id, date_key, account_key,
                               customer_key, branch_key,
                               transaction_media, transaction_type,
                               transaction_amount)
SELECT
    t.transaction_id,
    CAST(DATE_FORMAT(t.transaction_date, '%Y%m%d') AS UNSIGNED) AS date_key,
    da.account_key,  dc.customer_key, db.branch_key,
    t.transaction_media,
    t.transaction_type,
    t.transaction_amount
    
FROM banking_oltp.transaction t
JOIN banking_oltp.account a  ON a.account_id = t.account_id
JOIN dim_account  da ON da.account_id = a.account_id
JOIN dim_customer dc ON dc.customer_id = a.customer_id
JOIN dim_branch   db ON db.branch_id = a.branch_id;
INSERT INTO fact_loan (loan_id, customer_key, branch_key, loan_amount)
SELECT
    l.loan_id,
    dc.customer_key,
    db.branch_key,
    l.loan_amount
FROM banking_oltp.loan l
JOIN dim_customer dc ON dc.customer_id = l.customer_id
JOIN dim_branch   db ON db.branch_id = l.branch_id;

SELECT 'dim_date' tbl, COUNT(*) row_count FROM dim_date
UNION ALL SELECT 'dim_customer', COUNT(*) FROM dim_customer
UNION ALL SELECT 'dim_branch', COUNT(*) FROM dim_branch
UNION ALL SELECT 'dim_account', COUNT(*) FROM dim_account
UNION ALL SELECT 'fact_transaction', COUNT(*) FROM fact_transaction
UNION ALL SELECT 'fact_loan', COUNT(*) FROM fact_loan;

