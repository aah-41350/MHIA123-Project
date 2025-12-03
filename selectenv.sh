# LAN SERVER LOGIN
ssh azfar@192.168.0.77

# SSH TUNNEL SETUP FOR REMOTE DB ACCESS
ssh -R 15432:localhost:5432 -N azfar@ds223j.kudu-altair.ts.net

# LOGIN TO REMOTE SERVER
ssh azfar@ds223j.kudu-altair.ts.net
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
psql -U postgres -d mimiciv -f mimic-iv/buildmimic/postgres/create.sql
psql -U postgres -d mimiciv -v ON_ERROR_STOP=1 -v mimic_data_dir=./ -f load_gz.sql &
psql -U postgres -d mimiciv -v ON_ERROR_STOP=1 -v mimic_data_dir=./ -f constraint.sql &
psql -U postgres -d mimiciv -v ON_ERROR_STOP=1 -v mimic_data_dir=./ -f index.sql &

# REMOTE LOAD
psql -h ds223j.kudu-altair.ts.net -U postgres -p 15432 mimiciv

# pgAdmin DATA FILES
/volume1/docker/pgadmin4/9.9/data/storage/azfarn_me.com 

# DATABASE SETUP FOR MYSQL
mysql -u root -p
mysql use mimic-iv;
mysql source load.sql;

# DATABASE SETUP FOR DUCKDB
curl https://install.duckdb.org | sh
duckdb INSTALL mysql;
ATTACH 'host=localhost user=root port=24 database=mimic-iv' AS mimicdb (TYPE mysql);
USE mimicdb;