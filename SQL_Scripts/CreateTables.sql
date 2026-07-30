CREATE DATABASE IF NOT EXISTS banking_oltp;
USE banking_oltp;
CREATE TABLE branch (
    branch_id     CHAR(6)      NOT NULL,
    branch_name   VARCHAR(50)  NOT NULL,
    branch_state  VARCHAR(50)  NOT NULL,
    CONSTRAINT pk_branch PRIMARY KEY (branch_id)
);
CREATE TABLE customer (
    customer_id CHAR(6)      NOT NULL,
    first_name  VARCHAR(50)  NOT NULL,
    last_name  VARCHAR(50)  NOT NULL,
    city   VARCHAR(50),
    phone_number VARCHAR(20),
    occupation  VARCHAR(50),
    dob  DATE,
    CONSTRAINT pk_customer PRIMARY KEY (customer_id)
);

CREATE TABLE account (
    account_id  CHAR(6)   NOT NULL,
    customer_id  CHAR(6)  NOT NULL,
    branch_id  CHAR(6) NOT NULL,
    opening_balance  DECIMAL(15,2)  NOT NULL,
    account_open_date DATE     NOT NULL,
    account_type  VARCHAR(20)    NOT NULL,
    account_status  VARCHAR(20)    NOT NULL,
    CONSTRAINT pk_account PRIMARY KEY (account_id),
    CONSTRAINT fk_account_customer FOREIGN KEY (customer_id)
        REFERENCES customer(customer_id),
    CONSTRAINT fk_account_branch FOREIGN KEY (branch_id)
        REFERENCES branch(branch_id),
    CONSTRAINT chk_account_type CHECK (account_type IN
        ('Savings','Checking','Fixed Deposit','Recurring Deposit')),
    CONSTRAINT chk_account_status CHECK (account_status IN
        ('Active','Pending','Closed'))
);

CREATE TABLE loan (
    loan_id  CHAR(6)  NOT NULL,
    customer_id   CHAR(6)   NOT NULL,
    branch_id CHAR(6)  NOT NULL,
    loan_amount   DECIMAL(15,2)  NOT NULL,
    CONSTRAINT pk_loan PRIMARY KEY (loan_id),
    CONSTRAINT fk_loan_customer FOREIGN KEY (customer_id)
        REFERENCES customer(customer_id),
    CONSTRAINT fk_loan_branch FOREIGN KEY (branch_id)
        REFERENCES branch(branch_id)
);
CREATE TABLE transaction (
    transaction_id  CHAR(6) NOT NULL,
    account_id   CHAR(6)  NOT NULL,
    transaction_date   DATE  NOT NULL,
    transaction_media  VARCHAR(20)  NOT NULL,
    transaction_type   VARCHAR(20)  NOT NULL,
    transaction_amount DECIMAL(15,2)  NOT NULL,
    CONSTRAINT pk_transaction PRIMARY KEY (transaction_id),
    CONSTRAINT fk_transaction_account FOREIGN KEY (account_id)
        REFERENCES account(account_id),
    CONSTRAINT chk_transaction_type CHECK (transaction_type IN
        ('Deposit','Withdrawal','Transfer','Purchase'))
);



