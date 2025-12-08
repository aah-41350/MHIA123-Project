DROP TABLE IF EXISTS tmp_pat_adm_icu;

CREATE TEMP TABLE tmp_pat_adm_icu AS
SELECT
      t.subject_id,
      t.hadm_id,
      icu.stay_id,
      ROW_NUMBER() OVER (PARTITION BY t.subject_id ORDER BY icu.intime) AS icu_stay_num,
      CASE
          WHEN FIRST_VALUE(icu.stay_id) OVER (PARTITION BY t.subject_id ORDER BY icu.intime)
               = icu.stay_id THEN 1 ELSE 0
      END AS pat_count,
      t.hosp_stay_num,
      t.anchor_age + (EXTRACT(YEAR FROM icu.intime) - t.anchor_year) AS age,
      t.gender,
      t.insurance,
      icu.first_careunit,
      icu.los AS icu_los,
      t.hosp_los,
      t.dod,
      t.days_to_death,
      t.hospital_mortality,
      CASE WHEN DATE(t.dod) - DATE(icu.outtime) = 0 THEN 1 ELSE 0 END AS icu_mortality
FROM tmp_pat_adm_windows t
JOIN mimiciv_icu.icustays icu
    ON t.hadm_id = icu.hadm_id;