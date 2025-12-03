import psycopg2               

connection = psycopg2.connect(
    host="azfar.myds.me",
    database="mimiciv",
    user="postgres",
    password="PSQLpwd4!",
    port="15432"
    )

print("Connection to PostgreSQL successful!")