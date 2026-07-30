-- Data imported into staging tables using MySQL Workbench

USE banking_oltp;
SELECT 'stg_branch' AS tbl, COUNT(*) AS row_count FROM stg_branch
UNION ALL SELECT 'stg_customer', COUNT(*) FROM stg_customer
UNION ALL SELECT 'stg_account', COUNT(*) FROM stg_account
UNION ALL SELECT 'stg_loan', COUNT(*) FROM stg_loan
UNION ALL SELECT 'stg_transaction', COUNT(*) FROM stg_transaction;

