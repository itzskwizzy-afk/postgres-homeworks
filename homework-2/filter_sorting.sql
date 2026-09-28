SELECT ship_country, SUM(freight) AS sum
FROM orders
GROUP BY ship_country
ORDER BY sum DESC
LIMIT 3;

SELECT order_id, customer_id, freight, ship_country
FROM orders
WHERE ship_country IN ('Portugal', 'Poland')
ORDER BY freight DESC
LIMIT 10;

SELECT MIN(unit_price) AS min, MAX(unit_price) AS max
FROM products;

SELECT MIN(unit_price) AS min, MAX(unit_price) AS max
FROM products
WHERE discontinued = 0;

SELECT DISTINCT country
FROM customers
WHERE country IN ('UK', 'USA')
ORDER BY country;
