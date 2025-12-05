import os
from dotenv import load_dotenv
import pandas as pd
from sqlalchemy import create_engine

load_dotenv()

engine = create_engine(f"{os.getenv('DB_URL')}")

def run_query(sql):
    return pd.read_sql(sql, engine)
