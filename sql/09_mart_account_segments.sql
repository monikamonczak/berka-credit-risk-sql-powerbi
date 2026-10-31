/*******************************************************************************
* Project:  Berka Credit Risk Analysis
* Script:   09_customer_segments.sql
* Purpose:  Creates the customer segmentation reporting view ('mart.account_segments'),
*           validates segment distribution, and crosses segments with loan risk.
*******************************************************************************/

USE Berka;
GO

-- 1. Create or alter behavioral segmentation view with 'Mixed' payment style
CREATE OR ALTER VIEW mart.account_segments AS
WITH m AS (
    SELECT account_id,
           active_months,
           total_inflows / active_months AS monthly_inflow,
           100.0 * cash_withdrawals / NULLIF(total_outflows, 0) AS cash_share_pct,
           avg_balance,
           min_balance_after_opening
    FROM clean.account_behaviour
),
g AS (
    SELECT *,
           CASE WHEN monthly_inflow < 7000  THEN '1: Low inflow'
                WHEN monthly_inflow < 21000 THEN '2: Medium inflow'
                ELSE '3: High inflow' END AS inflow_group,
           CASE WHEN cash_share_pct IS NULL THEN 'No outflows'
                WHEN cash_share_pct >= 75   THEN 'Cash-heavy'
                ELSE 'Mixed' END AS payment_style
    FROM m
)
SELECT account_id,
       active_months,
       ROUND(monthly_inflow, 0) AS monthly_inflow,
       ROUND(cash_share_pct, 1) AS cash_share_pct,
       avg_balance,
       min_balance_after_opening,
       inflow_group,
       payment_style,
       inflow_group + ' / ' + payment_style AS segment
FROM g;
GO

-- 2. Verify new segment sizes and distribution
SELECT segment, 
       COUNT(*) AS accounts,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_accounts
FROM mart.account_segments
GROUP BY segment
ORDER BY segment;
GO

-- 3. Cross-analysis: Segments × Loan Risk (from former script 08)
SELECT s.segment,
       COUNT(l.loan_id) AS total_loans,
       SUM(CASE WHEN l.status IN ('B', 'D') THEN 1 ELSE 0 END) AS problem_loans,
       ROUND(100.0 * SUM(CASE WHEN l.status IN ('B', 'D') THEN 1 ELSE 0 END) / NULLIF(COUNT(l.loan_id), 0), 1) AS problem_pct
FROM mart.account_segments s
LEFT JOIN clean.loan l ON s.account_id = l.account_id
GROUP BY s.segment
ORDER BY s.segment;
GO