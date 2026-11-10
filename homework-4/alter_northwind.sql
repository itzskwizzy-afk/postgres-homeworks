-- Домашнее задание 4. Data Definition Language (DDL)
-- alter_northwind.sql — изменение схемы базы данных northwind
-- Подключение: psql -U postgres -d northwind (или Query Tool в pgAdmin)

-- ============================================================
-- 1. Добавить ограничение на поле unit_price таблицы products
--    (цена должна быть больше 0)
-- ============================================================
ALTER TABLE products
    ADD CONSTRAINT chk_products_unit_price CHECK (unit_price > 0);

-- ============================================================
-- 2. Добавить ограничение, что поле discontinued таблицы products
--    может содержать только значения 0 или 1
-- ============================================================
ALTER TABLE products
    ADD CONSTRAINT chk_products_discontinued CHECK (discontinued IN (0, 1));

-- ============================================================
-- 3. Создать новую таблицу, содержащую все продукты,
--    снятые с продажи (discontinued = 1)
-- ============================================================
CREATE TABLE products_discontinued AS
SELECT *
FROM products
WHERE discontinued = 1;

-- CREATE TABLE ... AS не переносит ограничения из исходной таблицы,
-- поэтому первичный ключ назначаем сами
ALTER TABLE products_discontinued
    ADD CONSTRAINT products_discontinued_pkey PRIMARY KEY (product_id);

-- Проверка: в архив попали все снятые с продажи товары
SELECT product_id, product_name, unit_price
FROM products_discontinued
ORDER BY product_id;

-- ============================================================
-- 4. Удалить из products товары, снятые с продажи (discontinued = 1)
--
--    Сложность: на products ссылается order_details через внешний ключ
--    fk_order_details_products (правило NO ACTION), а снятые товары
--    встречаются в заказах, поэтому простой DELETE завершится ошибкой
--    нарушения внешнего ключа.
--
--    Вариант ON DELETE SET NULL здесь не подойдёт: product_id входит
--    в составной первичный ключ order_details (order_id, product_id),
--    а столбец первичного ключа не может быть NULL.
--
--    Решение: удалить старое ограничение и пересоздать внешний ключ
--    с правилом ON DELETE CASCADE. Связь с таблицей order_details
--    сохраняется, а позиции снятых товаров удалятся из заказов
--    автоматически — вместе с самими товарами.
-- ============================================================

-- 4.1. Удаляем текущее ограничение внешнего ключа (правило NO ACTION)
ALTER TABLE order_details DROP CONSTRAINT fk_order_details_products;

-- 4.2. Восстанавливаем связь, но уже с правилом ON DELETE CASCADE
ALTER TABLE order_details
    ADD CONSTRAINT fk_order_details_products
    FOREIGN KEY (product_id) REFERENCES products (product_id)
    ON DELETE CASCADE;

-- 4.3. Теперь удаление снятых с продажи товаров проходит без ошибок
DELETE FROM products WHERE discontinued = 1;

-- ============================================================
-- Проверка результата
-- ============================================================

-- 4.4. В products не осталось снятых с продажи товаров
SELECT COUNT(*) AS left_discontinued FROM products WHERE discontinued = 1;

-- 4.5. Позиции снятых товаров ушли из order_details вместе с товарами
SELECT COUNT(*) AS order_details_left FROM order_details;

-- 4.6. Связь с order_details на месте, теперь с правилом CASCADE
SELECT tc.constraint_name, rc.delete_rule
FROM information_schema.table_constraints tc
JOIN information_schema.referential_constraints rc
       ON tc.constraint_name = rc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name = 'order_details';

-- 4.7. Архив снятых товаров сохранился
SELECT COUNT(*) AS discontinued_count FROM products_discontinued;

-- ============================================================
-- Альтернатива для пункта 4 — если нужно вернуть внешнему ключу
-- исходное правило NO ACTION. Идея та же: сначала чистим позиции
-- снятых товаров из order_details, и тогда «висячих» ссылок не
-- остаётся, а ограничение можно создать заново в исходном виде:
--
--     ALTER TABLE order_details DROP CONSTRAINT fk_order_details_products;
--     DELETE FROM products WHERE discontinued = 1;
--     DELETE FROM order_details
--         WHERE product_id NOT IN (SELECT product_id FROM products);
--     ALTER TABLE order_details
--         ADD CONSTRAINT fk_order_details_products
--         FOREIGN KEY (product_id) REFERENCES products (product_id);
--
-- Важно: простой вариант «удалить ограничение → удалить товары →
-- добавить ограничение обратно» на этих данных не сработает — после
-- удаления товаров в order_details останутся строки со ссылками на
-- них, и повторное создание внешнего ключа упадёт на валидации.
-- ============================================================
