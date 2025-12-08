DROP TABLE IF EXISTS tmp_pat_adm;

CREATE TEMP TABLE tmp_pat_adm AS
SELECT
      pat.subject_id,
      adm.hadm_id,
      pat.anchor_age,
      pat.anchor_year,
      pat.gender,
      adm.insurance,
      adm.admittime,
      adm.dischtime,
      pat.dod
FROM mimiciv_hosp.patients pat
JOIN mimiciv_hosp.admissions adm
    ON pat.subject_id = adm.subject_id;