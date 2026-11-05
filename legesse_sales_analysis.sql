-- Oregon online sales | Capstone 1 | Eyob Legesse
-- Learning Note: AI-assisted study reference, not independently authored student work.
-- Learning Note: The supplied course file requires students to write their own
-- submitted queries. Use this to understand, rebuild and verify your own analysis.
-- Learning Note: Working territory: Oregon online sales. Instructor may adjust it.
-- Learning Note: MySQL query text; run one numbered section at a time in Workbench.
-- Learning Note: Results were checked using an isolated SQLite inspection copy
-- and exact-cent checks. They have not been executed on your MySQL server.
-- Learning Note: This file only reads data. It does not recreate the database.
USE sample_sales;

-- 1. Overall revenue and date coverage
-- Learning Note: SUM adds the amounts; MIN and MAX show the first and last dates. COUNT(*) counts sales-table rows. This dataset has no separate order ID, so the report defines one row as one transaction.
SELECT SUM(SalesTotal) AS total_revenue,
       MIN(`Date`) AS start_date,
       MAX(`Date`) AS end_date,
       COUNT(*) AS transaction_count,
       AVG(SalesTotal) AS average_transaction
FROM Online_Sales
WHERE ShiptoState = 'Oregon';online_sales

-- 2. Revenue by year and month
-- Learning Note: The Oregon filter runs before grouping. Grouping by year AND month keeps January 2022 separate from January 2023. Export this result as data/02_monthly_revenue.csv for the PivotChart.
SELECT YEAR(`Date`) AS sales_year,
       MONTH(`Date`) AS sales_month,
       DATE_FORMAT(`Date`, '%Y-%m') AS year_month,
       SUM(SalesTotal) AS revenue,
       COUNT(*) AS transaction_count
FROM Online_Sales
WHERE ShiptoState = 'Oregon'
GROUP BY YEAR(`Date`), MONTH(`Date`), DATE_FORMAT(`Date`, '%Y-%m')
ORDER BY sales_year, sales_month;

-- 3. Territory and region comparison
-- Learning Note: The Management table assigns Online Sales to West. West includes the entire online business plus Colorado in-store sales. The two Online Sales manager rows must not multiply online revenue. The IN subquery treats membership as a set. Oregon is part of the region total, so these rows must not be added together as non-overlapping groups.
SELECT 'Oregon online territory' AS sales_scope,
       SUM(SalesTotal) AS revenue
FROM Online_Sales
WHERE ShiptoState = 'Oregon'
UNION ALL
SELECT 'West online component', SUM(SalesTotal)
FROM Online_Sales
UNION ALL
SELECT 'West in-store component', SUM(s.Sale_Amount)
FROM Store_Sales AS s
JOIN Store_Locations AS l ON s.Store_ID = l.StoreId
WHERE l.State IN (
    SELECT DISTINCT State FROM Management WHERE Region = 'West'
)
UNION ALL
SELECT 'West region total',
       (SELECT SUM(SalesTotal) FROM Online_Sales)
       + (SELECT SUM(s.Sale_Amount)
          FROM Store_Sales AS s
          JOIN Store_Locations AS l ON s.Store_ID = l.StoreId
          WHERE l.State IN (
              SELECT DISTINCT State FROM Management WHERE Region = 'West'
          ));

-- 4. Monthly transaction count and average by category
-- Learning Note: Join Online_Sales.ProdNum to Products.ProdNum, then Products.Categoryid to Inventory_Categories.Categoryid. Both product and category keys are unique. AVG(SalesTotal) is the average row amount, not unit price or order value.
SELECT DATE_FORMAT(o.`Date`, '%Y-%m') AS year_month,
       c.Category AS category,
       COUNT(*) AS transaction_count,
       SUM(o.SalesTotal) AS revenue,
       AVG(o.SalesTotal) AS average_transaction
FROM Online_Sales AS o
JOIN Products AS p ON o.ProdNum = p.ProdNum
JOIN Inventory_Categories AS c ON p.Categoryid = c.Categoryid
WHERE o.ShiptoState = 'Oregon'
GROUP BY DATE_FORMAT(o.`Date`, '%Y-%m'), c.Category
ORDER BY year_month, category;

-- 5. Online performance ranking by destination state
-- Learning Note: Oregon is a single-state online territory, so there are no Oregon physical stores to rank. This broader online peer ranking puts Oregon in context within the online business. The descending row order represents the ranking. Explain this scope choice to the instructor.
SELECT ShiptoState AS state,
       SUM(SalesTotal) AS revenue,
       COUNT(*) AS transaction_count,
       AVG(SalesTotal) AS average_transaction
FROM Online_Sales
GROUP BY ShiptoState
ORDER BY revenue DESC, state;

-- 6. Evidence for the next-quarter recommendation
-- Learning Note: The CASE expression creates quarter numbers. Compare matching quarters or complete years to avoid comparing a quarter with a year. This is historical evidence, not a forecast. The quarter after the dataset ends is Q1 2026; no actual 2026 sales are supplied.
SELECT YEAR(o.`Date`) AS sales_year,
       CASE
           WHEN MONTH(o.`Date`) BETWEEN 1 AND 3 THEN 1
           WHEN MONTH(o.`Date`) BETWEEN 4 AND 6 THEN 2
           WHEN MONTH(o.`Date`) BETWEEN 7 AND 9 THEN 3
           ELSE 4
       END AS sales_quarter,
       c.Category AS category,
       SUM(o.SalesTotal) AS revenue,
       COUNT(*) AS transaction_count
FROM Online_Sales AS o
JOIN Products AS p ON o.ProdNum = p.ProdNum
JOIN Inventory_Categories AS c ON p.Categoryid = c.Categoryid
WHERE o.ShiptoState = 'Oregon'
GROUP BY YEAR(o.`Date`),
         CASE
             WHEN MONTH(o.`Date`) BETWEEN 1 AND 3 THEN 1
             WHEN MONTH(o.`Date`) BETWEEN 4 AND 6 THEN 2
             WHEN MONTH(o.`Date`) BETWEEN 7 AND 9 THEN 3
             ELSE 4
         END,
         c.Category
ORDER BY sales_year, sales_quarter, revenue DESC;

-- Learning Note: Suggested recommendation to evaluate and explain in your own words.
-- Learning Note: First check the completeness of the 2025 records and investigate the decline in Oregon online
-- Learning Note: transactions. Revenue fell 72.7% and transactions fell 75.5% from 2024 to 2025, while average
-- Learning Note: transaction amount rose 11.2%. If reporting is complete, test a small Technology & Accessories
-- Learning Note: campaign to rebuild transaction volume. This category generated $3,654,893.37, or 47.8% of Oregon's
-- Learning Note: four-year revenue. Measure transaction count, revenue and average transaction amount during the
-- Learning Note: pilot. Obtain margin and return data before expanding it. The sales table alone cannot establish the
-- Learning Note: reason for the decline or the most profitable category.
