-- Oregon online sales | Capstone 1 | Eyob Legesse
USE sample_sales;

-- 1. Overall revenue and date coverage
SELECT SUM(SalesTotal) AS total_revenue,
       MIN(`Date`) AS start_date,
       MAX(`Date`) AS end_date,
       COUNT(*) AS transaction_count,
       AVG(SalesTotal) AS average_transaction
FROM Online_Sales
WHERE ShiptoState = 'Oregon';

-- 2. Revenue by year and month
SELECT YEAR(`Date`) AS sales_year,
       MONTH(`Date`) AS sales_month,
       DATE_FORMAT(`Date`, '%Y-%m') AS year_month_label,
       SUM(SalesTotal) AS revenue,
       COUNT(*) AS transaction_count
FROM Online_Sales
WHERE ShiptoState = 'Oregon'
GROUP BY YEAR(`Date`), MONTH(`Date`), DATE_FORMAT(`Date`, '%Y-%m')
ORDER BY sales_year, sales_month;

-- 3. Territory and region comparison
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
SELECT DATE_FORMAT(o.`Date`, '%Y-%m') AS sales_month,
       c.Category AS category,
       COUNT(*) AS transaction_count,
       SUM(o.SalesTotal) AS revenue,
       AVG(o.SalesTotal) AS average_transaction
FROM Online_Sales AS o
JOIN Products AS p ON o.ProdNum = p.ProdNum
JOIN Inventory_Categories AS c ON p.Categoryid = c.Categoryid
WHERE o.ShiptoState = 'Oregon'
GROUP BY DATE_FORMAT(o.`Date`, '%Y-%m'), c.Category
ORDER BY sales_month, category;

-- 5. Online performance ranking by destination state
SELECT ShiptoState AS state,
       SUM(SalesTotal) AS revenue,
       COUNT(*) AS transaction_count,
       AVG(SalesTotal) AS average_transaction
FROM Online_Sales
GROUP BY ShiptoState
ORDER BY revenue DESC, state;

-- 6. Evidence for the next-quarter recommendation
-- Recommendation for next quarter:
-- In Q4 2025, Textbooks generated $48,984.76,
-- representing 64.2% of Oregon's online revenue.
-- Books (General) ranked second with $22,892.92.
-- I recommend focusing next quarter's sales efforts on
-- Textbooks first and Books (General) second.
-- Test a small promotion and track revenue and transaction
-- count to evaluate the results.
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
AND YEAR(o.`Date`) = 2025
AND MONTH(o.`Date`) BETWEEN 10 AND 12
GROUP BY YEAR(o.`Date`),
         CASE
             WHEN MONTH(o.`Date`) BETWEEN 1 AND 3 THEN 1
             WHEN MONTH(o.`Date`) BETWEEN 4 AND 6 THEN 2
             WHEN MONTH(o.`Date`) BETWEEN 7 AND 9 THEN 3
             ELSE 4
         END,
         c.Category
ORDER BY sales_year, sales_quarter, revenue DESC;


