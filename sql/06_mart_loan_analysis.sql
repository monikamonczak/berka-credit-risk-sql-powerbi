/*******************************************************************************
* Project: Berka Credit Risk Analysis
* Script:  06_mart_loan_analysis.sql
* Purpose: Reporting view for Power BI Integration with account_id added.
* Grain:   one row = one loan (all 682 loans).
*
* Loans without a full pre-loan history are kept (history_group = 'short history'),
* with NULL balance metrics, so the portfolio pages can still count them.
*******************************************************************************/

USE Berka;
GO

IF SCHEMA_ID('mart') IS NULL EXEC('CREATE SCHEMA mart');
GO

CREATE OR ALTER VIEW mart.loan_analysis AS
SELECT 
    l.loan_id,
    l.account_id,
    l.date AS loan_date,
    YEAR(l.date) AS loan_year,
    l.amount,
    l.duration,
    l.payments,
    l.status,
    CASE WHEN l.status IN ('B', 'D') THEN 1 ELSE 0 END AS is_problem,
    di.region,
    di.district_name,
    CASE WHEN f.loan_id IS NULL THEN 'short history' ELSE 'full history' END AS history_group,
    f.avg_balance,
    f.min_balance,
    f.total_inflows,
    f.total_outflows,
    f.inflow_outflow_ratio,
    CASE 
        WHEN f.loan_id IS NULL THEN 'no data'
        WHEN f.min_balance < 5000  THEN '1: below 5k'
        WHEN f.min_balance < 10000 THEN '2: 5k-10k'
        WHEN f.min_balance < 20000 THEN '3: 10k-20k'
        ELSE '4: 20k and more' 
    END AS min_balance_band
FROM clean.loan l
JOIN clean.disp d 
    ON l.account_id = d.account_id AND d.type = 'OWNER'
JOIN clean.client c 
    ON d.client_id = c.client_id
JOIN clean.district di 
    ON c.district_id = di.district_id
LEFT JOIN clean.loan_pre_features f 
    ON f.loan_id = l.loan_id;
GO

-- Verification Tests: should return 682/682, ~597 for full history, and 76 problem loans
SELECT COUNT(*) AS rows_in_view, COUNT(DISTINCT loan_id) AS unique_loans 
FROM mart.loan_analysis;
GO

SELECT COUNT(*) AS full_history_loans 
FROM mart.loan_analysis 
WHERE history_group = 'full history';
GO

SELECT SUM(is_problem) AS problem_loans 
FROM mart.loan_analysis;
GO