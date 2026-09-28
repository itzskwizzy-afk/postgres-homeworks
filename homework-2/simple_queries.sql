SELECT order_id, customer_id, employee_id, order_date, required_date,
       shipped_date, ship_via, freight, ship_name, ship_address,
       ship_city, ship_region, ship_postal_code, ship_country
FROM orders;

SELECT DISTINCT ship_country, ship_city
FROM orders
ORDER BY ship_country, ship_city;

SELECT first_name, last_name, home_phone
FROM employees;

SELECT contact_name, city
FROM customers;

SELECT DISTINCT city
FROM customers
ORDER BY city;
