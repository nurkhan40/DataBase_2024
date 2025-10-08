--Task A1

INSERT INTO products (product_name, category, price, stock_quantity, supplier_id) VALUES
('Wireless Mouse', 'Electronics', 25.99, 50, 3);

--A2
INSERT INTO suppliers (supplier_name, contact_email, active_status) VALUES
('Tech Supplies Co.', 'tech@suppliers.com', TRUE),
('Office Direct', 'info@officedirect.com', TRUE);

--A3
INSERT INTO product (product_name, , category, price, stock_quantity, supplier_id)VALUES
('USB Cabel', 'Accessories', 15.50 * 1.2, 100, 2);

--B1
UPDATE products 
SET price = price * 1.15 
WHERE category = 'Electronics';

--B2
UPDATE products
SET category =
    CASE
        WHEN stock_quantity > 100 THEN 'Overstock'
        WHEN stock_quantity BETWEEN 20 AND 100 THEN 'Regular'
        ELSE 'Low Stock'
    END;

--B3
UPDATE products
SET
    price = price * 1.5,
    stock_quantity = stock_quantity + 20
WHERE
    price < 10; 

--C1
DELETE FROM products 
WHERE stock_quantity = 0 AND price > 50.0;

--C2
DELETE FROM suppliers
WHERE supplier_id NOT IN (
    SELECT DISTINCT supplier_id
    FROM products
    WHERE supplier_id IS NOT NULL
);

--D1
INSERT INTO product (product_name, category, price, stock_quantity, supplier_id) VALUES
('Mystery Item', NULL, NULL, 10, 1);

--D2
UPDATE products
SET price = 99.99
WHERE category IS NULL
RETURNING product_id, product_name;