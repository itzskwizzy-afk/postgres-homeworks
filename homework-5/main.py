import json
import re
from pathlib import Path

import psycopg2
from psycopg2 import sql

from config import config

BASE_DIR = Path(__file__).resolve().parent
SCRIPT_FILE = BASE_DIR / "fill_db.sql"
JSON_FILE = BASE_DIR / "suppliers.json"
DB_NAME = "northwind_suppliers"


def create_database(params: dict, db_name: str) -> None:
    connect_params = dict(params)
    connect_params.pop("dbname", None)
    connect_params["dbname"] = "postgres"

    conn = psycopg2.connect(**connect_params)
    conn.autocommit = True
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT 1 FROM pg_database WHERE datname = %s", (db_name,)
            )
            if cur.fetchone():
                print(f"БД {db_name} уже существует — создание пропущено")
            else:
                cur.execute(
                    sql.SQL("CREATE DATABASE {}").format(sql.Identifier(db_name))
                )
    finally:
        conn.close()


def split_sql_statements(script: str) -> list[str]:
    statements: list[str] = []
    buffer: list[str] = []
    in_single = False
    in_double = False
    in_line_comment = False

    i = 0
    length = len(script)
    while i < length:
        char = script[i]
        next_char = script[i + 1] if i + 1 < length else ""

        if in_line_comment:
            if char == "\n":
                in_line_comment = False
                buffer.append(char)
            i += 1
            continue

        if not in_single and not in_double and char == "-" and next_char == "-":
            in_line_comment = True
            i += 2
            continue

        if char == "'" and not in_double:
            if in_single and next_char == "'":
                buffer.append(char)
                buffer.append(next_char)
                i += 2
                continue
            in_single = not in_single
        elif char == '"' and not in_single:
            in_double = not in_double

        if char == ";" and not in_single and not in_double:
            statement = "".join(buffer).strip()
            if statement:
                statements.append(statement)
            buffer = []
        else:
            buffer.append(char)
        i += 1

    tail = "".join(buffer).strip()
    if tail:
        statements.append(tail)

    return statements


def execute_sql_script(cur, script_file: str) -> None:
    with open(script_file, encoding="utf-8") as file:
        script = file.read()

    statements = split_sql_statements(script)
    for number, statement in enumerate(statements, start=1):
        cur.execute(statement)
        if number % 100 == 0:
            print(f"  выполнено запросов: {number}")
    print(f"  всего выполнено запросов: {len(statements)}")


def create_suppliers_table(cur) -> None:
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS suppliers (
            supplier_id   smallint PRIMARY KEY,
            company_name  varchar(80) NOT NULL,
            contact_name  varchar(80),
            country       varchar(40),
            state         varchar(40),
            postal_code   varchar(20),
            city          varchar(60),
            street        varchar(120),
            phone         varchar(30),
            fax           varchar(30),
            homepage      varchar(120)
        )
        """
    )


def clean_value(value: str) -> str:
    if value is None:
        return ""
    return re.sub(r"\s+", " ", value.replace("#", "")).strip()


def parse_address(raw_address: str) -> dict:
    parts = [clean_value(part) for part in (raw_address or "").split(";")]
    parts += [""] * (5 - len(parts))
    country, state, postal_code, city, street = parts[:5]
    return {
        "country": country,
        "state": state,
        "postal_code": postal_code,
        "city": city,
        "street": street,
    }


def get_suppliers_data(json_file: str) -> list[dict]:
    with open(json_file, encoding="utf-8") as file:
        raw_data = json.load(file)

    suppliers: list[dict] = []
    for supplier_id, supplier in enumerate(raw_data, start=1):
        address = parse_address(supplier.get("address", ""))
        suppliers.append(
            {
                "supplier_id": supplier_id,
                "company_name": clean_value(supplier.get("company_name", "")),
                "contact_name": clean_value(supplier.get("contact", "")),
                "phone": clean_value(supplier.get("phone", "")),
                "fax": clean_value(supplier.get("fax", "")),
                "homepage": clean_value(supplier.get("homepage", "")),
                "products": supplier.get("products", []) or [],
                **address,
            }
        )
    return suppliers


def insert_suppliers_data(cur, suppliers: list[dict]) -> None:
    cur.executemany(
        """
        INSERT INTO suppliers (
            supplier_id, company_name, contact_name,
            country, state, postal_code, city, street,
            phone, fax, homepage
        )
        VALUES (
            %(supplier_id)s, %(company_name)s, %(contact_name)s,
            %(country)s, %(state)s, %(postal_code)s, %(city)s, %(street)s,
            %(phone)s, %(fax)s, %(homepage)s
        )
        ON CONFLICT (supplier_id) DO UPDATE SET
            company_name = EXCLUDED.company_name,
            contact_name = EXCLUDED.contact_name,
            country      = EXCLUDED.country,
            state        = EXCLUDED.state,
            postal_code  = EXCLUDED.postal_code,
            city         = EXCLUDED.city,
            street       = EXCLUDED.street,
            phone        = EXCLUDED.phone,
            fax          = EXCLUDED.fax,
            homepage     = EXCLUDED.homepage
        """,
        suppliers,
    )


def add_foreign_keys(cur, json_file: str) -> None:
    cur.execute(
        """
        ALTER TABLE products
            ADD COLUMN IF NOT EXISTS supplier_id smallint
        """
    )

    with open(json_file, encoding="utf-8") as file:
        raw_data = json.load(file)

    product_to_supplier: dict[str, int] = {}
    for supplier_id, supplier in enumerate(raw_data, start=1):
        for product_name in supplier.get("products", []) or []:
            product_to_supplier[clean_value(product_name)] = supplier_id

    cur.execute("SELECT product_id, product_name FROM products")
    updated = 0
    unmatched: list[str] = []
    for product_id, product_name in cur.fetchall():
        supplier_id = product_to_supplier.get(clean_value(product_name))
        if supplier_id is None:
            unmatched.append(product_name)
            continue
        cur.execute(
            "UPDATE products SET supplier_id = %s WHERE product_id = %s",
            (supplier_id, product_id),
        )
        updated += 1

    cur.execute(
        """
        ALTER TABLE products
            DROP CONSTRAINT IF EXISTS fk_products_suppliers
        """
    )
    cur.execute(
        """
        ALTER TABLE products
            ADD CONSTRAINT fk_products_suppliers
            FOREIGN KEY (supplier_id) REFERENCES suppliers (supplier_id)
            ON DELETE SET NULL
        """
    )

    print(f"  поставщик проставлен у {updated} товаров")
    if unmatched:
        print(f"  без поставщика осталось {len(unmatched)} товаров "
              f"(например: {', '.join(unmatched[:5])})")


def main() -> None:
    params = config(filename=str(BASE_DIR / "database.ini"))

    create_database(params, DB_NAME)
    print(f"БД {DB_NAME} успешно создана")

    params = dict(params)
    params["dbname"] = DB_NAME

    conn = None
    try:
        with psycopg2.connect(**params) as conn:
            with conn.cursor() as cur:
                execute_sql_script(cur, str(SCRIPT_FILE))
                print(f"БД {DB_NAME} успешно заполнена")

                create_suppliers_table(cur)
                print("Таблица suppliers успешно создана")

                suppliers = get_suppliers_data(str(JSON_FILE))
                insert_suppliers_data(cur, suppliers)
                print(f"Данные в suppliers успешно добавлены ({len(suppliers)} строк)")

                add_foreign_keys(cur, str(JSON_FILE))
                print("FOREIGN KEY успешно добавлены")

                cur.execute(
                    """
                    SELECT COUNT(*) AS linked
                    FROM products p
                    JOIN suppliers s ON p.supplier_id = s.supplier_id
                    """
                )
                print(f"  связано товаров с поставщиками: {cur.fetchone()[0]}")

        conn.commit()
    except (Exception, psycopg2.DatabaseError) as error:
        print("Ошибка:", error)
        if conn is not None:
            conn.rollback()
        raise
    finally:
        if conn is not None:
            conn.close()


if __name__ == "__main__":
    main()
