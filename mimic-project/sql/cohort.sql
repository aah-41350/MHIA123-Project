SELECT
    p.subject_id,
    icu.hadm_id,
    icu.stay_id,
    p.anchor_age AS age,
    CASE WHEN adm.dischtime < p.dod THEN 1 ELSE 0 END AS mortality
FROM mimiciv_derived.icustays icu
JOIN mimiciv_hosp.patients p ON icu.subject_id = p.subject_id
JOIN mimiciv_hosp.admissions adm ON icu.hadm_id = adm.hadm_id
WHERE icu.first_icu_stay = 1
  AND p.anchor_age >= 18;
