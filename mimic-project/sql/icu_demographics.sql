SELECT
      pat.subject_id,
      adm.hadm_id,
      icu.stay_id,
      ROW_NUMBER() OVER (PARTITION BY pat.subject_id ORDER BY icu.intime) AS icu_stay_num,
      DENSE_RANK() OVER (PARTITION BY pat.subject_id ORDER BY adm.admittime) AS hosp_stay_num,
      CASE
          WHEN FIRST_VALUE(icu.stay_id) OVER icustay_window = icu.stay_id THEN 1
          ELSE 0
      END AS pat_count,
      pat.anchor_age + (EXTRACT(YEAR FROM icu.intime) - pat.anchor_year) AS age,
      pat.gender,
      icu.first_careunit,
      icu.los AS icu_los,
      EXTRACT(EPOCH FROM (adm.dischtime - adm.admittime)) / 3600 / 24 AS hosp_los,
      pat.dod,
      DATE(pat.dod) - DATE(adm.dischtime) AS days_to_death,
      CASE WHEN DATE(pat.dod) - DATE(adm.dischtime) = 0 THEN 1 ELSE 0 END AS hospital_mortality,
      CASE WHEN DATE(pat.dod) - DATE(icu.outtime) = 0 THEN 1 ELSE 0 END AS icu_mortality
FROM mimiciv_hosp.patients pat
INNER JOIN mimiciv_hosp.admissions adm
    ON pat.subject_id = adm.subject_id
INNER JOIN mimiciv_icu.icustays icu
    ON adm.hadm_id = icu.hadm_id
WINDOW hadm_window AS (PARTITION BY pat.subject_id ORDER BY adm.admittime),
       icustay_window AS (PARTITION BY pat.subject_id ORDER BY icu.intime);