USE banking_oltp;
EXPLAIN ANALYZE
SELECT t.transaction_id, t.transaction_date, t.transaction_amount
FROM transaction t
JOIN account a ON a.account_id = t.account_id
WHERE a.branch_id = 'B00010'
  AND t.transaction_date BETWEEN '2020-01-01' AND '2020-12-31';
CREATE INDEX idx_account_customer ON account(customer_id);
CREATE INDEX idx_account_branch   ON account(branch_id);
CREATE INDEX idx_loan_customer    ON loan(customer_id);
CREATE INDEX idx_loan_branch      ON loan(branch_id);
CREATE INDEX idx_transaction_account ON transaction(account_id);
CREATE INDEX idx_transaction_account_date ON transaction(account_id, transaction_date);
CREATE INDEX idx_transaction_date ON transaction(transaction_date);
CREATE INDEX idx_customer_occupation ON customer(occupation);
EXPLAIN ANALYZE
SELECT t.transaction_id, t.transaction_date, t.transaction_amount
FROM transaction t
JOIN account a ON a.account_id = t.account_id
WHERE a.branch_id = 'B00010'
  AND t.transaction_date BETWEEN '2020-01-01' AND '2020-12-31';




