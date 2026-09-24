from pathlib import Path
import os

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL


# --------------------------------------------------
# 1. FIND PROJECT FOLDERS
# --------------------------------------------------

PROJECT_ROOT = Path(__file__).resolve().parents[1]
PROCESSED_DATA_DIR = PROJECT_ROOT / "data" / "processed"

PROCESSED_DATA_DIR.mkdir(parents=True, exist_ok=True)


# --------------------------------------------------
# 2. LOAD DATABASE SETTINGS
# --------------------------------------------------

load_dotenv(PROJECT_ROOT / ".env")

database_settings = {
    "host": os.getenv("DB_HOST"),
    "port": os.getenv("DB_PORT"),
    "database": os.getenv("DB_NAME"),
    "username": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD"),
}

missing_settings = [
    name
    for name, value in database_settings.items()
    if not value
]

if missing_settings:
    missing = ", ".join(missing_settings)
    raise ValueError(f"Missing database settings: {missing}")


# --------------------------------------------------
# 3. CREATE POSTGRESQL CONNECTION
# --------------------------------------------------

database_url = URL.create(
    drivername="postgresql+psycopg2",
    username=database_settings["username"],
    password=database_settings["password"],
    host=database_settings["host"],
    port=int(database_settings["port"]),
    database=database_settings["database"],
)

engine = create_engine(database_url)


# --------------------------------------------------
# 4. MAP DATABASE VIEWS TO CSV FILES
# --------------------------------------------------

analysis_views = {
    "customer_rfm": "customer_rfm.csv",
    "vw_cohort_retention": "cohort_retention.csv",
    "vw_product_category_performance":
        "product_category_performance.csv",
    "vw_top_products": "top_products.csv",
    "vw_product_abc_analysis": "product_abc_analysis.csv",
    "vw_category_satisfaction": "category_satisfaction.csv",
    "vw_category_business_priorities":
        "category_business_priorities.csv",
}


# --------------------------------------------------
# 5. EXTRACT THE ANALYSIS DATA
# --------------------------------------------------

print("\n--------------------------------")
print("EXTRACTING ANALYSIS DATA")
print("--------------------------------")

with engine.connect() as connection:

    connection.execute(text("SELECT 1"))

    for view_name, output_file in analysis_views.items():

        print(f"\nReading view: {view_name}")

        query = text(f"SELECT * FROM public.{view_name}")

        dataframe = pd.read_sql_query(
            query,
            connection,
        )

        if dataframe.empty:
            print(f"Warning: {view_name} returned no rows.")
            continue

        output_path = PROCESSED_DATA_DIR / output_file

        dataframe.to_csv(
            output_path,
            index=False,
        )

        print(f"Rows exported: {len(dataframe):,}")
        print(f"Saved: {output_path.relative_to(PROJECT_ROOT)}")


engine.dispose()

print("\n--------------------------------")
print("ANALYSIS DATA EXTRACTION COMPLETE")
print("--------------------------------")