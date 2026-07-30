USE banking_oltp;
-- Customer Accounts with Branch Details
SELECT c.customer_id, c.first_name, c.last_name,
       a.account_id, a.account_type, a.opening_balance,
       b.branch_name, b.branch_state
FROM customer c
JOIN account a ON a.customer_id = c.customer_id
JOIN branch  b ON b.branch_id  = a.branch_id;

-- Customers with Loan Information 
SELECT c.customer_id, c.first_name, c.last_name,
       l.loan_id, l.loan_amount
FROM customer c
LEFT JOIN loan l ON l.customer_id = c.customer_id;

-- Transaction Details with Customer and Branch Context
SELECT t.transaction_id, t.transaction_date, t.transaction_type,
       t.transaction_amount, c.first_name, c.last_name, b.branch_state
FROM transaction t
JOIN account  a ON a.account_id  = t.account_id
JOIN customer c ON c.customer_id = a.customer_id
JOIN branch   b ON b.branch_id   = a.branch_id;

-- Accounts Above Average Opening Balance
SELECT customer_id, account_id, opening_balance
FROM account
WHERE opening_balance > (SELECT AVG(opening_balance) FROM account);

-- Latest Transaction Date for Each Customer
SELECT c.customer_id, c.first_name, c.last_name,
       (SELECT MAX(t.transaction_date)
        FROM transaction t
        JOIN account a ON a.account_id = t.account_id
        WHERE a.customer_id = c.customer_id) AS last_transaction_date
FROM customer c;

-- Branches with Above-Average Loan Count
SELECT branch_id, total_loans
FROM (
    SELECT branch_id, COUNT(*) AS total_loans
    FROM loan
    GROUP BY branch_id
) branch_loans
WHERE total_loans > (SELECT COUNT(*) / COUNT(DISTINCT branch_id) FROM loan);

-- Monthly Transaction Summary
WITH monthly_txn AS (
    SELECT DATE_FORMAT(transaction_date, '%Y-%m') AS txn_month,
           transaction_type,
           SUM(transaction_amount) AS total_amount,
           COUNT(*) AS txn_count
    FROM transaction
    GROUP BY DATE_FORMAT(transaction_date, '%Y-%m'), transaction_type
)
SELECT * FROM monthly_txn ORDER BY txn_month, transaction_type;

-- Top 10 Customers by Transaction Volume
WITH customer_totals AS (
    SELECT a.customer_id, SUM(t.transaction_amount) AS total_txn_amount
    FROM transaction t
    JOIN account a ON a.account_id = t.account_id
    GROUP BY a.customer_id
),
ranked_customers AS (
    SELECT customer_id, total_txn_amount,
           RANK() OVER (ORDER BY total_txn_amount DESC) AS spend_rank
    FROM customer_totals
)
SELECT * FROM ranked_customers WHERE spend_rank <= 10;

-- Monthly Transaction Timeline (Including Empty Months)
WITH RECURSIVE month_series AS (
    SELECT DATE_FORMAT(MIN(transaction_date), '%Y-%m-01') AS month_start
    FROM transaction
    UNION ALL
    SELECT DATE_ADD(month_start, INTERVAL 1 MONTH)
    FROM month_series
    WHERE month_start < (SELECT MAX(transaction_date) FROM transaction)
)
SELECT
    DATE_FORMAT(m.month_start, '%Y-%m') AS month,
    COALESCE(SUM(t.transaction_amount), 0) AS total_amount,
    COUNT(t.transaction_id) AS txn_count
FROM month_series m
LEFT JOIN transaction t
       ON DATE_FORMAT(t.transaction_date, '%Y-%m') = DATE_FORMAT(m.month_start, '%Y-%m')
GROUP BY m.month_start
ORDER BY m.month_start;

-- Running Account Balance by Transaction
SELECT account_id, transaction_id, transaction_date, transaction_type,
       transaction_amount,
       SUM(CASE WHEN transaction_type = 'Deposit' THEN transaction_amount
                WHEN transaction_type = 'Withdrawal' THEN -transaction_amount
                ELSE 0 END)
           OVER (PARTITION BY account_id ORDER BY transaction_date, transaction_id
                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_balance
FROM transaction
ORDER BY account_id, transaction_date;

-- Customer Ranking by Transaction Amount Within Each Branch
WITH cust_branch_totals AS (
    SELECT a.customer_id, a.branch_id, SUM(t.transaction_amount) AS total_amount
    FROM transaction t
    JOIN account a ON a.account_id = t.account_id
    GROUP BY a.customer_id, a.branch_id
)
SELECT customer_id, branch_id, total_amount,
       RANK() OVER (PARTITION BY branch_id ORDER BY total_amount DESC) AS branch_rank
FROM cust_branch_totals;

-- LAG: month-over-month change in total transaction volume
WITH monthly AS (
    SELECT DATE_FORMAT(transaction_date, '%Y-%m') AS txn_month,
           SUM(transaction_amount) AS total_amount
    FROM transaction
    GROUP BY DATE_FORMAT(transaction_date, '%Y-%m')
)
SELECT txn_month, total_amount,
       LAG(total_amount) OVER (ORDER BY txn_month) AS prev_month_amount,
       total_amount - LAG(total_amount) OVER (ORDER BY txn_month) AS mom_change
FROM monthly
ORDER BY txn_month;

-- Balance tiering
SELECT account_id, opening_balance,
       CASE
           WHEN opening_balance < 10000 THEN 'Low'
           WHEN opening_balance < 100000 THEN 'Medium'
           WHEN opening_balance < 500000 THEN 'High'
           ELSE 'Premium'
       END AS balance_tier
FROM account;

-- Customer Ranking by Transaction Amount Within Each Branch
SELECT customer_id, first_name, last_name,
       TIMESTAMPDIFF(YEAR, dob, CURDATE()) AS age,
       CASE
           WHEN TIMESTAMPDIFF(YEAR, dob, CURDATE()) < 30 THEN 'Young Adult'
           WHEN TIMESTAMPDIFF(YEAR, dob, CURDATE()) < 60 THEN 'Working Age'
           ELSE 'Senior'
       END AS life_stage
FROM customer;

