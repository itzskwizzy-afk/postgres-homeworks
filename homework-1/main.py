"""Скрипт для заполнения данными таблиц в БД Postgres."""
import csv
import os
from datetime import datetime

import psycopg2


DB_CONFIG = {
    "host": "localhost",
    "port": 5432,
    "database": "north",
    "user": "postgres",
    "password": "1234",
}

DATA_DIR = "north_data"


def parse_date(value):
    if not value or value.strip() == "":
        return None
    for fmt in ("%Y-%m-%d", "%d.%m.%Y", "%m/%d/%Y"):
        try:
            return datetime.strptime(value.strip(), fmt).date()
        except ValueError:
            continue
    return None


def load_csv(path):
    with open(path, encoding="utf-8") as f:
        return list(csv.DictReader(f))


def insert_employees(cur, rows):
    for r in rows:
        cur.execute(
            """
            INSERT INTO employees
                (first_name, last_name, title, birth_date, notes)
            VALUES (%s, %s, %s, %s, %s)
            """,
            (
                r["first_name"],
                r["last_name"],
                r.get("title"),
                parse_date(r.get("birth_date", "")),
                r.get("notes"),
            ),
        )


def insert_customers(cur, rows):
    for r in rows:
        cur.execute(
            """
            INSERT INTO customers
                (customer_id, company_name, contact_name, contact_title,
                 address, city, postal_code, country, phone)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (
                r["customer_id"],
                r["company_name"],
                r.get("contact_name"),
                r.get("contact_title"),
                r.get("address"),
                r.get("city"),
                r.get("postal_code"),
                r.get("country"),
                r.get("phone"),
            ),
        )


def insert_orders(cur, rows):
    for r in rows:
        cur.execute(
            """
            INSERT INTO orders
                (customer_id, employee_id, order_date, required_date,
                 shipped_date, ship_via, freight)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            """,
            (
                r["customer_id"],
                int(r["employee_id"]),
                parse_date(r.get("order_date", "")),
                parse_date(r.get("required_date", "")),
                parse_date(r.get("shipped_date", "")),
                int(r["ship_via"]) if r.get("ship_via") else None,
                float(r["freight"]) if r.get("freight") else None,
            ),
        )


def main():
    conn = psycopg2.connect(**DB_CONFIG)
    try:
        with conn.cursor() as cur:
            insert_employees(cur, load_csv(os.path.join(DATA_DIR, "employees_data.csv")))
            insert_customers(cur, load_csv(os.path.join(DATA_DIR, "customers_data.csv")))
            insert_orders(cur, load_csv(os.path.join(DATA_DIR, "orders_data.csv")))
        conn.commit()
        print("Готово: данные загружены.")
    except Exception as e:
        conn.rollback()
        print("Ошибка:", e)
        raise
    finally:
        conn.close()


if __name__ == "__main__":
    main()
