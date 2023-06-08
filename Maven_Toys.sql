--Table creation

CREATE TABLE products(
	product_id INT PRIMARY KEY,
	product_name VARCHAR,
	product_category VARCHAR,
	product_cost REAL,
	product_price REAL
);

CREATE TABLE stores(
	store_id INT PRIMARY KEY,
	store_name VARCHAR,
	store_city VARCHAR,
	store_location VARCHAR,
	store_open_date DATE
);

CREATE TABLE inventory(
	store_id INT,
	product_id INT,
	stock_on_hand INT
);

CREATE TABLE sales(
	sales_id INT PRIMARY KEY,
	date DATE,
	store_id INT,
	product_id INT,
	units INT
);

--DATA INSPECTION & CLEANING
SELECT*
FROM sales;

SELECT conname
FROM pg_constraint
WHERE conrelid = 'sales'::regclass
AND contype = 'p';

--Removing Null values from the sales table

SELECT*
FROM sales
WHERE sales_id IS NULL OR date IS NULL OR store_id IS NULL OR product_id IS NULL OR units IS NULL;

SELECT*
FROM inventory;

--Removing Null values from the inventory table
SELECT*
FROM inventory
WHERE store_id IS NULL OR product_id IS NULL OR stock_on_hand IS NULL;

SELECT*
FROM stores;

--Removing Null values from the stores table
SELECT*
FROM stores
WHERE store_id IS NULL OR store_name IS NULL OR store_city IS NULL OR store_location IS NULL OR store_open_date IS NULL;

SELECT*
FROM products;

SELECT
	DISTINCT
	product_category
FROM 
	products;

--Removing Null values from the products table
SELECT*
FROM products
WHERE product_id IS NULL OR product_name IS NULL OR product_category IS NULL OR product_cost IS NULL OR product_price IS NULL;

ALTER TABLE sales
RENAME COLUMN date TO sales_date;

--DATA MODELING AND ANALYSIS
--Qst 1(a): Which Product Category drives the biggest Profit?

SELECT  
    p.product_category,
	CAST(SUM((p.product_price - p.product_cost) * s.units) AS INTEGER) AS totalProfit
    
FROM 
    products AS p
JOIN 
	sales AS s
ON 
	p.product_id = s.product_id

GROUP BY
	product_category
ORDER BY
	totalProfit DESC;

--Result from the analysis shows that 'Toys' drives the biggest profit (1,079,527) compared to other product category.

-- 1(b) Is this the same accross all store location?

SELECT
	l.store_location,
    p.product_category,
	CAST(SUM((product_price - product_cost) * units) AS INTEGER) AS totalProfit
FROM 
    products AS p
JOIN 
	sales AS s
ON 
	p.product_id = s.product_id
JOIN 
	stores AS l
ON 
	s.store_id = l.store_id
GROUP BY
	p.product_category,
	l.store_location
ORDER BY
	l.store_location,
	totalProfit DESC;

/*Result of the finding shows that 'Electronics' drove the biggest sales in Airport and Commercial Locations while 'Toys' drove the 
biggest profit in Downtown and Residential locations
*/
	
-- Qst 2(a): How much money is tied up in inventory at the toy stores?
SELECT 
	CAST(SUM(i.stock_on_hand * p.product_cost) AS INTEGER) AS total_inventory_value
FROM 
	inventory AS i
JOIN 
	products AS p 
ON 
	i.product_id = p.product_id;

-- From the above analysis, the total amount of money tied up in inventory at the toy stores is $300,210

-- Bonus answer: Money tied up in inventory at different store locations
SELECT
	s.store_location,
	CAST(SUM(i.stock_on_hand * p.product_cost) AS INTEGER) AS total_inventory_value
FROM 
	inventory AS i
JOIN 
	products AS p 
ON 
	i.product_id = p.product_id 
JOIN
	stores AS s
ON 
	i.store_id = s.store_id
GROUP BY
	store_location
ORDER BY
	total_inventory_value DESC;


-- 2(b) How long it will last
SELECT 
	i.store_id, 
	i.product_id, 
	i.stock_on_hand / (SUM(sa.units) / COUNT(DISTINCT sa.date)) AS inventory_duration
FROM 
	inventory AS i
JOIN 
	sales AS sa 
ON 
	i.store_id = sa.store_id 
AND 
	i.product_id = sa.product_id
GROUP BY 
	i.store_id, 
	i.product_id, 
	i.stock_on_hand
ORDER BY
	inventory_duration DESC;

-- Are sales being lost with out_of_stock products at certain location?
SELECT 
	s.store_id, 
	s.store_name, 
	s.store_city, 
	s.store_location, 
	COUNT(*) AS lost_sales_count
FROM 
	stores AS s
JOIN 
	sales AS sa 
ON 
	s.store_id = sa.store_id
LEFT JOIN 
	inventory AS i 
ON 
	sa.store_id = i.store_id 
AND sa.product_id = i.product_id
WHERE 
	i.stock_on_hand <= 0
GROUP BY 
	s.store_id, 
	s.store_name, 
	s.store_city, 
	s.store_location;

--Result of the analysis shows that sales are being lost in certain locations.
