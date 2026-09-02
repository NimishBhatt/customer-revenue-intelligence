from pathlib import Path
import os

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine


# --------------------------------------------------
# 1. FIND PROJECT FOLDERS
# --------------------------------------------------

PROJECT_ROOT = Path(__file__).resolve().parents[1]

RAW_DATA_DIR = PROJECT_ROOT / "data" / "raw"


# --------------------------------------------------
# 2. LOAD DATABASE SETTINGS FROM .env
# --------------------------------------------------

load_dotenv(PROJECT_ROOT / ".env")

db_host = os.getenv("DB_HOST")
db_port = os.getenv("DB_PORT")
db_name = os.getenv("DB_NAME")
db_user = os.getenv("DB_USER")
db_password = os.getenv("DB_PASSWORD")


# --------------------------------------------------
# 3. CREATE CONNECTION TO POSTGRESQL
# --------------------------------------------------

database_url = (
    f"postgresql+psycopg2://{db_user}:{db_password}"
    f"@{db_host}:{db_port}/{db_name}"
)

engine = create_engine(database_url)


# --------------------------------------------------
# 4. MAP CSV FILES TO DATABASE TABLES
# --------------------------------------------------

files = {
    "olist_customers_dataset.csv": "customers",
    "olist_orders_dataset.csv": "orders",
    "olist_order_items_dataset.csv": "order_items",
    "olist_order_payments_dataset.csv": "payments",
    "olist_order_reviews_dataset.csv": "reviews",
    "olist_products_dataset.csv": "products",
    "olist_sellers_dataset.csv": "sellers",
    "product_category_name_translation.csv": "category_translation",
    "olist_geolocation_dataset.csv": "geolocation",
}


# --------------------------------------------------
# 5. LOAD EACH CSV INTO POSTGRESQL
# --------------------------------------------------

for file_name, table_name in files.items():

    file_path = RAW_DATA_DIR / file_name

    print(f"\nLoading: {file_name}")

    df = pd.read_csv(file_path)

    print(f"Rows: {len(df):,}")
    print(f"Columns: {len(df.columns)}")

    df.to_sql(
        table_name,
        engine,
        if_exists="replace",
        index=False,
        chunksize=5000,
        method="multi",
    )

    print(f"Created table: {table_name}")


print("\n--------------------------------")
print("DATA LOAD COMPLETE")
print("--------------------------------")