# Banking Data Warehouse & Advanced SQL Analytics

End-to-end SQL project: a 3NF banking OLTP system redesigned into a star-schema data warehouse, with advanced SQL querying (joins, subqueries, CTEs, recursive CTEs, window functions), business analytics, and performance tuning  built on a  banking dataset.

## Business Objective
Simulate a bank's data platform: capture day-to-day transactional data (customers, accounts, branches, loans, transactions), clean and warehouse it, then answer real banking questions like  customer value, branch performance, loan risk, and fraud signals.

**KPIs tracked:** account growth, transaction volume trend, loan-to-deposit ratio, customer RFM segmentation, dormant-customer rate, anomalous transaction rate.

## Dataset
 5 related CSVs: Branch, Customer, Account, Loan, Transaction.

**Data quality note:** the raw CSVs contain each business key repeated 3× with conflicting attribute values (not clean duplicates). This was found and resolved during the cleaning step  see [`Documentation/Data_Dictionary.md`](Documentation/Data_Dictionary.md) for the full explanation. True unique counts after cleaning: 50 branches, 1,000 customers, 1,000 accounts, 500 loans, 5,000 transactions, spanning transactions from 2013 to 2023.

## Architecture
Raw CSV → Staging (unconstrained) → Data Cleaning (dedup/standardize/validate) → OLTP (3NF) → ETL → Data Warehouse (star schema) → Business Analytics

Full diagram: [`Documentation/Architecture.md`](Documentation/Architecture.md)
ER diagrams (OLTP + star schema): [`ER Diagram/ER_Diagram.md`](ER%20Diagram/ER_Diagram.md)

## Tech Stack
MySQL 8 · pure SQL ETL · MySQL Workbench

## Folder Structure
```
Banking-Data-Warehouse/
├── Dataset/                  # Source CSVs
├── ER Diagram/                # Mermaid ER diagrams (OLTP + star schema)
├── Documentation/             # Data dictionary, architecture notes
├── SQL Scripts/               # Numbered scripts, run in order
└── Screenshots/                # Query results, EXPLAIN ANALYZE output
```

## How to Run
Execute in MySQL Workbench, in order:

| # | Script | Purpose |
|---|---|---|
| 01 | CreateTables.sql | OLTP schema (3NF, constraints) |
| 02 | CreateStaging.sql | Unconstrained staging tables |
| 03 | InsertStagingData.sql | Load raw CSVs into staging (via Table Data Import Wizard) |
| 04 | DataCleaning.sql | Dedup, standardize, validate → OLTP |
| 05 | CreateDW.sql | Star schema (dims + facts) |
| 06 | ETL_LoadDW.sql | Populate the data warehouse |
| 07 | AdvancedSQL_Queries.sql | Joins, subqueries, CTEs, recursive CTE, window functions, CASE |
| 12 | BusinessAnalytics.sql | Customer, account, branch, transaction, loan, fraud analytics |
| 13 | Indexing.sql | EXPLAIN ANALYZE before/after, indexing |

Staging tables were loaded via MySQL Workbench's **Table Data Import Wizard** (Right-click table → Table Data Import Wizard → select matching CSV) rather than `LOAD DATA LOCAL INFILE`, to avoid local-infile permission issues.

## Key SQL Techniques Demonstrated
- 3NF normalization + star-schema (dimensional) design, two fact tables at different grains
- Staging-layer ETL pattern for handling dirty source data
- Window functions: `RANK()`, `NTILE()`, `LAG()`, running totals
- Recursive CTEs: calendar/date-spine generation, gapless month trends
- Statistical anomaly detection (`STDDEV()`-based outlier flagging) for fraud analytics
- Index design tied to actual query patterns, verified with `EXPLAIN ANALYZE`

## Sample Insights
- Total loan book (₹2.51B) runs ~5.1× total deposits (₹492M)  a loan to deposit ratio far above the healthy 80–90% banking benchmark, flagged in the branch-level analytics as a portfolio risk signal.
- Transaction activity splits close to evenly across Deposit, Withdrawal, Transfer, and Purchase (~1,200–1,300 each of 5,000).
- Account portfolio: Checking (36%), Fixed Deposit (34%), Savings (30%).

