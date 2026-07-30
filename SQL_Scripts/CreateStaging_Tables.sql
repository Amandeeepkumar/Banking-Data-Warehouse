USE banking_oltp;
CREATE TABLE stg_branch (
    stg_id INT AUTO_INCREMENT PRIMARY KEY,
    branch_id VARCHAR(20),
    branch_name VARCHAR(50),
    branch_state VARCHAR(50)
);

CREATE TABLE stg_customer (
    stg_id  INT AUTO_INCREMENT PRIMARY KEY,
    customer_id  VARCHAR(20),
    first_name  VARCHAR(50),
    last_name  VARCHAR(50),
    city VARCHAR(50),
    phone_number VARCHAR(20),
    occupation VARCHAR(50),
    dob           VARCHAR(20)
);

CREATE TABLE stg_account (
    stg_id INT AUTO_INCREMENT PRIMARY KEY,
    account_id VARCHAR(20),
    customer_id VARCHAR(20),
    branch_id  VARCHAR(20),
    opening_balance VARCHAR(20),
    account_open_date  VARCHAR(20),
    account_type  VARCHAR(20),
    account_status  VARCHAR(20)
);

CREATE TABLE stg_loan (
    stg_id  INT AUTO_INCREMENT PRIMARY KEY,
    loan_id VARCHAR(20),
    customer_id VARCHAR(20),
    branch_id VARCHAR(20),
    loan_amount VARCHAR(20)
);

CREATE TABLE stg_transaction (
    stg_id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id VARCHAR(20),
    account_id VARCHAR(20),
    transaction_date VARCHAR(20),
    transaction_media  VARCHAR(20),
    transaction_type VARCHAR(20),
    transaction_amount VARCHAR(20)
);

