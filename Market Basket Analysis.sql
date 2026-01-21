-- Let's see the products customers often purchase together
WITH ProductPairs AS (
    SELECT 
        f1.ProductID AS ProductA, 
        f2.ProductID AS ProductB, 
        COUNT(*) AS PurchaseCount
    FROM vSales f1
    JOIN vSales f2 
        ON f1.SalesOrderID = f2.SalesOrderID -- Ensure products are in the same order
        AND f1.ProductID < f2.ProductID -- Prevent self-joins and duplicates
    GROUP BY f1.ProductID, f2.ProductID
)
SELECT TOP(10)
    p1.ProductName AS ProductA, 
    p2.ProductName AS ProductB, 
    pp.PurchaseCount
FROM ProductPairs pp
JOIN vProduct p1 ON pp.ProductA = p1.ProductID
JOIN vProduct  p2 ON pp.ProductB = p2.ProductID
ORDER BY pp.PurchaseCount DESC;

-- ALTERNATIVELY
SELECT TOP(10)
        f1.ProductID AS ProductA, 
        f2.ProductID AS ProductB, 
		p1.ProductName AS ProductAName,
		p2.ProductName AS ProductBName,
        COUNT(*) AS PurchaseCount
FROM vSales f1
JOIN vSales f2 
    ON f1.SalesOrderID = f2.SalesOrderID -- Ensure products are in the same order
    AND f1.ProductID < f2.ProductID -- Prevent self-joins and duplicates
JOIN vProduct AS p1 ON f1.ProductID = p1.ProductID
JOIN vProduct AS p2 ON f2.ProductID = p2.ProductID
GROUP BY f1.ProductID, f2.ProductID, p1.ProductName, p2.ProductName
ORDER BY PurchaseCount DESC;


