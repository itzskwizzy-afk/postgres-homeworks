-- 1. Название компании заказчика и ФИО сотрудника, когда и заказчик,
-- и сотрудник зарегистрированы в London, а доставку ведёт United Package
SELECT DISTINCT
    c.company_name AS customer,
    CONCAT(e.first_name, ' ', e.last_name) AS employee
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN employees e ON o.employee_id = e.employee_id
JOIN shippers sh ON o.ship_via = sh.shipper_id
WHERE c.city = 'London'
  AND e.city = 'London'
  AND sh.company_name = 'United Package'
ORDER BY customer, employee;


-- 2. Продукты из Dairy Products и Condiments, не снятые с продажи,
-- с остатком < 25, с информацией о поставщике
SELECT p.product_name,
       p.units_in_stock,
       s.contact_name,
       s.phone
FROM products p
JOIN suppliers s ON p.supplier_id = s.supplier_id
JOIN categories cat ON p.category_id = cat.category_id
WHERE p.discontinued = 0
  AND p.units_in_stock < 25
  AND cat.category_name IN ('Dairy Products', 'Condiments')
ORDER BY p.units_in_stock;


-- 3. Компании-заказчики, не сделавшие ни одного заказа
SELECT c.company_name
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL
ORDER BY c.company_name;


-- 4. Уникальные названия продуктов, которых заказано ровно 10 единиц
-- (через подзапрос)
SELECT p.product_name
FROM products p
WHERE p.product_id IN (
    SELECT od.product_id
    FROM order_details od
    WHERE od.quantity = 10
)
ORDER BY p.product_id;
