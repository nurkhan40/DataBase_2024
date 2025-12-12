--Part A
--1
SELECT 
    LOWER(product_name) AS lower_product_name,
    category || ' (Category)' AS category,
    SUBSTR(supplier_name, -3) AS last_3_supplier_chars;
FROM products;

--2 
SELECT 
    product_name,
    CASE
        WHEN rating >= 4.5 THEN 'Top Rated'
        WHEN rating >= 3.0 THEN 'Good'
        ELSE 'Poor'
    END AS rating_category
    FROM products;

--3
SELECT
    customer_id,
    username
    FROM customers
    WHERE username LIKE '%123' OR username LIKE '%456';
--Part B
--1
SELECT 
    stock_level,
    unit_price
    CASE
        WHEN stock_level < 20 THEN AND unit_price > 50
    FROM products;

--2
    SELECT
        unit_price,
        quantity_sold,
        discount_applied,
        unit_price * quantity_sold * (1 - discount_applied / 100.0) AS final_price
    FROM sales;

--3
SELECT 
    customer_id,
    loyalty_points
    FROM customers
    WHERE join_date > '2023-01-01' OR loyalty_points > 1000;
--Part C
--1
SELECT 
    category,
    COUNT(*) AS product_count
    FROM products
    GROUP BY category;

--2
SELECT 
    city,
    AVG(loyalty_points) AS avg_loyalty_points
    FROM customers
    GROUP BY city
    HAVING AVG(loyalty_points) > 500;

--3
SELECT 
    product_id,
    SUM(quantity_sold) AS total_quantity_sold
FROM sales
GROUP BY product_id;

--4
SELECT 
    supplier_name,
    MIN(unit_price) AS min_unit_price,
    MAX(unit_price) AS max_unit_price
FROM products
GROUP BY supplier_name;
--Part D
--1
SELECT
    quantity_sold
FROM
--2
SELECT
    loyality_points
    WHERE loyality_points < 'Seatle'
