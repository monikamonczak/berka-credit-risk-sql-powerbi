/*******************************************************************************
* Project: Berka Credit Risk Analysis
* Script: 03_check_clean_views.sql
* Description: Quality checks and data validation for clean views.
*******************************************************************************/

-- CHECK 1: Row counts comparison (raw vs clean)
SELECT 'account' AS table_name, (SELECT COUNT(*) FROM dbo.account) AS raw_rows, (SELECT COUNT(*) FROM clean.account) AS clean_rows
UNION ALL SELECT 'client', (SELECT COUNT(*) FROM dbo.client), (SELECT COUNT(*) FROM clean.client)
UNION ALL SELECT 'disp', (SELECT COUNT(*) FROM dbo.disp), (SELECT COUNT(*) FROM clean.disp)
UNION ALL SELECT 'card', (SELECT COUNT(*) FROM dbo.card), (SELECT COUNT(*) FROM clean.card)
UNION ALL SELECT 'loan', (SELECT COUNT(*) FROM dbo.loan), (SELECT COUNT(*) FROM clean.loan)
UNION ALL SELECT 'order', (SELECT COUNT(*) FROM dbo.[order]), (SELECT COUNT(*) FROM clean.[order])
UNION ALL SELECT 'trans', (SELECT COUNT(*) FROM dbo.trans), (SELECT COUNT(*) FROM clean.trans)
UNION ALL SELECT 'district', (SELECT COUNT(*) FROM dbo.district), (SELECT COUNT(*) FROM clean.district);


-- CHECK 2: Total rows vs successfully parsed dates for loan, trans, account
SELECT 
    'loan' AS dataset,
    COUNT(*) AS total_rows,
    COUNT(date) AS dates_ok
FROM clean.loan
UNION ALL
SELECT 
    'trans',
    COUNT(*),
    COUNT(date)
FROM clean.trans
UNION ALL
SELECT 
    'account',
    COUNT(*),
    COUNT(date)
FROM clean.account;


-- CHECK 3: Loan statuses distribution
SELECT 
    status,
    COUNT(*) AS loan_count
FROM clean.loan
GROUP BY status;


-- CHECK 4: Disposition types distribution (OWNER / DISPONENT)
SELECT 
    type,
    COUNT(*) AS disp_count
FROM clean.disp
GROUP BY type;