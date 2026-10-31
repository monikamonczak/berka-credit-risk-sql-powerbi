/*******************************************************************************
* Project:  Berka Credit Risk Analysis
* Script:   05_pre_loan_features.sql
* Purpose:  Creates the 'clean.loan_pre_features' view calculating 6-month
*           pre-loan behavioral metrics (balances, inflows, outflows) for accounts
*           with a full history (> 6 months before the loan date).
*******************************************************************************/

-- Create pre-loan features view
CREATE OR ALTER VIEW clean.loan_pre_features AS
WITH first_dates AS (
    SELECT account_id, MIN(date) AS first_date
    FROM clean.trans
    GROUP BY account_id
)
SELECT l.loan_id,
       l.status,
       COUNT(*) AS transaction_count,
       ROUND(AVG(t.balance), 0) AS avg_balance,
       MIN(t.balance) AS min_balance,
       SUM(CASE WHEN t.type = 'PRIJEM' THEN t.amount ELSE 0 END) AS total_inflows,
       SUM(CASE WHEN t.type IN ('VYDAJ', 'VYBER') THEN t.amount ELSE 0 END) AS total_outflows,
       ROUND(SUM(CASE WHEN t.type = 'PRIJEM' THEN t.amount ELSE 0 END) 
             / NULLIF(SUM(CASE WHEN t.type IN ('VYDAJ', 'VYBER') THEN t.amount ELSE 0 END), 0), 2) AS inflow_outflow_ratio
FROM clean.loan l
JOIN first_dates fd ON fd.account_id = l.account_id
JOIN clean.trans t  ON t.account_id = l.account_id
                   AND t.date >= DATEADD(month, -6, l.date)
                   AND t.date <  l.date
WHERE fd.first_date < DATEADD(month, -6, l.date)
GROUP BY l.loan_id, l.status;
GO

-- Control 1: Weighted average balance from view
SELECT ROUND(SUM(avg_balance * transaction_count) / SUM(transaction_count), 2) AS weighted_avg_from_view
FROM clean.loan_pre_features;
GO

-- Control 2: Count of loans in view (expected: 597)
SELECT COUNT(*) AS loans_in_view 
FROM clean.loan_pre_features;
GO

-- Control 3: Independent verification of average balance from raw transactions (expected: 43800.15)
WITH first_dates AS (
    SELECT account_id, MIN(date) AS first_date 
    FROM clean.trans 
    GROUP BY account_id
)
SELECT ROUND(AVG(t.balance), 2) AS avg_balance_from_raw_transactions
FROM clean.loan l
JOIN first_dates fd ON fd.account_id = l.account_id
JOIN clean.trans t  ON t.account_id = l.account_id
                   AND t.date >= DATEADD(month, -6, l.date)
                   AND t.date <  l.date
WHERE fd.first_date < DATEADD(month, -6, l.date);
GO