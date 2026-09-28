SELECT country, COUNT(*) AS count
FROM customers
GROUP BY country
ORDER BY count DESC;

SELECT country
FROM customers
GROUP BY country
ORDER BY COUNT(*) DESC
LIMIT 10;

SELECT DISTINCT ship_city AS city
FROM orders
ORDER BY city;

SELECT COUNT(*) AS count FROM orders;

SELECT COUNT(*) AS count
FROM orders
WHERE order_date BETWEEN '1997-01-01' AND '1997-12-31';

SELECT AVG(freight) AS avg FROM orders;

SELECT order_id, COUNT(*) AS count
FROM order_details
GROUP BY order_id
ORDER BY order_id;
