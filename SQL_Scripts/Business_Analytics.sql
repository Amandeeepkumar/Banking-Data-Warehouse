
USE banking_oltp;
-- Top 10 customers by total balance across all their accounts
SELECT c.customer_id, c.first_name, c.last_name,
       SUM(a.opening_balance) AS total_balance
FROM customer c
JOIN account a ON a.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_balance DESC
LIMIT 10;

-- Customer segmentation
WITH ref_date AS (SELECT MAX(transaction_date) AS max_date FROM transaction),
customer_rfm AS (
    SELECT
        a.customer_id,
        DATEDIFF((SELECT max_date FROM ref_date), MAX(t.transaction_date)) AS recency_days,
        COUNT(*) AS frequency,
        SUM(t.transaction_amount) AS monetary
    FROM transaction t
    JOIN account a ON a.account_id = t.account_id
    GROUP BY a.customer_id
)
SELECT customer_id, recency_days, frequency, monetary,
       NTILE(4) OVER (ORDER BY monetary DESC) AS value_quartile
FROM customer_rfm
ORDER BY monetary DESC;

-- Dormant customers: no transaction in the last 180 days

WITH ref_date AS (SELECT MAX(transaction_date) AS max_date FROM transaction)
SELECT c.customer_id, c.first_name, c.last_name,
       MAX(t.transaction_date) AS last_transaction_date
FROM customer c
JOIN account a ON a.customer_id = c.customer_id
LEFT JOIN transaction t ON t.account_id = a.account_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING MAX(t.transaction_date) IS NULL
    OR MAX(t.transaction_date) < (SELECT max_date - INTERVAL 180 DAY FROM ref_date);

-- Customer distribution 
SELECT c.occupation, COUNT(DISTINCT c.customer_id) AS num_customers,
       AVG(a.opening_balance) AS avg_balance
FROM customer c
JOIN account a ON a.customer_id = c.customer_id
GROUP BY c.occupation
ORDER BY num_customers DESC;

-- Account type distribution + average balance per type
SELECT account_type, COUNT(*) AS num_accounts,
       AVG(opening_balance) AS avg_balance,
       SUM(opening_balance) AS total_balance
FROM account
GROUP BY account_type
ORDER BY num_accounts DESC;

-- Account status breakdown 
SELECT account_status, COUNT(*) AS num_accounts,
       ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM account), 2) AS pct_of_total
FROM account
GROUP BY account_status;

-- Account growth trend: new accounts opened per year
SELECT YEAR(account_open_date) AS open_year, COUNT(*) AS accounts_opened
FROM account
GROUP BY YEAR(account_open_date)
ORDER BY open_year;

-- Customers holding more than one account
SELECT customer_id, COUNT(*) AS num_accounts
FROM account
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY num_accounts DESC;

-- Branch ranking by total transaction volume
SELECT b.branch_id, b.branch_name, b.branch_state,
       SUM(t.transaction_amount) AS total_txn_volume,
       RANK() OVER (ORDER BY SUM(t.transaction_amount) DESC) AS volume_rank
FROM branch b
JOIN account a ON a.branch_id = b.branch_id
JOIN transaction t ON t.account_id = a.account_id
GROUP BY b.branch_id, b.branch_name, b.branch_state;

SELECT b.branch_state,
       (SELECT COUNT(*) FROM account a JOIN branch b2 ON b2.branch_id = a.branch_id
        WHERE b2.branch_state = b.branch_state) AS num_accounts,
       (SELECT SUM(a.opening_balance) FROM account a JOIN branch b2 ON b2.branch_id = a.branch_id
        WHERE b2.branch_state = b.branch_state) AS total_balance,
       (SELECT SUM(l.loan_amount) FROM loan l JOIN branch b2 ON b2.branch_id = l.branch_id
        WHERE b2.branch_state = b.branch_state) AS total_loan_amount
FROM branch b
GROUP BY b.branch_state;

-- Branch efficiency: avg transaction size per branch
SELECT b.branch_id, b.branch_name,
       COUNT(t.transaction_id) AS txn_count,
       AVG(t.transaction_amount) AS avg_txn_amount
FROM branch b
JOIN account a ON a.branch_id = b.branch_id
JOIN transaction t ON t.account_id = a.account_id
GROUP BY b.branch_id, b.branch_name
ORDER BY avg_txn_amount DESC;



-- Monthly transaction volume trend
SELECT DATE_FORMAT(transaction_date, '%Y-%m') AS txn_month,
       COUNT(*) AS txn_count,
       SUM(transaction_amount) AS total_amount
FROM transaction
GROUP BY DATE_FORMAT(transaction_date, '%Y-%m')
ORDER BY txn_month;

-- Transaction type distribution
SELECT transaction_type, COUNT(*) AS txn_count,
       SUM(transaction_amount) AS total_amount,
       AVG(transaction_amount) AS avg_amount
FROM transaction
GROUP BY transaction_type;

-- Transaction media usage (Credit Card / Debit Card / Online / etc.)
SELECT transaction_media, COUNT(*) AS txn_count,
       ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM transaction), 2) AS pct_of_total
FROM transaction
GROUP BY transaction_media
ORDER BY txn_count DESC;

-- Day-of-week transaction pattern
SELECT DAYNAME(transaction_date) AS weekday, COUNT(*) AS txn_count,
       SUM(transaction_amount) AS total_amount
FROM transaction
GROUP BY DAYNAME(transaction_date), DAYOFWEEK(transaction_date)
ORDER BY DAYOFWEEK(transaction_date);



-- Loan portfolio by branch
SELECT b.branch_id, b.branch_name, COUNT(l.loan_id) AS num_loans,
       SUM(l.loan_amount) AS total_loan_amount,
       AVG(l.loan_amount) AS avg_loan_amount
FROM loan l
JOIN branch b ON b.branch_id = l.branch_id
GROUP BY b.branch_id, b.branch_name
ORDER BY total_loan_amount DESC;

-- Average loan size by customer occupation
SELECT c.occupation, COUNT(l.loan_id) AS num_loans,
       AVG(l.loan_amount) AS avg_loan_amount
FROM loan l
JOIN customer c ON c.customer_id = l.customer_id
GROUP BY c.occupation
ORDER BY avg_loan_amount DESC;

-- Loan-to-deposit ratio per branch (a core banking risk KPI)
SELECT branch_totals.branch_id, branch_totals.branch_name,
       branch_totals.total_loans, branch_totals.total_deposits,
       ROUND(branch_totals.total_loans / NULLIF(branch_totals.total_deposits, 0), 2) AS loan_to_deposit_ratio
FROM (
    SELECT b.branch_id, b.branch_name,
           (SELECT COALESCE(SUM(l.loan_amount), 0) FROM loan l WHERE l.branch_id = b.branch_id) AS total_loans,
           (SELECT COALESCE(SUM(a.opening_balance), 0) FROM account a WHERE a.branch_id = b.branch_id) AS total_deposits
    FROM branch b
) branch_totals
ORDER BY loan_to_deposit_ratio DESC;

-- Top 10 borrowers
SELECT c.customer_id, c.first_name, c.last_name, SUM(l.loan_amount) AS total_borrowed
FROM loan l
JOIN customer c ON c.customer_id = l.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_borrowed DESC
LIMIT 10;

WITH account_stats AS (
    SELECT account_id, AVG(transaction_amount) AS avg_amt,
           STDDEV(transaction_amount) AS stddev_amt
    FROM transaction
    GROUP BY account_id
    HAVING COUNT(*) >= 3  
)
SELECT t.transaction_id, t.account_id, t.transaction_date, t.transaction_amount,
       s.avg_amt, s.stddev_amt
FROM transaction t
JOIN account_stats s ON s.account_id = t.account_id
WHERE t.transaction_amount > s.avg_amt + 3 * s.stddev_amt
ORDER BY t.transaction_amount DESC;

SELECT account_id, transaction_date, COUNT(*) AS txn_count_that_day,
       SUM(transaction_amount) AS total_amount_that_day
FROM transaction
GROUP BY account_id, transaction_date
HAVING COUNT(*) > 5
ORDER BY txn_count_that_day DESC;


SELECT t.transaction_id, t.account_id, a.account_open_date,
       t.transaction_date, t.transaction_amount,
       DATEDIFF(t.transaction_date, a.account_open_date) AS days_since_open
FROM transaction t
JOIN account a ON a.account_id = t.account_id
WHERE DATEDIFF(t.transaction_date, a.account_open_date) < 30
  AND t.transaction_amount > 500000
ORDER BY t.transaction_amount DESC;



