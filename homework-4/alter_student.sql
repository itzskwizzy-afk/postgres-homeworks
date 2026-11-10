-- Домашнее задание 4. Data Definition Language (DDL)
-- alter_student.sql — работа с таблицей student
-- Команды выполняются по порядку. Писать и проверять можно в pgAdmin (Query Tool).

-- 0. Страховка на случай повторного запуска: удаляем таблицу, если она
--    осталась с прошлого раза, чтобы каждый запуск шёл с чистого листа.
DROP TABLE IF EXISTS student;

-- 1. Создать таблицу student с полями student_id serial, first_name varchar,
--    last_name varchar, birthday date, phone varchar
CREATE TABLE student (
    student_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name  VARCHAR(50),
    birthday   DATE,
    phone      VARCHAR(20)
);

-- 2. Добавить в таблицу student колонку middle_name varchar
ALTER TABLE student ADD COLUMN middle_name VARCHAR(50);

-- 3. Удалить колонку middle_name
ALTER TABLE student DROP COLUMN middle_name;

-- 4. Переименовать колонку birthday в birth_date
ALTER TABLE student RENAME COLUMN birthday TO birth_date;

-- 5. Изменить тип данных колонки phone на varchar(32)
ALTER TABLE student ALTER COLUMN phone TYPE VARCHAR(32);

-- 6. Вставить три любых записи с автогенерацией идентификатора
--    student_id не указываем — его генерирует последовательность SERIAL
INSERT INTO student (first_name, last_name, birth_date, phone) VALUES
    ('Иван',   'Петров',   '2003-04-15', '+7 900 111-22-33'),
    ('Анна',   'Сидорова', '2004-11-02', '+7 900 222-33-44'),
    ('Максим', 'Иванов',   '2002-07-20', '+7 900 333-44-55');

-- Проверка: идентификаторы проставились автоматически (1, 2, 3)
SELECT student_id, first_name, last_name, birth_date, phone
FROM student
ORDER BY student_id;

-- 7. Удалить все данные из таблицы со сбросом идентификатора в исходное состояние
--    TRUNCATE очищает таблицу, а RESTART IDENTITY сбрасывает счётчик SERIAL,
--    поэтому следующая запись снова получит student_id = 1
TRUNCATE TABLE student RESTART IDENTITY;

-- Проверка: таблица пуста
SELECT COUNT(*) AS rows_left FROM student;

-- Проверка сброса счётчика: вставляем запись и убеждаемся, что student_id = 1
INSERT INTO student (first_name, last_name, birth_date, phone)
VALUES ('Тест', 'Проверка', '2000-01-01', '+7 900 000-00-00');
SELECT student_id, first_name, last_name FROM student;

-- Убираем тестовую запись, оставляя таблицу пустой
DELETE FROM student;
