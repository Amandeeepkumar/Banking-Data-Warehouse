CREATE DATABASE IF NOT EXISTS banking_dw;
USE banking_dw;
CREATE TABLE dim_date (
    date_key INT NOT NULL,   
    full_date DATE  NOT NULL,
    day_num TINYINT NOT NULL,
    month_num  TINYINT NOT NULL,
    month_name VARCHAR(10)   NOT NULL,
    quarter_num  TINYINT  NOT NULL,
    year_num SMALLINT  NOT NULL,
    weekday_name  VARCHAR(10)   NOT NULL,
    is_weekend  TINYINT(1)  NOT NULL,
    CONSTRAINT pk_dim_date PRIMARY KEY (date_key)
);

CREATE TABLE dim_customer (
    customer_key  INT AUTO_INCREMENT,
    customer_id   CHAR(6) NOT NULL,   
    first_name  VARCHAR(50),
    last_name  VARCHAR(50),
    city  VARCHAR(50),
    occupation    VARCHAR(50),
    dob DATE,
    age_band VARCHAR(10),             
    CONSTRAINT pk_dim_customer PRIMARY KEY (customer_key),
    CONSTRAINT uq_dim_customer_bk UNIQUE (customer_id)
);

CREATE TABLE dim_branch (
    branch_key  INT AUTO_INCREMENT,
    branch_id VarcHAR(6) NOT NULL,
    branch_name VARCHAR(50),
    branch_state VARCHAR(50),
    CONSTRAINT pk_dim_branch PRIMARY KEY (branch_key),
    CONSTRAINT uq_dim_branch_bk UNIQUE (branch_id)
);


CREATE TABLE dim_account (
    account_key  INT AUTO_INCREMENT,
    account_id  CHAR(6)  NOT NULL,
    account_type VARCHAR(20),
    account_status  VARCHAR(20),
    opening_balance  DECIMAL(15,2),
    account_open_date DATE,
    CONSTRAINT pk_dim_account PRIMARY KEY (account_key),
    CONSTRAINT uq_dim_account_bk UNIQUE (account_id)
);

CREATE TABLE fact_transaction (
    transaction_key INT AUTO_INCREMENT,
    transaction_id   CHAR(6)  NOT NULL,
    date_key INT  NOT NULL,
    account_key  INT NOT NULL,
    customer_key  INT NOT NULL,
    branch_key   INT NOT NULL,
    transaction_media VARCHAR(20),
    transaction_type  VARCHAR(20),
    transaction_amount DECIMAL(15,2)  NOT NULL,
    CONSTRAINT pk_fact_transaction PRIMARY KEY (transaction_key),
    CONSTRAINT fk_ft_date FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    CONSTRAINT fk_ft_account FOREIGN KEY (account_key) REFERENCES dim_account(account_key),
    CONSTRAINT fk_ft_customer FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key),
    CONSTRAINT fk_ft_branch FOREIGN KEY (branch_key) REFERENCES dim_branch(branch_key)
);

CREATE TABLE fact_loan (
    loan_key INT AUTO_INCREMENT,
    loan_id  CHAR(6) NOT NULL,   
    customer_key  INT NOT NULL,
    branch_key INT  NOT NULL,
    loan_amount DECIMAL(15,2)  NOT NULL,
    CONSTRAINT pk_fact_loan PRIMARY KEY (loan_key),
    CONSTRAINT fk_fl_customer FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key),
    CONSTRAINT fk_fl_branch FOREIGN KEY (branch_key) REFERENCES dim_branch(branch_key)
);
CREATE INDEX idx_ft_date ON fact_transaction(date_key);
CREATE INDEX idx_ft_account ON fact_transaction(account_key);
CREATE INDEX idx_ft_customer ON fact_transaction(customer_key);
CREATE INDEX idx_ft_branch ON fact_transaction(branch_key);
CREATE INDEX idx_fl_customer ON fact_loan(customer_key);
CREATE INDEX idx_fl_branch ON fact_loan(branch_key);

