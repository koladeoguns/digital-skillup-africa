
CREATE TABLE SaleData (
    Row_ID INT,
    Order_ID BIGINT,
    Order_Date DATE,
    Order_Priority VARCHAR(50),
    Order_Quantity INT,
    Sales DECIMAL(10,2),
    Discount DECIMAL(5,2),
    Ship_Mode VARCHAR(50),
    Profit DECIMAL(10,2),
    Unit_Price DECIMAL(10,2),
    Shipping_Cost DECIMAL(10,2),
    Customer_Name VARCHAR(100),
    Province VARCHAR(100),
    Region VARCHAR(100),
    Customer_Segment VARCHAR(100),
    Product_Category VARCHAR(100),
    Product_Sub_Category VARCHAR(100),
    Product_Name VARCHAR(255),
    Product_Container VARCHAR(100),
    Product_Base_Margin DECIMAL(5,2),
    Ship_Date DATE
	)
	select * from DataTest
	------Which product category had the highest sales?------- 1

	SELECT TOP 1 [Product_Category], SUM(CAST(Sales AS FLOAT)) AS TotalSales
FROM DataTest
GROUP BY [Product_Category]
ORDER BY TotalSales DESC

	-------What are the Top 3 and Bottom 3 regions in terms of sales?--------- 2

	SELECT TOP 3 Region, SUM(CAST(Sales AS FLOAT)) AS TotalSales
FROM DataTest
GROUP BY Region
ORDER BY TotalSales DESC

SELECT Region, SUM(CAST(Sales AS FLOAT)) AS TotalSales
FROM DataTest
GROUP BY Region
ORDER BY TotalSales ASC


SELECT TOP 3 Region, SUM(CAST(Sales AS FLOAT)) AS TotalSales
FROM DataTest
GROUP BY Region
ORDER BY TotalSales ASC

-------What were the total sales of appliances in Ontario?----- 3

SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'DataTest';

SELECT TOP 10 * FROM DataTest;

SELECT DISTINCT Product_Category, Product_Sub_Category
FROM DataTest
WHERE Product_Sub_Category = 'Appliances';

SELECT SUM(CAST(Sales AS FLOAT)) AS total_appliance_sales
FROM DataTest
WHERE Product_Category = 'Office Supplies'
  AND Product_Sub_Category = 'Appliances'
  AND Province = 'Ontario';

  -------Advise the management of KMS on what to do to increase the revenue from the bottom 10 customers------ 4

  ---Define your bottom customers---
  SELECT TOP 10 "Customer_Name", 
       SUM(CAST(Sales AS FLOAT)) AS total_sales
FROM DataTest
GROUP BY "Customer_Name"
ORDER BY total_sales ASC

---Analyze purchase frequency---
WITH CustomerSales AS (
    SELECT "Customer_Name", SUM(CAST(Sales AS FLOAT)) AS total_sales
    FROM DataTest
    GROUP BY "Customer_Name"
),
BottomCustomers AS (
    SELECT TOP 10 "Customer_Name"
    FROM CustomerSales
    ORDER BY total_sales
)
SELECT
    D."Customer_Name",
    COUNT(DISTINCT D."Order_ID") AS order_count,
    COUNT(DISTINCT D."Product_Name") AS unique_products,
    COUNT(DISTINCT D."Product_Category") AS unique_categories,
    AVG(CAST(D.Sales AS FLOAT)) AS avg_order_value,
    SUM(CAST(D.Sales AS FLOAT)) AS total_sales
FROM DataTest D
JOIN BottomCustomers bc ON D."Customer_Name" = bc."Customer_Name"
GROUP BY D."Customer_Name"
ORDER BY total_sales;

---Analyze product variety---
WITH BottomCustomers AS (
    SELECT TOP 10 "Customer_Name"
    FROM DataTest
    GROUP BY "Customer_Name"
    ORDER BY SUM(CAST(Sales AS FLOAT)) ASC
)

SELECT 
    D."Customer_Name",
    COUNT(DISTINCT D."Product_Name") AS unique_products,
    COUNT(DISTINCT D."Product_Category") AS unique_categories
FROM DataTest D
WHERE D."Customer_Name" IN (
    SELECT "Customer_Name" FROM BottomCustomers
)
GROUP BY D."Customer_Name";

----Analyze average order value----

WITH CustomerSales AS (
    SELECT 
        "Customer_Name",
        SUM(CAST(Sales AS FLOAT)) AS total_sales
    FROM DataTest
    GROUP BY "Customer_Name"
),
BottomCustomers AS (
    SELECT TOP 10 "Customer_Name"
    FROM CustomerSales
    ORDER BY total_sales ASC
)
SELECT 
    D."Customer_Name",
    AVG(CAST(D.Sales AS FLOAT)) AS avg_order_value
FROM DataTest D
JOIN BottomCustomers bc ON D."Customer_Name" = bc."Customer_Name"
GROUP BY D."Customer_Name";

-----Customer Profiling Dashboard Using a Pivot Table (Excel)------

WITH CustomerMetrics AS (
    SELECT 
        "Customer_Name",
        COUNT(DISTINCT "Order_ID") AS order_count,
        COUNT(DISTINCT "Product_Name") AS unique_products,
        COUNT(DISTINCT "Product_Category") AS unique_categories,
        AVG(CAST(Sales AS FLOAT)) AS avg_order_value,
        SUM(CAST(Sales AS FLOAT)) AS total_sales
    FROM DataTest
    GROUP BY "Customer_Name"
),
BottomCustomers AS (
    SELECT TOP 10 "Customer_Name"
    FROM CustomerMetrics
    ORDER BY total_sales ASC
)
SELECT 
    cm."Customer_Name",
    cm.order_count,
    cm.unique_products,
    cm.unique_categories,
    cm.avg_order_value,
    cm.total_sales,
    CASE 
        WHEN cm.order_count < 3 THEN 'Low Frequency'
        ELSE 'Normal Frequency'
    END AS frequency_label,
    CASE 
        WHEN cm.unique_products < 3 THEN 'Low Variety'
        ELSE 'Normal Variety'
    END AS variety_label,
    CASE 
        WHEN cm.avg_order_value < 50 THEN 'Low AOV'
        ELSE 'Normal AOV'
    END AS aov_label
FROM CustomerMetrics cm
JOIN BottomCustomers bc ON cm."Customer_Name" = bc."Customer_Name"
ORDER BY cm.total_sales ASC;

---Which shipping method incurred the most total shipping cost?---- 5

SELECT TOP 1 [Ship_Mode], 
       SUM(CAST([Shipping_Cost] AS FLOAT)) AS total_shipping_cost
FROM DataTest
GROUP BY [Ship_Mode]
ORDER BY total_shipping_cost DESC;

-----Who are the most valuable customers, and what products or services do they typically purchase---- 6

WITH CustomerValue AS (
    SELECT 
        [Customer_Name],
        SUM(CAST([Sales] AS FLOAT)) AS total_sales,
        SUM(CAST([Profit] AS FLOAT)) AS total_profit,
        COUNT(DISTINCT [Order_ID]) AS order_count
    FROM DataTest
    GROUP BY [Customer_Name]
),
TopCustomers AS (
    SELECT TOP 20 [Customer_Name]
    FROM CustomerValue
    ORDER BY total_sales DESC
)
SELECT 
    D.[Customer_Name],
    COUNT(DISTINCT D.[Order_ID]) AS orders,
    COUNT(DISTINCT D.[Product_Name]) AS products_bought,
    COUNT(DISTINCT D.[Product_Category]) AS categories_bought,
    STUFF((
        SELECT DISTINCT ', ' + DC.[Product_Category]
        FROM DataTest DC
        WHERE DC.[Customer_Name] = D.[Customer_Name]
        FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS top_categories,
    STUFF((
        SELECT DISTINCT ', ' + DC.[Product_Sub_Category]
        FROM DataTest DC
        WHERE DC.[Customer_Name] = D.[Customer_Name]
        FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS top_subcategories
FROM DataTest D
JOIN TopCustomers TC ON D.[Customer_Name] = TC.[Customer_Name]
GROUP BY D.[Customer_Name]
ORDER BY orders DESC;

-----Which small business customer had the highest sales?----- 7

SELECT TOP 1
    [Customer_Name],
    SUM(CAST([Sales] AS FLOAT)) AS total_sales
FROM DataTest
WHERE [Customer_Segment] = 'Small Business'
GROUP BY [Customer_Name]
ORDER BY total_sales DESC;

-------Which Corporate Customer placed the most number of orders in 2009 – 2012?----- 8

SELECT TOP 1
    [Customer_Name],
    COUNT(DISTINCT [Order_ID]) AS order_count
FROM DataTest
WHERE 
    [Customer_Segment] = 'Corporate'
    AND YEAR(CAST([Order_Date] AS DATE)) BETWEEN 2009 AND 2012
GROUP BY [Customer_Name]
ORDER BY order_count DESC;

------Which consumer customer was the most profitable one?----- 9

SELECT TOP 1
    [Customer_Name],
    SUM(CAST([Profit] AS FLOAT)) AS total_profit
FROM DataTest
WHERE [Customer_Segment] = 'Consumer'
GROUP BY [Customer_Name]
ORDER BY total_profit DESC;

------Which customer returned items, and what segment do they belong to?----- 10

SELECT TOP 10 *
FROM DataTest
WHERE CAST([Profit] AS FLOAT) < 0
   OR CAST([Sales] AS FLOAT) < 0;

SELECT DISTINCT
    [Customer_Name],
    [Customer_Segment]
FROM DataTest
WHERE CAST([Profit] AS FLOAT) < 0;







