/*******************************************************************************
* Project:  Berka Credit Risk Analysis
* Script:   07_pre_loan_analysis.sql
* Purpose:  Analyzes pre-loan behavioral metrics and loan risk profiles
*           using the 'mart.loan_analysis' reporting view.
*******************************************************************************/

-- 1. Problem loans by minimum balance band
SELECT min_balance_band,       
       COUNT(*) AS loans,       
       SUM(is_problem) AS problem_loans,       
       ROUND(100.0 * SUM(is_problem) / COUNT(*), 1) AS problem_pct
FROM mart.loan_analysis
WHERE history_group = 'full history'
GROUP BY min_balance_band
ORDER BY min_balance_band;
GO

-- 2. Cross analysis: loan size x minimum balance
SELECT CASE WHEN amount < 150000 THEN 'loan below 150k' ELSE 'loan 150k and more' END AS loan_size,       
       CASE WHEN min_balance < 10000 THEN 'min balance below 10k' ELSE 'min balance 10k and more' END AS balance_group,       
       COUNT(*) AS loans,       
       SUM(is_problem) AS problem_loans,       
       ROUND(100.0 * SUM(is_problem) / COUNT(*), 1) AS problem_pct
FROM mart.loan_analysis
WHERE history_group = 'full history'
GROUP BY CASE WHEN amount < 150000 THEN 'loan below 150k' ELSE 'loan 150k and more' END,         
         CASE WHEN min_balance < 10000 THEN 'min balance below 10k' ELSE 'min balance 10k and more' END
ORDER BY loan_size, balance_group;
GO

-- 3. Status comparison
SELECT status,       
       COUNT(*) AS loans,       
       ROUND(AVG(avg_balance), 0) AS avg_of_avg_balance,       
       ROUND(AVG(min_balance), 0) AS avg_min_balance,       
       ROUND(AVG(inflow_outflow_ratio), 2) AS avg_ratio
FROM mart.loan_analysis
WHERE history_group = 'full history'
GROUP BY status
ORDER BY status;
GO

-- 4. Excluded loans (expected: full history 597 / 61 problem; short history 85 / 15 problem)
SELECT history_group, 
       COUNT(*) AS loans, 
       SUM(is_problem) AS problem_loans,       
       ROUND(100.0 * SUM(is_problem) / COUNT(*), 1) AS problem_pct
FROM mart.loan_analysis
GROUP BY history_group;
GO

-- 5. Average loan amount per balance band
SELECT min_balance_band, 
       COUNT(*) AS loans, 
       ROUND(AVG(amount), 0) AS avg_loan_amount
FROM mart.loan_analysis
WHERE history_group = 'full history'
GROUP BY min_balance_band
ORDER BY min_balance_band;
GO

-- 6. Opening deposit inside the 6-month window under the simple rule (expected: 18)
WITH first_dates AS (
    SELECT account_id, MIN(date) AS first_date 
    FROM clean.trans 
    GROUP BY account_id
)
SELECT COUNT(*) AS loans_with_opening_deposit_in_window
FROM clean.loan l
JOIN clean.account a ON a.account_id = l.account_id
JOIN first_dates fd  ON fd.account_id = l.account_id
WHERE DATEDIFF(month, a.date, l.date) >= 6  
  AND fd.first_date >= DATEADD(month, -6, l.date);
GO