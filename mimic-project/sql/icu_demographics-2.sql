DROP TABLE IF EXISTS tmp_pat_adm_windows;

CREATE TEMP TABLE tmp_pat_adm_windows AS
SELECT
      *,
      DENSE_RANK() OVER (PARTITION BY subject_id ORDER BY admittime) AS hosp_stay_num,
      EXTRACT(EPOCH FROM (dischtime - admittime)) / 3600 / 24 AS hosp_los,
      DATE(dod) - DATE(dischtime) AS days_to_death,
      CASE WHEN DATE(dod) - DATE(dischtime) = 0 THEN 1 ELSE 0 END AS hospital_mortality
FROM tmp_pat_adm;