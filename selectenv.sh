source ./mimicproject/bin/activate

ssh ***@localhost
cd /.../phpmyadmin/uploads/
mysql -u root -p

mysql use mimic-iv;
mysql source load.sql;

curl https://install.duckdb.org | sh
duckdb INSTALL mysql;
ATTACH 'host=localhost user=root port=24 database=mimic-iv' AS mimicdb (TYPE mysql);
USE mimicdb;