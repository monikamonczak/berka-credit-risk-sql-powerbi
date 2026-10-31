/*******************************************************************************
* Project:  Berka Credit Risk Analysis
* Script:   08_customer_behaviour.sql
* Purpose:  Creates the behavioral metrics view for all accounts ('clean.account_behaviour'),
*           runs validation checks, and verifies global transaction metrics.
*******************************************************************************/

-- 1. Create behavioral segmentation view for all accounts
CREATE OR ALTER VIEW clean.account_behaviour AS
WITH first_dates AS (
    SELECT account_id, MIN(date) AS first_date
    FROM clean.trans
    GROUP BY account_id
)
SELECT t.account_id,
       DATEDIFF(month, MIN(t.date), MAX(t.date)) + 1 AS active_months,
       SUM(CASE WHEN t.type = 'PRIJEM' THEN t.amount ELSE 0 END) AS total_inflows,
       SUM(CASE WHEN t.type IN ('VYDAJ', 'VYBER') THEN t.amount ELSE 0 END) AS total_outflows,
       SUM(CASE WHEN t.operation IN ('VYBER', 'VYBER KARTOU') THEN t.amount ELSE 0 END) AS cash_withdrawals,
       ROUND(AVG(t.balance), 0) AS avg_balance,
       MIN(t.balance) AS min_balance_incl_opening,
       MIN(CASE WHEN t.date > f.first_date THEN t.balance END) AS min_balance_after_opening
FROM clean.trans t
JOIN first_dates f ON f.account_id = t.account_id
GROUP BY t.account_id;
GO

-- 2. Check 1: Scale of minimum balance change after excluding opening day
SELECT COUNT(*) AS accounts,
       SUM(CASE WHEN min_balance_incl_opening <> min_balance_after_opening THEN 1 ELSE 0 END) AS minimum_changed,
       SUM(CASE WHEN min_balance_after_opening IS NULL THEN 1 ELSE 0 END) AS no_data_after_opening
FROM clean.account_behaviour;
GO

-- 3. Check 2: Account 1589 verification
SELECT account_id, min_balance_incl_opening, min_balance_after_opening
FROM clean.account_behaviour
WHERE account_id = 1589;
GO

-- 4. Distribution of behavioral metrics for all 4,500 accounts
SELECT COUNT(*) AS accounts,
       ROUND(AVG(total_inflows / active_months), 0) AS avg_monthly_inflow,
       ROUND(MIN(total_inflows / active_months), 0) AS min_monthly_inflow,
       ROUND(MAX(total_inflows / active_months), 0) AS max_monthly_inflow,
       ROUND(AVG(100.0 * cash_withdrawals / NULLIF(total_outflows, 0)), 1) AS avg_cash_share_pct,
       SUM(CASE WHEN cash_withdrawals = total_outflows THEN 1 ELSE 0 END) AS cash_only_accounts
FROM clean.account_behaviour;
GO

-- 5. Quantiles of average monthly inflow (cut points for 3 equal groups)
SELECT DISTINCT 
       PERCENTILE_CONT(0.33) WITHIN GROUP (ORDER BY monthly_inflow) OVER () AS p33,
       PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY monthly_inflow) OVER () AS median,
       PERCENTILE_CONT(0.67) WITHIN GROUP (ORDER BY monthly_inflow) OVER () AS p67
FROM (SELECT total_inflows / active_months AS monthly_inflow 
      FROM clean.account_behaviour) x;
GO

-- 6. Distribution across cash-share ranges
SELECT CASE WHEN cash_share = 100 THEN '1: 100% cash'
            WHEN cash_share >= 75 THEN '2: 75-99%'
            WHEN cash_share >= 50 THEN '3: 50-74%'
            ELSE '4: below 50%' 
       END AS cash_band,
       COUNT(*) AS accounts
FROM (SELECT 100.0 * cash_withdrawals / NULLIF(total_outflows, 0) AS cash_share 
      FROM clean.account_behaviour) x
GROUP BY CASE WHEN cash_share = 100 THEN '1: 100% cash'
              WHEN cash_share >= 75 THEN '2: 75-99%'
              WHEN cash_share >= 50 THEN '3: 50-74%'
              ELSE '4: below 50%' END
ORDER BY cash_band;
GO

-- 7. Global Controls from README
-- Control A: Interest share (expected: 0.85%)
SELECT ROUND(100.0 * SUM(CASE WHEN k_symbol = 'UROK' THEN amount ELSE 0 END) / SUM(amount), 2) AS interest_pct 
FROM clean.trans
WHERE type = 'PRIJEM';
GO

-- Control B: Check if cash withdrawals exceed total outflows (expected: 0 accounts)
SELECT SUM(CASE WHEN cash_withdrawals > total_outflows THEN 1 ELSE 0 END) AS cash_exceeds_outflows 
FROM clean.account_behaviour;
GO