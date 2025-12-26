WITH cohort AS (
    -- Identify Adult Cardiac Surgery patients
    SELECT DISTINCT
        adm.subject_id,
        adm.hadm_id,
        icu.stay_id,
        icu.intime AS icu_intime,
        pat.anchor_age,
        pat.gender,
        adm.hospital_expire_flag AS label,
    FROM remote_mimic.mimiciv_hosp.admissions adm
    JOIN remote_mimic.mimiciv_hosp.patients pat ON adm.subject_id = pat.subject_id
    JOIN remote_mimic.mimiciv_icu.icustays icu ON adm.hadm_id = icu.hadm_id
    JOIN remote_mimic.mimiciv_hosp.procedures_icd proc ON adm.hadm_id = proc.hadm_id
    WHERE pat.anchor_age >= 18
      AND (
        (proc.icd_version = 9 AND proc.icd_code LIKE '361%') OR -- CABG
        (proc.icd_version = 10 AND proc.icd_code LIKE '021%') OR
        (proc.icd_version = 9 AND proc.icd_code LIKE '35%') OR -- Valve
        (proc.icd_version = 10 AND proc.icd_code LIKE '02R%')
      )
),
comorbidities AS (
    -- Charlson Comorbidity Index from derived schema
    SELECT 
        hadm_id,
        charlson_comorbidity_index,
        myocardial_infarct,
        congestive_heart_failure,
        peripheral_vascular_disease,
        cerebrovascular_disease,
        dementia,
        chronic_pulmonary_disease,
        rheumatic_disease,
        peptic_ulcer_disease,
        mild_liver_disease,
        diabetes_without_cc,
        diabetes_with_cc,
        paraplegia,
        renal_disease,
        malignant_cancer,
        severe_liver_disease,
        metastatic_solid_tumor
    FROM remote_mimic.mimiciv_derived.charlson
),
--preop_vitals AS (
    -- Get mean vitals in the 24h window before ICU admission
--    SELECT 
--        c.stay_id,
--        AVG(v.heart_rate) as heart_rate_mean,
--        AVG(v.sbp) as sbp_mean,
--        AVG(v.dbp) as dbp_mean,
--        AVG(v.mbp) as mbp_mean,
--        AVG(v.resp_rate) as resp_rate_mean,
--        AVG(v.spo2) as spo2_mean
--    FROM cohort c
--    JOIN remote_mimic.mimiciv_derived.vitalsign v ON c.stay_id = v.stay_id
--    WHERE v.charttime BETWEEN (c.icu_intime - INTERVAL '2 month') AND c.icu_intime
--    GROUP BY c.stay_id
--),
-- Extract Preoperative Labs (Last value before ICU admission)
preop_labs AS (
    SELECT 
        c.hadm_id,
        -- Aggregating to get the last value before ICU entry
        MAX(cbc.hematocrit) AS hematocrit,
        MAX(cbc.hemoglobin) AS hemoglobin,
        MAX(cbc.wbc) AS wbc,
        MAX(cbc.platelet) AS platelet,
        MAX(ch.creatinine) AS creatinine,
        MAX(ch.bun) AS bun
    FROM cohort c
    JOIN remote_mimic.mimiciv_derived.complete_blood_count cbc ON c.hadm_id = cbc.hadm_id
    JOIN remote_mimic.mimiciv_derived.chemistry ch ON c.hadm_id = ch.hadm_id
    WHERE cbc.charttime < c.icu_intime AND ch.charttime < c.icu_intime
    GROUP BY c.hadm_id
),
euroscore_components AS (
    -- EuroSCORE II requires specific labs and comorbidities
    -- We pull pre-calculated derived tables for these inputs
    SELECT 
        c.hadm_id,
        enz.ck_mb as ck_mb,
        MAX(enz.troponin_t) as trop_t,
        MAX(enz.ntprobnp) as probnp,
        -- Binary flags for EuroSCORE risk factors (derived from ICD)
        MAX(CASE WHEN di.icd_code LIKE 'I252' THEN 1 ELSE 0 END) as prev_mi,
        MAX(CASE WHEN di.icd_code LIKE 'I63%' THEN 1 ELSE 0 END) as stroke_history
    FROM cohort c
    LEFT JOIN remote_mimic.mimiciv_derived.cardiac_marker enz ON c.hadm_id = enz.hadm_id
    LEFT JOIN remote_mimic.mimiciv_hosp.diagnoses_icd di ON c.hadm_id = di.hadm_id
    GROUP BY c.hadm_id, enz.ck_mb
)

-- Final Feature Set
SELECT 
    c.subject_id, c.anchor_age, c.gender, c.label,
    com.charlson_comorbidity_index, 
    com.myocardial_infarct, com.congestive_heart_failure,
    com.peripheral_vascular_disease, com.cerebrovascular_disease, com.dementia,
    com.chronic_pulmonary_disease, com.rheumatic_disease, com.peptic_ulcer_disease,
    com.mild_liver_disease, com.diabetes_without_cc, com.diabetes_with_cc,
    com.paraplegia, com.renal_disease, com.malignant_cancer,
    com.severe_liver_disease, com.metastatic_solid_tumor,
    --v.heart_rate_mean, v.sbp_mean, v.dbp_mean, v.mbp_mean, v.resp_rate_mean, v.spo2_mean,
    l.hematocrit, l.hemoglobin, l.wbc, l.platelet, l.creatinine, l.bun,
    e.ck_mb, e.trop_t, e.probnp, e.prev_mi, e.stroke_history
FROM cohort c
LEFT JOIN comorbidities com ON c.hadm_id = com.hadm_id
--LEFT JOIN preop_vitals v ON c.stay_id = v.stay_id
LEFT JOIN preop_labs l ON c.hadm_id = l.hadm_id
LEFT JOIN euroscore_components e ON c.hadm_id = e.hadm_id