# Berka Bank: Credit Risk and Customer Behaviour Analysis

## Project overview

This SQL and Power BI case study analyses the loan portfolio of a Czech bank, the behaviour of accounts in the six months before a loan is granted, and rule-based customer segments. The objective was to turn relational banking data into insights that could support credit-risk monitoring: how to recognise, before a loan is granted, which clients deserve a closer look.

The analysis covers:

- **682 loans** granted between **1993 and 1998**,
- **4,500 accounts** and **5,369 clients**,
- **1,056,320 transactions**,
- **77 districts** grouped into **8 regions**.

**Technologies:** SQL Server (T-SQL), SSMS, Power BI (DAX), Canva (dashboard background design)

**SQL techniques:**

- joins across up to five tables,
- common table expressions (CTEs),
- views organised in `raw → clean → mart` layers,
- aggregate functions with `CASE`,
- `NULLIF`,
- type and date conversion (`TRY_CAST`, `TRY_CONVERT`),
- date arithmetic (`DATEADD`, `DATEDIFF`),
- window functions (`PERCENTILE_CONT`, `SUM() OVER`),
- subqueries and temporary tables,
- data quality checks and reconciliation queries.

**Power BI techniques:**

- DAX measures and calculated columns,
- page navigation and a custom landing page,
- tooltip page with loan counts,
- conditional formatting,
- slicers,
- a minimum-sample rule: percentages are hidden where fewer than 30 loans stand behind them.

## Business questions

1. What is the scale and geography of risk in the loan portfolio?
2. Does account behaviour before a loan reveal later repayment problems?
3. Which behavioural profiles can be distinguished among the bank's accounts, and how do they relate to loan outcomes?

## Dataset and database structure

The analysis uses the Berka (PKDD'99) financial dataset: real, anonymised data from a Czech bank. It consists of eight related tables:

| Table      | Description                                                       |     Rows |
|------------|-------------------------------------------------------------------|---------:|
| `account`  | Bank accounts                                                     |    4,500 |
| `client`   | Clients; `birth_number` encodes date of birth and gender          |    5,369 |
| `disp`     | Link between clients and accounts (`OWNER` or `DISPONENT`)        |    5,369 |
| `card`     | Issued credit cards                                               |      892 |
| `loan`     | Loans with amount, duration, payments and status                  |      682 |
| `order`    | Standing payment orders                                           |    6,471 |
| `trans`    | Transactions with amount, type, operation and balance after it    |1,056,320 |
| `district` | Demographic and economic indicators of 77 districts               |       77 |

![Berka database ERD](images/berka_database_ERD.png)

**Layers.** Imported tables (`dbo.*`) are never modified. Cleaning happens in `clean.*` views, and Power BI reads only `mart.*` views.

**Loan status.** `A` finished and repaid, `B` finished and not repaid, `C` running without problems, `D` running and in debt. A **problem loan** is a loan with status **B or D** (76 loans); a good loan has status A or C (606 loans).

## Data preparation and quality checks

Before the analysis I checked:

- row counts of raw tables against the clean views,
- whether all dates and amounts converted without `NULL` values,
- the values of loan status and disposition type,
- whether joins duplicate loans.

All eight tables kept their row counts, all dates converted (682 loan dates, 1,056,320 transaction dates, 4,500 account dates), loan statuses came out as A 203, B 31, C 403 and D 45, and every account has exactly one `OWNER` (4,500 owners, 869 disponents).

The checks also uncovered issues that would have distorted the results:

| Issue | Impact | Fix |
|-------|--------|-----|
| Quotation marks left in text values and column names after the CSV import | Filters such as `status = 'B'` return nothing | `REPLACE` and bracketed column names in the clean views |
| Dates stored as `YYMMDD` numbers (e.g. `930705`) | No date filtering or time analysis | `TRY_CONVERT(date, …, 12)` |
| Carriage return at the end of the last column of each file | Failed numeric casts | `REPLACE(…, CHAR(13), '')` |
| One account can have an `OWNER` and a `DISPONENT` | Joining loans to dispositions duplicates loans | Join `OWNER` only; verified 682 rows for 682 unique loans |
| The six-month pre-loan window contained the account-opening deposit for **18 loans** (17 fell in the lowest balance band) | Artificially low minimum balances | A loan is analysed only if the account's first transaction is earlier than the start of the window |
| For **4,168 of 4,500 accounts (92.6%)** the minimum balance over the whole history was the opening deposit, not a real low point | Meaningless minimum balances in segmentation | Minimum balance calculated after the opening day |
| 183,114 inflow rows have no operation; all are interest credits (`UROK`), **0.85%** of inflow value | Inflows are not pure income | Left unchanged and documented |
| Cash withdrawals are recorded under two transaction types plus card withdrawals | Cash would be undercounted | Cash = operation `VYBER` or `VYBER KARTOU`, regardless of type; no account has cash above its total outflows |

The pre-loan view was verified with an independent query on raw transactions: the average balance of the analysed windows is **43,800.15** in both calculations.

## Key findings

### 1. Portfolio and regional risk

| Status | Loans | Meaning |
|--------|------:|---------|
| A | 203 | Finished, repaid |
| B | 31 | Finished, not repaid |
| C | 403 | Running, no problems |
| D | 45 | Running, in debt |

**76 of 682 loans (11.1%)** are problem loans. The figure is probably an underestimate: **448 loans (65.7%) are still running** (statuses C and D), so their final outcome is unknown. Among finished loans only, **31 of 234 (13.2%)** were not repaid.

Loans were issued mostly in the second half of the period: 20 in 1993 (the first loan is from July), 101 in 1994, 90 in 1995, 117 in 1996, 196 in 1997 and 158 in 1998.

| Region          | Loans | Problem loans | Problem loan rate |
|-----------------|------:|--------------:|------------------:|
| north Moravia   | 117   | 19            | 16.2%             |
| south Bohemia   | 61    | 9             | 14.8%             |
| west Bohemia    | 56    | 8             | 14.3%             |
| central Bohemia | 87    | 10            | 11.5%             |
| south Moravia   | 133   | 15            | 11.3%             |
| east Bohemia    | 87    | 8             | 9.2%              |
| Prague          | 79    | 6             | 7.6%              |
| north Bohemia   | 62    | 1             | 1.6%              |

The region is the district of the loan owner. North Moravia has the highest rate and the most problem loans. Each region holds only 56 to 133 loans, and one loan more or less moves a regional rate by roughly one and a half percentage points, so the differences should be treated as indicative rather than conclusive.

### 2. Account behaviour before the loan

For every loan I measured the account in the six months before the loan date (the loan day itself excluded), using **597 loans with a full pre-loan history, 61 of them problem loans (10.2%)**.

**Minimum balance separates the groups best.**

| Status | Loans | Average minimum balance | Inflow / outflow ratio |
|--------|------:|------------------------:|-----------------------:|
| A | 174 | 19,628 | 1.01 |
| B | 20  | 7,816  | 1.03 |
| C | 362 | 19,907 | 1.03 |
| D | 41  | 5,044  | 0.93 |

Clients whose loans ended unpaid (B) had an average minimum balance about 2.5 times lower than clients who repaid (A), and clients in debt (D) about 3.9 times lower than clients with running loans without problems (C). The inflow-to-outflow ratio is not a convincing signal: A and B look the same, and only D is lower.

**The risk rises below roughly 10,000 CZK.**

| Minimum balance in the 6 months before the loan | Loans | Problem loans | Problem loan rate |
|-------------------------------------------------|------:|--------------:|------------------:|
| below 5k    | 65  | 34 | 52.3% |
| 5k - 10k    | 59  | 12 | 20.3% |
| 10k - 20k   | 218 | 7  | 3.2%  |
| 20k and more| 255 | 8  | 3.1%  |

Above 10,000 CZK the rate is low and flat (about 3%). Below 5,000 CZK it is about 17 times higher than in the highest band.

**Loan size does not explain the effect.** Loans in the lowest balance bands are also larger, so I checked loan size separately:

| Loan size    | Minimum balance 10k and more | Minimum balance below 10k |
|--------------|-----------------------------:|--------------------------:|
| below 150k   | 2.5% (7 of 282)              | 23.0% (14 of 61)          |
| 150k or more | 4.2% (8 of 191)              | 50.8% (32 of 63)          |

In both loan-size groups a low minimum balance goes with many more problem loans. A large loan combined with a low balance is the riskiest combination.

**Loans excluded from this analysis.** 85 loans lack a full pre-loan history; 15 of them (17.6%) are problem loans, against 10.2% in the analysed group. The group is small, so this is a signal and not a finding.

The analysis respects the temporal constraint: only transactions dated before the loan are used. The maintainers of the dataset note that if temporal constraints are ignored, good and bad loans can be separated almost perfectly by a simple rule on the minimum balance over the entire account history ([CTU Relational Learning Repository](https://relational.fel.cvut.cz/dataset/Financial))[cite: 7]. Because this analysis strictly uses pre-loan transactions, it avoids data leakage, while the full-history segmentation is intentionally kept as descriptive only.

### 3. Customer segments

Segments are rule-based and use two axes: average monthly inflow (low below 7,000 CZK, medium up to 21,000 CZK, high above; rounded 33rd and 67th percentiles, 7,081 and 21,266, median 14,425) and payment style (**Cash-heavy** when at least 75% of outflows are cash withdrawals, otherwise **Mixed**).

| Segment | Accounts | Share | Avg monthly inflow | Cash share of outflows | Loans | Problem loan rate |
|---------|---------:|------:|-------------------:|-----------------------:|------:|------------------:|
| Low inflow / Cash-heavy    | 235   | 5.2%  | 4,347 CZK  | 98.2% | 1   | n < 30 |
| Low inflow / Mixed         | 1,238 | 27.5% | 4,908 CZK  | 45.0% | 7   | n < 30 |
| Medium inflow / Cash-heavy | 512   | 11.4% | 14,499 CZK | 93.7% | 58  | 27.6%  |
| Medium inflow / Mixed      | 987   | 21.9% | 13,759 CZK | 55.7% | 150 | 4.7%   |
| High inflow / Cash-heavy   | 1,071 | 23.8% | 34,696 CZK | 90.4% | 304 | 14.1%  |
| High inflow / Mixed        | 457   | 10.2% | 27,967 CZK | 66.4% | 162 | 6.2%   |

Observations:

- **Cash dominates spending.** On average 68.6% of an account's outflows are cash withdrawals, and **1,818 accounts (40.4%) are Cash-heavy**, including 898 accounts that spend only in cash.
- **Cash use rises with income.** Cash-heavy accounts are about 16% of low-inflow accounts, 34% of medium and 70% of high-inflow accounts.
- **Clients with low inflows rarely received loans:** the two low-inflow segments hold 1,473 accounts (33%) but only 8 loans, so their problem rates are not shown.
- **Cash-heavy clients have more problem loans** in both segments that can be compared: 27.6% against 4.7% at medium inflow, and 14.1% against 6.2% at high inflow.

This last comparison is **descriptive only**. Segments are built from the whole account history, including the time after the loan, so a client who ran into trouble may have changed behaviour after receiving the loan. Unlike the pre-loan analysis, it cannot be read as an early-warning signal.

## Power BI dashboard

The report has a landing page and three analytical pages, each answering one business question, plus a methodology page.

| Page | Content |
|------|---------|
| Home | Project summary and navigation tiles |
| Portfolio Overview | KPIs, problem loan rate by region with the portfolio average, loans by status and by year of issue, key takeaways, a year slicer |
| Pre-Loan Behaviour | Problem loan rate by minimum balance band, loan size by band, loan size × balance matrix, key takeaway |
| Customer Segments | Segment sizes, problem loan rate by segment, segment profile table, a payment-style slicer |
| About | Data source, definitions, analytical decisions, limitations |

![Dashboard home](images/dashboard_home.png)
![Portfolio Overview](images/dashboard_portfolio.png)
![Pre-Loan Behaviour](images/dashboard_pre_loan.png)
![Customer Segments](images/dashboard_segments.png)

Design decisions:

- **Number of loans next to every percentage.** A tooltip page shows loans, problem loans and the rate for any bar or table row.
- **Minimum-sample rule.** Rates are hidden where fewer than 30 loans stand behind them (for example the low-inflow segments).
- **Colour carries meaning.** Coral marks risk only; green is used for everything else.
- **Every number was reconciled with the SQL results** before it was published.

## Recommendations

1. **Use the minimum balance before the loan as a screening signal.** Clients who dropped below about 10,000 CZK in the six months before applying deserve a closer review, especially for loans of 150k CZK or more.
2. **Combine balance with loan size.** A low balance together with a large loan had the highest problem rate (50.8%).
3. **Re-evaluate once running loans finish.** Statuses C and D cover two thirds of the portfolio, so the final problem rate and the regional differences may change.
4. **Treat regional differences as leads, not conclusions.** North Moravia, south Bohemia and west Bohemia are candidates for further review; north Bohemia's very low rate rests on one problem loan.
5. **Check cash behaviour before the loan.** Cash-heavy clients show more problem loans, but only a measure calculated on the six months before the loan can show whether it is an early signal.
6. **Do not use the inflow-to-outflow ratio as a warning indicator.** It did not separate repaid from unpaid loans.

## Analytical assumptions and limitations

- **Small samples.** There are only 76 problem loans (61 in the pre-loan analysis). Group comparisons, especially by region and in the lowest balance band, are directional rather than statistically robust.
- **Exploratory analysis.** The thresholds (5k, 10k, 20k CZK for balance, 150k CZK for loan size, 7,000 and 21,000 CZK for inflow, 75% for cash share) were chosen after looking at the data, and no statistical test was applied.
- **Association, not causation.** A low balance and repayment problems may share a cause, such as low income.
- **Problem loan definition.** B and D together follow the dataset's good/bad grouping (606 versus 76 loans). Status D loans are still running, so their outcome is not final. A comparison of finished loans only (A against B) is shown separately.
- **Balance metrics are based on balances after each transaction,** not daily balances, so averages give more weight to days with many transactions.
- **Inflows include interest credits** (0.85% of inflow value).
- **Regions are based on the district of the loan owner,** not the branch.
- **Segments use the whole account history** and are descriptive only when combined with loan outcomes.
- **Historical data from 1993 to 1998.** The results describe this bank in this period and are not a view of today's market. Amounts are in Czech Koruna (CZK).

## Next steps

- Measure the cash share of outflows in the six months before the loan to test whether it is an early signal.
- Add a statistical test or a simple model with a temporal split to quantify the minimum-balance effect.
- Compare the results for finished loans only (A against B) with the B and D definition.

## Repository structure