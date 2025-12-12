SELECT
      pat.subject_id,
      adm.hadm_id,
      DENSE_RANK() OVER hadm_window AS hosp_stay_num,
      CASE
          WHEN FIRST_VALUE(adm.hadm_id) OVER hadm_window = adm.hadm_id THEN 1
          ELSE 0
      END AS pat_count,
      pat.anchor_age + (EXTRACT(YEAR FROM adm.admittime) - pat.anchor_year) AS age,
      pat.gender,
      adm.insurance,
      EXTRACT(EPOCH FROM (adm.dischtime - adm.admittime)) / 3600 / 24 AS hosp_los,
      pat.dod,
      DATE(pat.dod) - DATE(adm.dischtime) AS days_to_death,
      CASE WHEN DATE(pat.dod) - DATE(adm.dischtime) = 0 THEN 1 ELSE 0 END AS hospital_mortality
FROM mimiciv_hosp.patients pat
JOIN mimiciv_hosp.admissions adm
    ON pat.subject_id = adm.subject_id
WINDOW hadm_window AS (
    PARTITION BY pat.subject_id
    ORDER BY adm.admittime
);
