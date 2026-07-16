--Top 5 Customers by Total Revenue
SELECT
    c.CompanyName,
    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    ROUND(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)), 2) AS TotalRevenue,
    ROUND(
        SUM(od.UnitPrice * od.Quantity * (1 - od.Discount))
        / COUNT(DISTINCT o.OrderID),
        2
    ) AS AvgOrderValue
FROM Customers c
JOIN Orders o
    ON c.CustomerID = o.CustomerID
JOIN "Order Details" od
    ON o.OrderID = od.OrderID
GROUP BY c.CustomerID, c.CompanyName
ORDER BY TotalRevenue DESC
LIMIT 5;

--Best Selling Product in Each Category
WITH ProductSales AS (
    SELECT
        c.CategoryName,
        p.ProductID,
        p.ProductName,
        SUM(od.Quantity) AS TotalQuantity
    FROM Categories c
    JOIN Products p
        ON c.CategoryID = p.CategoryID
    JOIN "Order Details" od
        ON p.ProductID = od.ProductID
    GROUP BY
        c.CategoryID,
        c.CategoryName,
        p.ProductID,
        p.ProductName
)

SELECT
    CategoryName,
    ProductName,
    TotalQuantity
FROM ProductSales ps
WHERE TotalQuantity = (
    SELECT MAX(TotalQuantity)
    FROM ProductSales
    WHERE CategoryName = ps.CategoryName
)
ORDER BY CategoryName;

--Employees Who Generated Above-Average Revenue
WITH EmployeeRevenue AS (
    SELECT
        e.EmployeeID,
        e.FirstName || ' ' || e.LastName AS EmployeeName,
        SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS Revenue
    FROM Employees e
    JOIN Orders o
        ON e.EmployeeID = o.EmployeeID
    JOIN "Order Details" od
        ON o.OrderID = od.OrderID
    GROUP BY
        e.EmployeeID,
        EmployeeName
)

SELECT
    EmployeeName,
    ROUND(Revenue, 2) AS Revenue
FROM EmployeeRevenue
WHERE Revenue >
(
    SELECT AVG(Revenue)
    FROM EmployeeRevenue
)
ORDER BY Revenue DESC;

--Products Selling Below Category Average
WITH ProductSales AS (
    SELECT
        p.ProductID,
        p.ProductName,
        c.CategoryID,
        c.CategoryName,
        SUM(od.Quantity) AS TotalSold
    FROM Products p
    JOIN Categories c
        ON p.CategoryID = c.CategoryID
    JOIN "Order Details" od
        ON p.ProductID = od.ProductID
    GROUP BY
        p.ProductID,
        p.ProductName,
        c.CategoryID,
        c.CategoryName
)

SELECT
    ProductName,
    CategoryName,
    TotalSold
FROM ProductSales ps
WHERE TotalSold <
(
    SELECT AVG(TotalSold)
    FROM ProductSales
    WHERE CategoryID = ps.CategoryID
)
ORDER BY CategoryName, TotalSold;

--Rank Employees by Revenue Within Each Shipping Country
WITH EmployeeSales AS (
    SELECT
        o.ShipCountry,
        e.EmployeeID,
        e.FirstName || ' ' || e.LastName AS EmployeeName,
        COUNT(DISTINCT o.OrderID) AS TotalOrders,
        SUM(
            od.UnitPrice * od.Quantity * (1 - od.Discount)
        ) AS TotalRevenue
    FROM Orders o
    JOIN Employees e
        ON o.EmployeeID = e.EmployeeID
    JOIN "Order Details" od
        ON o.OrderID = od.OrderID
    GROUP BY
        o.ShipCountry,
        e.EmployeeID,
        EmployeeName
),
RankedEmployees AS (
    SELECT
        *,
        RANK() OVER (
            PARTITION BY ShipCountry
            ORDER BY TotalRevenue DESC
        ) AS RevenueRank
    FROM EmployeeSales
)

SELECT
    ShipCountry,
    EmployeeName,
    TotalOrders,
    ROUND(TotalRevenue,2) AS TotalRevenue,
    RevenueRank
FROM RankedEmployees
WHERE RevenueRank <= 3
ORDER BY ShipCountry, RevenueRank;

--Customers Who Purchased From the Largest Number of Categories
SELECT
    c.CompanyName,
    COUNT(DISTINCT p.CategoryID) AS CategoriesPurchased,
    COUNT(DISTINCT o.OrderID) AS TotalOrders
FROM Customers c
JOIN Orders o
    ON c.CustomerID = o.CustomerID
JOIN "Order Details" od
    ON o.OrderID = od.OrderID
JOIN Products p
    ON od.ProductID = p.ProductID
GROUP BY
    c.CustomerID,
    c.CompanyName
HAVING COUNT(DISTINCT p.CategoryID) > 5
ORDER BY CategoriesPurchased DESC;
