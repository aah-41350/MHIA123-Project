import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

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
