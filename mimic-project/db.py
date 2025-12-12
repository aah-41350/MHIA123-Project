import os
from dotenv import load_dotenv
import pandas as pd
from sqlalchemy import create_engine, text
import duckdb

load_dotenv()

engine = create_engine(f"postgresql://{os.getenv('PGUSER')}:{os.getenv('PGPASSWORD')}@{os.getenv('PGHOST')}:{os.getenv('PGPORT')}/{os.getenv('PGDATABASE')}")

def run_query(sql):
    return pd.read_sql(sql, engine)

def temp_query(sql):
    with engine.connect() as conn:
        conn.execute(text(sql))

def duck_query_df(query):
    con = duckdb.connect()
    con.install_extension('postgres')
    con.load_extension('postgres')

    # Clear cache to free up memory
    con.sql("CALL pg_clear_cache();")

    # Attach the Postgres database using environment variables
    con.sql(f"ATTACH 'dbname={os.getenv('PGDATABASE')} user={os.getenv('PGUSER')} \
            password={os.getenv('PGPASSWORD')} host={os.getenv('PGHOST')}'" \
            "AS db (TYPE postgres, READ_ONLY);")
    
    # Run the query and return the result as a pandas DataFrame
    result = con.sql(query).df()
    con.close()
    return result