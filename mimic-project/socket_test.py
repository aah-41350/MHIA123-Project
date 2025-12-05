import psycopg2
try:
    psycopg2.connect(
        host="100.101.9.39",
        dbname="mimiciv",
        user="postgres",
        password="PSQLpwd4!",
        connect_timeout=5
    )
    print("Connected!")
except Exception as e:
    print("Error:", e)
