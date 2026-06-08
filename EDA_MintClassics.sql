# => Explore the Mint Classics Database
## Table-1: Warehouses
SELECT * FROM warehouses LIMIT 5;

## Table-2: Products
SELECT * FROM products LIMIT 5;

## Table-3: ProductLines
SELECT * FROM productlines LIMIT 5;

## Table-4: OrderDetails
SELECT * FROM orderdetails LIMIT 5;

## Table-5: Orders
SELECT * FROM orders LIMIT 5;

## Table-6: Customers
SELECT * FROM customers LIMIT 5;
 
## Table-7: Payments
SELECT * FROM payments LIMIT 5;

## Table-8: Employees
SELECT * FROM employees LIMIT 5;

## Table-9: Offices
SELECT * FROM offices LIMIT 5;

#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#

-- Problem Statement-1: Which warehouse holds the LOWEST volume or MOST redundant stock?
-- Goal: Surface the Warehouse with Lowest Utilization, Fewer Product Lines, and Highest Stock-to-Sales Ratio: Strongest Closure Candidate

WITH warehouse_inventory AS(
SELECT w.warehouseCode, w.warehouseName, CAST(w.warehousePctCap AS UNSIGNED) AS Current_Pct_Cap,
SUM(p.quantityInStock) AS Total_Units_in_Stock, COUNT(p.productCode) AS Product_Count
FROM warehouses AS w JOIN products AS p ON w.warehouseCode = p.warehouseCode
GROUP BY w.warehouseCode, w.warehouseName, w.warehousePctCap
)

SELECT warehouseCode, warehouseName, Current_Pct_Cap, Total_Units_in_Stock, Product_Count,
DENSE_RANK() OVER (ORDER BY Total_Units_in_Stock ASC) AS Stock_Rank
FROM warehouse_inventory
ORDER BY Total_Units_in_Stock ASC;

#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#

-- Problem Statement-2: Are there PRODUCTS that haven't SOLD in the past 6-12 months?
-- Goal: Identify SLOW/ZERO-MOVEMENT items that are DEAD STOCK or Candidates for Dis-Continuation.

WITH Ref_Date AS(
	SELECT MAX(o.orderDate) AS As_Of_Date
    FROM orders AS o
),

Product_Last_Sale AS(
	SELECT od.productCode, MAX(o.orderDate) AS Last_Sale_Date
    FROM orderdetails AS od
    JOIN orders AS o
    ON od.orderNumber = o.orderNumber
    WHERE o.status IN ('Shipped', 'Resolved')
    GROUP BY od.productCode)
    
    SELECT p.productCode, p.productName, p.productLine, pls.Last_Sale_Date,
    TIMESTAMPDIFF(MONTH, pls.last_Sale_Date, rf.As_Of_Date) AS Months_Since_Last_Sale,
    CASE 
    WHEN pls.last_Sale_Date IS NULL THEN 'Never_Sold'
    WHEN TIMESTAMPDIFF(MONTH, pls.last_Sale_Date, rf.As_Of_Date) >= 12 THEN '12+ Months'
    WHEN TIMESTAMPDIFF(MONTH, pls.last_Sale_Date, rf.As_Of_Date) >= 6 THEN '6-12 Months'
    ELSE 'Avtive'
    END AS Inactivity_Bucket
    FROM products AS p
    CROSS JOIN Ref_Date AS rf
    LEFT JOIN Product_Last_Sale AS pls
    ON pls.productCode = p.productCode
    WHERE pls.Last_Sale_Date IS NULL
    OR pls.Last_Sale_Date < DATE_SUB(rf.As_Of_Date, INTERVAL 6 MONTH)
    ORDER BY pls.Last_Sale_Date IS NULL DESC, pls.Last_Sale_Date ASC, p.productCode;

#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#

-- Problem Statement-3: What is the Re-Order Vs. Actual Demand Ratio per Product Line?
-- Interpretation: "Reorder Stock Held" Vs. Demand Velocity
-- Metrics: 
# => Months of Supply = Current Stock + Avg Monthly Demand
# => Stock-To-Sales Ratio = Current Stock + Lifetime Units Sold

WITH Shipped_Demand AS(
	SELECT p.productLine, SUM(od.quantityOrdered) AS Actual_Demand_Units
    FROM orderdetails AS od
    JOIN orders AS o
    ON o.orderNumber = od.orderNumber
    JOIN products AS p
    ON p.productCode = od.productCode
    WHERE o.status IN ('Shipped', 'Resolved')
    GROUP BY p.productLine
),
Inventory AS(
	SELECT productLine, SUM(quantityInStock) AS Stock_Units
    FROM products
    GROUP BY productLine
)
SELECT i.productLine, i.Stock_Units, sd.Actual_Demand_Units,
ROUND(i.Stock_Units/NULLIF(sd.Actual_Demand_Units, 0), 2) AS Stock_To_Demand_Ratio,
ROUND(sd.Actual_Demand_Units/NULLIF(i.Stock_Units, 0), 4) AS Demand_To_Stock_Ratio
FROM Inventory AS i JOIN Shipped_Demand AS sd ON i.productLine = sd.productLine
ORDER BY Stock_To_Demand_Ratio DESC;

#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#

-- Problem Statement-4: Can Existing Warehouses ABSORB Redistributed Stock?
-- Goal: For each Warehouse treated as the Closure Candidate, determine whether the remaining THREE have enough combined FREE SPACE 
-- to absorb its Entire Inventory.

WITH Warehouse_Stock AS(
SELECT w.warehouseCode, w.warehouseName, 
CAST(w.warehousePctCap AS UNSIGNED) AS Current_Pct_Cap,
SUM(p.quantityInStock) AS Stock_Units
FROM warehouses AS w JOIN products AS p ON w.warehouseCode = p.warehouseCode
GROUP BY w.warehouseCode, w.warehouseName, w.warehousePctCap
),

Capacity_Model AS(
SELECT warehouseCode, warehouseName, Current_Pct_Cap, Stock_Units, 
ROUND(Stock_Units * 100.0 / NULLIF(Current_Pct_Cap, 0), 2) AS Implied_Max_Units,
ROUND((Stock_Units * 100.0 / NULLIF(Current_Pct_Cap, 0)) - Stock_Units, 2) AS Avaliable_Headroom_Units
FROM Warehouse_Stock),

Candidate AS(
SELECT warehouseCode, warehouseName, Stock_Units
FROM Capacity_Model
ORDER BY Stock_Units ASC
LIMIT 1),

Receiver_Capacity AS(
SELECT cm.warehouseCode, cm.warehouseName, cm.Avaliable_Headroom_Units 
FROM Capacity_Model AS cm
JOIN Candidate AS c
ON cm.warehouseCode <> c.warehouseCode)

SELECT c.warehouseCode AS Warehouse_To_Close, 
c.warehouseName AS Warehouse_To_Close_Name, c.Stock_Units AS Stock_To_Redistribute,
ROUND(SUM(rc.Avaliable_Headroom_Units), 2) AS Total_Avalaible_Headroom,
CASE WHEN SUM(rc.Avaliable_Headroom_Units) >= c.Stock_Units THEN 'YES' ELSE 'NO' END AS Can_Absorb_Redistributed_Stock
FROM Candidate AS c CROSS JOIN Receiver_Capacity AS rc
GROUP BY c.warehouseCode, c.warehouseName, c.Stock_Units; 

#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#

-- Problem Statement-5: Which ITEMS pose a FULFILMENT RISK if Inventory is REDUCED?
-- Risk Definitions:
# 1. Avg Monthly Demand > 0 AND Months of Supply < 3 => High Risk
# 2. Avg Monthly Demand > 0 AND Months of Supply < 1 => Critical Risk
# 3. Very High - Velocity Items (Top 10% Demand Risk) => Flag Regardless
-- Scope: Only products currently in the West Warehouse (c) are at IMMEDIATE RISK during a Closure/Relocation Event.
 
 WITH Anchor_Date AS(
 SELECT MAX(o.orderDate) AS As_Of_Date
 FROM orders AS o),
 
 Recent_Demand AS(
 SELECT od.productCode, SUM(od.quantityOrdered) AS Demand_12m
 FROM orderdetails AS od 
 JOIN orders AS o
 ON od.orderNumber = o.orderNumber
 CROSS JOIN Anchor_Date AS ad
 WHERE o.status IN ('Shipped', 'Resolved')
 AND o.orderDate >= DATE_SUB(ad.As_Of_Date, INTERVAL 12 MONTH)
 GROUP BY od.productCode),
 
 Product_Risk AS(
 SELECT p.productCode, p.productName, p.productLine, p.quantityInStock,
 COALESCE(rd.demand_12m, 0) AS Demand_12m,
 ROUND(COALESCE(rd.Demand_12m, 0)/12.0, 2) AS Avg_Monthly_Demand,
 ROUND(p.quantityInStock/NULLIF(COALESCE(rd.Demand_12m, 0)/12.0, 0),2) AS Months_To_Cover
 FROM products AS p LEFT JOIN Recent_Demand AS rd
 ON rd.productCode = p.productCode)
 
 SELECT productCode, productName, productLine, quantityInStock, Demand_12m, Avg_Monthly_Demand, Months_To_Cover
 FROM Product_Risk
 WHERE Demand_12m > 0 AND Months_To_Cover < 3
 ORDER BY Months_To_Cover ASC, Demand_12m DESC, quantityInStock ASC;
 
#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#--#--<>--#


