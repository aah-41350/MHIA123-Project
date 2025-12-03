# Connecting to database via Terminal with SSH
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 40
Server version: 10.11.6-MariaDB Source distribution

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

# Loading appropriate database for project
MariaDB [(none)]> use mimic-iv
Database changed

# Validating the contents of downloaded files match
MariaDB [mimic-iv]> source validate.sql;
+--------+-----------+-----------+--------------------+
| chk    | exp       | obs       | tbl                |
+--------+-----------+-----------+--------------------+
| PASSED |    546028 |    546028 | admissions         |
| PASSED | 432997491 | 432997491 | chartevents        |
| PASSED |   9979761 |   9979761 | datetimeevents     |
| PASSED |   6364488 |   6364488 | diagnoses_icd      |
| PASSED |    761856 |    761856 | drgcodes           |
| PASSED |     89208 |     89208 | d_hcpcs            |
| PASSED |    112107 |    112107 | d_icd_diagnoses    |
| PASSED |     86423 |     86423 | d_icd_procedures   |
| PASSED |      4095 |      4095 | d_items            |
| PASSED |      1650 |      1650 | d_labitems         |
| PASSED |  42808593 |  42808593 | emar               |
| PASSED |  87371064 |  87371064 | emar_detail        |
| PASSED |    186074 |    186074 | hcpcsevents        |
| PASSED |     94458 |     94458 | icustays           |
| PASSED |  10953713 |  10953713 | inputevents        |
| PASSED | 158374764 | 158374764 | labevents          |
| PASSED |   3988224 |   3988224 | microbiologyevents |
| PASSED |   7753027 |   7753027 | omr                |
| PASSED |   5359395 |   5359395 | outputevents       |
| PASSED |    364627 |    364627 | patients           |
| PASSED |  17847567 |  17847567 | pharmacy           |
| PASSED |  52212109 |  52212109 | poe                |
| PASSED |   8504982 |   8504982 | poe_detail         |
| PASSED |  20292611 |  20292611 | prescriptions      |
| PASSED |    808706 |    808706 | procedureevents    |
| PASSED |    859655 |    859655 | procedures_icd     |
| PASSED |    593071 |    593071 | services           |
| PASSED |   2413581 |   2413581 | transfers          |
+--------+-----------+-----------+--------------------+
28 rows in set (25 min 11.650 sec)

# Postgresql Verification Output
psql -U postgres -d mimiciv -f validate.sql
        tbl         | expected_count | observed_count | row_count_check 
--------------------+----------------+----------------+-----------------
 procedureevents    |         808706 |         808706 | PASSED
 d_hcpcs            |          89208 |          89208 | PASSED
 admissions         |         546028 |         546028 | PASSED
 d_icd_diagnoses    |         112107 |         112107 | PASSED
 d_icd_procedures   |          86423 |          86423 | PASSED
 d_labitems         |           1650 |           1650 | PASSED
 diagnoses_icd      |        6364488 |        6364488 | PASSED
 drgcodes           |         761856 |         761856 | PASSED
 emar               |       42808593 |       42808593 | PASSED
 emar_detail        |       87371064 |       87371064 | PASSED
 hcpcsevents        |         186074 |         186074 | PASSED
 labevents          |      158374764 |      158374764 | PASSED
 microbiologyevents |        3988224 |        3988224 | PASSED
 omr                |        7753027 |        7753027 | PASSED
 patients           |         364627 |         364627 | PASSED
 pharmacy           |       17847567 |       17847567 | PASSED
 poe                |       52212109 |       52212109 | PASSED
 poe_detail         |        8504982 |        8504982 | PASSED
 prescriptions      |       20292611 |       20292611 | PASSED
 procedures_icd     |         859655 |         859655 | PASSED
 services           |         593071 |         593071 | PASSED
 transfers          |        2413581 |        2413581 | PASSED
 icustays           |          94458 |          94458 | PASSED
 d_items            |           4095 |           4095 | PASSED
 chartevents        |      432997491 |      432997491 | PASSED
 datetimeevents     |        9979761 |        9979761 | PASSED
 inputevents        |       10953713 |       10953713 | PASSED
 outputevents       |        5359395 |        5359395 | PASSED
(28 rows)