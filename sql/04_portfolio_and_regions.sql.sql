/*******************************************************************************
* Project:  Berka Credit Risk Analysis
* Script:   04_portfolio_and_regions.sql
* Question: What is the scale and geography of risk in the loan portfolio?
*
* Definitions:
*   problem loan = status B (finished, not paid) or D (running, in debt)
*   good loan    = status A (finished OK) or C (running OK)
*   region       = region of the district where the loan OWNER lives
*******************************************************************************/

-- Query 1: Count total loans and sum their amounts (expected: 682 loans)
SELECT COUNT(*)    AS total_loans,
       SUM(amount) AS total_amount
FROM clean.loan;
GO

-- Query 2: Breakdown of loans by status (expected: A 203, B 31, C 403, D 45)
SELECT status,
       COUNT(*)    AS loan_count,
       SUM(amount) AS total_amount
FROM clean.loan
GROUP BY status
ORDER BY status;
GO

-- Query 3: Count problem loans (expected: 76 of 682)
SELECT COUNT(*) AS problem_loans
FROM clean.loan
WHERE status IN ('B', 'D');
GO

-- Query 4: Share of problem loans (expected: 76 of 682, 11.1%)
SELECT COUNT(*) AS loans,
       SUM(CASE WHEN status IN ('B', 'D') THEN 1 ELSE 0 END) AS problem_loans,
       CAST(100.0 * SUM(CASE WHEN status IN ('B', 'D') THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,1)) AS problem_pct
FROM clean.loan;
GO

-- Query 5: Finished loans only (expected: 234 finished, 31 unpaid)
SELECT COUNT(*) AS finished_loans,
       SUM(CASE WHEN status = 'B' THEN 1 ELSE 0 END) AS unpaid_loans
FROM clean.loan
WHERE status IN ('A', 'B');
GO

-- Query 6: Loans by year of issue (expected: 20, 101, 90, 117, 196, 158 = 682)
SELECT YEAR(date) AS loan_year,
       COUNT(*)   AS loans
FROM clean.loan
GROUP BY YEAR(date)
ORDER BY loan_year;
GO

-- =============================================================================
-- REGIONAL ANALYSIS (Demonstrating row duplication fix & aggregation by region)
-- =============================================================================

-- Step 1: Loan + Disposition (Demonstrating row duplication without OWNER filter)
SELECT l.loan_id, 
       l.account_id, 
       d.client_id, 
       d.type
FROM clean.loan l
JOIN clean.disp d ON l.account_id = d.account_id;
GO

-- Step 2: Filter by OWNER only to fix duplication
SELECT l.loan_id, 
       l.account_id, 
       d.client_id
FROM clean.loan l
JOIN clean.disp d ON l.account_id = d.account_id
WHERE d.type = 'OWNER';
GO

-- Step 3: Add Client table to get district_id
SELECT l.loan_id, 
       l.status, 
       c.district_id
FROM clean.loan l
JOIN clean.disp d   ON l.account_id = d.account_id
JOIN clean.client c ON d.client_id = c.client_id
WHERE d.type = 'OWNER';
GO

-- Step 4: Problem loans by region (Path: loan -> disp (OWNER) -> client -> district)
-- Check: total_loans must add up to 682, problem_loans to 76.
SELECT di.region,       
       COUNT(*) AS total_loans,       
       SUM(CASE WHEN l.status IN ('B', 'D') THEN 1 ELSE 0 END) AS problem_loans,
       CAST(100.0 * SUM(CASE WHEN l.status IN ('B', 'D') THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,1)) AS problem_loans_percentage
FROM clean.loan l
JOIN clean.disp d      ON l.account_id = d.account_id
JOIN clean.client c    ON d.client_id = c.client_id
JOIN clean.district di ON c.district_id = di.district_id
WHERE d.type = 'OWNER'
GROUP BY di.region
ORDER BY problem_loans_percentage DESC;
GO