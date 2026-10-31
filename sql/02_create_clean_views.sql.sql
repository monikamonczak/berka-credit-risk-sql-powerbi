/*******************************************************************************
* Project: Berka Credit Risk Analysis
* Script:  02_create_clean_views.sql
* Purpose: Creates the 'clean' layer on top of the raw imported tables (dbo.*).
*          Removes quotes, fixes data types and dates.
*******************************************************************************/

USE Berka;
GO

IF SCHEMA_ID('clean') IS NULL EXEC('CREATE SCHEMA clean');
GO
IF SCHEMA_ID('mart') IS NULL EXEC('CREATE SCHEMA mart');
GO
-- =============================================================================
-- 1. ACCOUNT TABLE
-- =============================================================================

CREATE OR ALTER VIEW clean.account AS
SELECT 
    CAST(["account_id"] AS INT)  AS account_id,
    CAST(["district_id"] AS INT) AS district_id,
    REPLACE(["frequency"], '"', '') AS frequency,
    TRY_CONVERT(date, REPLACE(["date"], CHAR(13), ''), 12) AS date
FROM dbo.account;
GO

-- =============================================================================
-- 2. CLIENT TABLE
-- =============================================================================


CREATE OR ALTER VIEW clean.client AS
SELECT 
    CAST(["client_id"] AS INT) AS client_id,
    REPLACE(["birth_number"], '"', '') AS birth_number,
    CAST(REPLACE(["district_id"], CHAR(13), '') AS INT) AS district_id
FROM dbo.client;
GO

-- =============================================================================
-- 3. DISP TABLE 
-- =============================================================================


CREATE OR ALTER VIEW clean.disp AS
SELECT 
    CAST(["disp_id"] AS INT)    AS disp_id,
    CAST(["client_id"] AS INT)  AS client_id,
    CAST(["account_id"] AS INT) AS account_id,
    REPLACE(REPLACE(["type"], '"', ''), CHAR(13), '') AS type -- OWNER / DISPONENT
FROM dbo.disp;
GO

-- =============================================================================
-- 4. CARD TABLE
-- =============================================================================


CREATE OR ALTER VIEW clean.card AS
SELECT 
    CAST(["card_id"] AS INT) AS card_id,
    CAST(["disp_id"] AS INT) AS disp_id,
    REPLACE(["type"], '"', '') AS type,
    TRY_CONVERT(date, LEFT(REPLACE(["issued"], '"', ''), 6), 12) AS issued
FROM dbo.card;
GO

-- =============================================================================
-- 5. LOAN TABLE
-- =============================================================================

CREATE OR ALTER VIEW clean.loan AS
SELECT 
    CAST(["loan_id"] AS INT)    AS loan_id,
    CAST(["account_id"] AS INT) AS account_id,
    TRY_CONVERT(date, ["date"], 12) AS date,
    CAST(["amount"] AS DECIMAL(18,2))   AS amount,
    CAST(["duration"] AS INT)           AS duration,
    CAST(["payments"] AS DECIMAL(18,2)) AS payments,
    REPLACE(REPLACE(["status"], '"', ''), CHAR(13), '') AS status
FROM dbo.loan;
GO

-- =============================================================================
-- 6. ORDER TABLE
-- =============================================================================


CREATE OR ALTER VIEW clean.[order] AS
SELECT 
    CAST(["order_id"] AS INT)   AS order_id,
    CAST(["account_id"] AS INT) AS account_id,
    REPLACE(["bank_to"], '"', '')    AS bank_to,
    REPLACE(["account_to"], '"', '') AS account_to,
    CAST(["amount"] AS DECIMAL(18,2)) AS amount,
    REPLACE(REPLACE(["k_symbol"], '"', ''), CHAR(13), '') AS k_symbol
FROM dbo.[order];
GO

-- =============================================================================
-- 7. TRANS TABLE
-- =============================================================================


CREATE OR ALTER VIEW clean.trans AS
SELECT 
    CAST(["trans_id"] AS INT)   AS trans_id,
    CAST(["account_id"] AS INT) AS account_id,
    TRY_CONVERT(date, ["date"], 12) AS date,
    REPLACE(["type"], '"', '')      AS type,
    NULLIF(REPLACE(["operation"], '"', ''), '') AS operation,
    CAST(["amount"] AS DECIMAL(18,2))  AS amount,
    CAST(["balance"] AS DECIMAL(18,2)) AS balance,
    NULLIF(REPLACE(["k_symbol"], '"', ''), '') AS k_symbol
FROM dbo.trans;
GO

-- =============================================================================
-- 8. DISTRICT TABLE (Demographics A1-A16)
-- =============================================================================


CREATE OR ALTER VIEW clean.district AS
SELECT 
    CAST(A1 AS INT) AS district_id,
    REPLACE(A2, '"', '') AS district_name,
    REPLACE(A3, '"', '') AS region,
    CAST(A4 AS INT) AS inhabitants,
    TRY_CAST(A10 AS DECIMAL(10,2)) AS urban_ratio,
    TRY_CAST(A11 AS DECIMAL(18,2)) AS avg_salary,
    TRY_CAST(A12 AS DECIMAL(10,2)) AS unemployment_1995,
    TRY_CAST(A13 AS DECIMAL(10,2)) AS unemployment_1996,
    TRY_CAST(A14 AS INT) AS entrepreneurs_per_1000,
    TRY_CAST(A15 AS INT) AS crimes_1995,
    TRY_CAST(REPLACE(A16, CHAR(13), '') AS INT) AS crimes_1996
FROM dbo.district;
GO

