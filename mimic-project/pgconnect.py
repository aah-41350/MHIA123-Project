import psycopg2
try:
    psycopg2.connect(
        host="dxp4800.kudu-altair.ts.net",
        dbname="mimiciv",
        user="postgres",
        password="PSQLpwd4!",
        connect_timeout=5
    )
    print("Connected!")
except Exception as e:
    print("Error:", e)
