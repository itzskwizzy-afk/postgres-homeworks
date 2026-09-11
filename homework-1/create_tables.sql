-- SQL-команды для создания таблиц

CREATE TABLE employees (
    employee_id   SERIAL PRIMARY KEY,
    first_name    VARCHAR(50) NOT NULL,
    last_name     VARCHAR(50) NOT NULL,
    title         VARCHAR(100),
    birth_date    DATE,
    notes         TEXT
);

CREATE TABLE customers (
    customer_id   VARCHAR(10) PRIMARY KEY,
    company_name  VARCHAR(100) NOT NULL,
    contact_name  VARCHAR(100),
    contact_title VARCHAR(100),
    address       VARCHAR(150),
    city          VARCHAR(50),
    postal_code   VARCHAR(20),
    country       VARCHAR(50),
    phone         VARCHAR(30)
);

CREATE TABLE orders (
    order_id       SERIAL PRIMARY KEY,
    customer_id    VARCHAR(10) NOT NULL,
    employee_id    INTEGER NOT NULL,
    order_date     DATE,
    required_date  DATE,
    shipped_date   DATE,
    ship_via       INTEGER,
    freight        NUMERIC(10,2),
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_orders_employee
        FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);
