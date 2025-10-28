# LOGIN TO REMOTE SERVER
ssh azfar@192.168.0.77 -p 824
azfar@DS223j:~$ cd /volume1/docker/postgres/18/data

# CLONE REPO
azfar@DS223j:data$ git clone https://github.com/MIT-LCP/mimic-code.git
azfar@DS223j:data$ cd mimic-code
azfar@DS223j:mimic-code$ wget -r -N -c -np --user azfar41350 --ask-password https://physionet.org/files/mimiciv/3.1/
azfar@DS223j:mimic-code$ mv physionet.org/files/mimiciv mimiciv && rmdir physionet.org/files && rm physionet.org/robots.txt && rmdir physionet.org

# DOCKER SHELL ACCESS
azfar@DS223j:mimic-code$ sudo -i
root@DS223j:~# docker exec -it postgresdb bash
root@postgresdb:# cd /var/lib/postgresql/18/docker/3.1
root@postgresdb:/var/lib/postgresql/18/docker/3.1# 

# DATABASE SETUP FOR POSTGRESQL
createdb mimiciv
psql -d mimiciv -f mimic-iv/buildmimic/postgres/create.sql
psql -d mimiciv -v ON_ERROR_STOP=1 -v mimic_data_dir=mimiciv/3.1 -f mimic-iv/buildmimic/postgres/load_gz.sql
psql -d mimiciv -v ON_ERROR_STOP=1 -v mimic_data_dir=mimiciv/3.1 -f mimic-iv/buildmimic/postgres/constraint.sql
psql -d mimiciv -v ON_ERROR_STOP=1 -v mimic_data_dir=mimiciv/3.1 -f mimic-iv/buildmimic/postgres/index.sql

# DATABASE SETUP FOR MYSQL
mysql -u root -p
mysql use mimic-iv;
mysql source load.sql;

# DATABASE SETUP FOR DUCKDB
curl https://install.duckdb.org | sh
duckdb INSTALL mysql;
ATTACH 'host=localhost user=root port=24 database=mimic-iv' AS mimicdb (TYPE mysql);
USE mimicdb;

# REMOTE LOAD
psql -h azfar.myds.me -U postgres -p 15432 mimiciv