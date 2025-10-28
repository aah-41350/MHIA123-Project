import psycopg2               

conn = psycopg2.connect(
    host = "remote_host",  
    database = "db_name",  
    user="username",     
    password="password"
)