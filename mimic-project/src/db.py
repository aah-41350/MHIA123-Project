import os
from dotenv import load_dotenv
import pandas as pd
from sqlalchemy import create_engine, text
import duckdb
import psycopg2

load_dotenv()

###########################################################################
                        ### SQL LOAD FUNCTION ###
###########################################################################
def load_sql(filename):
    #base_path = os.path.dirname(os.path.abspath(__file__))
    file_path = os.path.join(".", "sql", filename)

    try:
        with open(file_path, 'r', encoding='utf-8') as sql_file:
            return sql_file.read()
    except FileNotFoundError:
        return f"Error: The file {filename} was not found at {file_path}"

###########################################################################
                        ### DUCKDB FUNCTIONS ###
###########################################################################
con = duckdb.connect()

def attach_duckdb(dbname="remote_mimic", dbtype="POSTGRES"):
    try:
        con.sql(f"""
                INSTALL postgres_scanner;
                LOAD postgres_scanner;
                ATTACH 'dbname={os.getenv("PGDATABASE")} user={os.getenv("PGUSER")}\
                    password={os.getenv("PGPASSWORD")} host={os.getenv("PGHOST")}\
                        port={os.getenv("PGPORT")}' AS {dbname} (TYPE {dbtype});
                """)
        print("DuckDB attached to remote PostgreSQL successfully.")

    except Exception as e:
        print(f"Error attaching PostgreSQL: {e}")

def duckdb_to_df(query):
    result = con.execute(query).df()
    return result

###########################################################################
                        ### POSTGRESQL FUNCTIONS ###
###########################################################################
def psql():
    try:
        psycopg2.connect(
            host=f"{os.getenv('PGHOST')}",
            dbname=f"{os.getenv('PGDATABASE')}",
            user=f"{os.getenv('PGUSER')}",
            password=f"{os.getenv('PGPASSWORD')}",
            connect_timeout=5
        )
        print("Connected!")
    except Exception as e:
        print("Error:", e)
        
engine = create_engine(f"postgresql://{os.getenv('PGUSER')}:{os.getenv('PGPASSWORD')}\
                       @{os.getenv('PGHOST')}:{os.getenv('PGPORT')}/{os.getenv('PGDATABASE')}")

def pg_df_query(sql):
    return pd.read_sql(sql, engine)

def pg_ex_query(sql):
    with engine.connect() as conn:
        conn.execute(text(sql))