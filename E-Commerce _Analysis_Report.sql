-- MySQL Project 
-- E-Commerce Customer & Sales Analysis Project 

use eccommerce_analysis;

-- 1. Total number of customers
SELECT COUNT(customer_id) as total_customers
FROM tbl_customers;

-- 2. Total number of orders
SELECT COUNT(order_id) as total_orders
FROM tbl_orders;

-- 3. Total revenue

SELECT SUM(oi.quantity * p.price) as total_revenue
FROM tbl_order_items oi
INNER JOIN tbl_products p
ON oi.product_id = p.product_id;

-- 4. Monthly revenue trend

SELECT DATE_FORMAT(o.order_date,'%m-%Y') AS month,
       SUM(oi.quantity * p.price) AS revenue
FROM tbl_orders o
INNER JOIN tbl_order_items oi ON o.order_id = oi.order_id
INNER JOIN tbl_products p ON oi.product_id = p.product_id
GROUP BY month
ORDER BY month;


-- 5. Top 3 products by revenue
SELECT p.product_id, p.product_name,
	   SUM(oi.quantity * p.price) as revenue
FROM tbl_products p
INNER JOIN tbl_order_items oi
GROUP BY p.product_id, p.product_name
ORDER BY revenue DESC
LIMIT 3;


-- 6. Top 3 customers by revenue
SELECT c.customer_id, c.customer_name,
	   SUM(oi.quantity * p.price) as revenue_by_customer
FROM tbl_customers c 
INNER JOIN tbl_orders o ON c.customer_id = o.customer_id
INNER JOIN tbl_order_items oi ON oi.order_id = o.order_id
INNER JOIN tbl_products p ON p.product_id = oi.product_id
GROUP BY c.customer_id, c.customer_name
ORDER BY revenue DESC 
LIMIT 3;

-- 7. Average order value (AOV) => total_revenue ÷ total_number_of_orders

SELECT ROUND(AVG(order_revenue),2) AS avg_order_value
FROM  (
        SELECT o.order_id,
			SUM(oi.quantity * p.price) AS order_revenue
		FROM tbl_orders o
		INNER JOIN tbl_order_items oi ON o.order_id = oi.order_id
		INNER JOIN tbl_products p ON oi.product_id = p.product_id
		WHERE o.order_status = 'Completed'
		GROUP BY o.order_id
)a ;


-- 8. Revenue by category
SELECT p.category, 
       SUM(oi.quantity * p.price) as revenue_by_category
FROM tbl_products p
INNER JOIN tbl_order_items oi ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY revenue_by_category DESC;

-- 9. Orders per customer

SELECT c.customer_id, c.customer_name, 
	   COUNT(o.order_id) as total_orders
FROM tbl_customers c
LEFT JOIN tbl_orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_orders DESC;

-- 10. Repeat customers
SELECT c.customer_id, c.customer_name, 
       COUNT(o.order_id) as total_orders
FROM tbl_customers c
LEFT JOIN tbl_orders o ON c.customer_id = o.customer_id
GROUP BY  c.customer_id, c.customer_name
HAVING COUNT(o.order_id)>1;

-- using subquery
SELECT c.customer_id, c.customer_name
FROM tbl_customers c
WHERE c.customer_id IN 
		(
			SELECT o.customer_id
			FROM tbl_orders o
			GROUP BY o.customer_id
			HAVING COUNT(o.order_id)>1
		);


-- 11. Country-wise revenue

SELECT c.country, 
	   SUM(oi.quantity * p.price) as revenue_by_country
FROM tbl_customers c 
INNER JOIN tbl_orders o ON c.customer_id = o.customer_id 
INNER JOIN tbl_order_items oi ON o.order_id = oi.order_id 
INNER JOIN tbl_products p ON p.product_id = oi.product_id 
GROUP BY c.country 
ORDER BY revenue_by_country DESC;

-- 12. First purchase date per customer

SELECT customer_id, customer_name, 
	   MIN(signup_date) as first_purchase_date
FROM tbl_customers
GROUP BY customer_id, customer_name
ORDER BY first_purchase_date;


-- 13. Customer lifetime value (CLV)

SELECT c.customer_id, c.customer_name, 
       SUM(oi.quantity * p.price) as CLV
FROM tbl_customers c 
INNER JOIN tbl_orders o ON c.customer_id = o.customer_id
INNER JOIN tbl_order_items oi ON oi.order_id = o.order_id
INNER JOIN tbl_products p ON p.product_id = oi.product_id
GROUP BY c.customer_id, c.customer_name
ORDER BY CLV DESC ;

-- 14. Days between consecutive purchases

SELECT
    customer_id,
    order_date,
    DATEDIFF(
        order_date,
        LAG(order_date) OVER ( PARTITION BY customer_id ORDER BY order_date) 
       ) AS days_between_purchases
FROM tbl_orders
WHERE order_status = 'Completed'
ORDER BY customer_id, order_date;

-- 15. Rank customers by total spend
SELECT c.customer_id, c.customer_name,
	   SUM(oi.quantity * p.price) as total_spent,
       RANK() OVER (ORDER BY SUM(oi.quantity * p.price) DESC) AS customer_rank
FROM tbl_customers c
INNER JOIN tbl_orders o ON c.customer_id = o.customer_id
INNER JOIN tbl_order_items oi ON oi.order_id = o.order_id
INNER JOIN tbl_products p ON p.product_id = oi.product_id
GROUP BY c.customer_id, c.customer_name;

-- 16. Created a stored procedure add_product that inserts a new product into the Products table if exists or else update the record

DELIMITER $$
USE `eccommerce_analysis`$$
CREATE PROCEDURE `add_product` (
IN p_product_id INT,
IN p_product_name VARCHAR(100),
IN p_category VARCHAR(100),
IN p_price DECIMAL(10,2)
)
BEGIN
	 IF p_product_id IS NULL THEN
     INSERT INTO tbl_products(product_name, category, price)
     VALUES (p_product_name, p_category, p_price);
     
     ELSE
     
	 UPDATE tbl_products
	 SET product_name = p_product_name,
		 category = p_category,
		 price = p_price
	 WHERE product_id = p_product_id;
     
     END IF;
END$$

DELIMITER ;

call add_product (NULL,'Smartwatch', 'Accessories','1500'); 
select * from tbl_products;

-- 17. Created a stored procedure to get the Revenue by Category between a given date range 

DELIMITER $$
USE `eccommerce_analysis`$$
CREATE PROCEDURE `get_category_rev_by_date` (
IN p_start_date DATE,
In p_end_date DATE
)
BEGIN
		SELECT p.category, 
               SUM(oi.quantity * p.price) as revenue
		FROM tbl_orders o
        INNER JOIN tbl_order_items oi ON o.order_id = oi.order_id
        INNER JOIN tbl_products p ON p.product_id = oi.product_id
        WHERE o.order_status = 'Completed' AND 
        o.order_date BETWEEN p_start_date AND p_end_date
        GROUP BY p.category
        ORDER BY revenue DESC;
END$$

DELIMITER ;

call get_category_rev_by_date('2023-06-01','2023-06-30');
 

-- 18. Writing a BEFORE INSERT trigger to Prevent Negative Product Price

DELIMITER $$
CREATE TRIGGER trg_valid_product_price
BEFORE INSERT ON tbl_products
FOR EACH ROW
BEGIN 
		IF NEW.price < 0 THEN
           SIGNAL SQLSTATE  '45000'
           SET MESSAGE_TEXT = 'Product price cannot be negative';
	    END IF;
END$$

insert into tbl_products (product_name, category, price)
values ('Earbuds','Accessories',-1);






