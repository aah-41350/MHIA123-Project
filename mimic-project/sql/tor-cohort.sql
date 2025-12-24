WITH cardiac_surgery AS (
    -- Identify CABG and Valve surgeries using ICD-9 and ICD-10 procedure codes
    SELECT 
        p.subject_id, 
        p.hadm_id, 
        p.icd_code,
        p.icd_version
    FROM remote_mimic.mimiciv_hosp.procedures_icd p
    WHERE 
        -- CABG Codes (ICD-9: 36.1*, ICD-10: 021*)
        (p.icd_version = 9 AND p.icd_code LIKE '361%') OR
        (p.icd_version = 10 AND p.icd_code LIKE '021%') OR
        -- Valve Codes (ICD-9: 35.*, ICD-10: 02R*)
        (p.icd_version = 9 AND p.icd_code LIKE '35%') OR
        (p.icd_version = 10 AND p.icd_code LIKE '02R%')
),
cohort AS (
    SELECT DISTINCT
        cs.subject_id,
        cs.hadm_id,
        adm.hospital_expire_flag AS label, -- Target: In-hospital Mortality
        pat.anchor_age,
        pat.gender,
        icu.stay_id,
        icu.intime AS icu_intime
    FROM cardiac_surgery cs
    JOIN remote_mimic.mimiciv_hosp.admissions adm ON cs.hadm_id = adm.hadm_id
    JOIN remote_mimic.mimiciv_hosp.patients pat ON cs.subject_id = pat.subject_id
    -- Join ICU stays to determine the "Pre-op" boundary (Time before ICU admission)
    JOIN remote_mimic.mimiciv_icu.icustays icu ON cs.hadm_id = icu.hadm_id
    WHERE pat.anchor_age >= 18
),
-- Extract Preoperative Labs (Last value before ICU admission)
comorbidities AS (
    -- Charlson Comorbidity Index from derived schema
    SELECT
        c.hadm_id, 
        cci.charlson_comorbidity_index 
    FROM cohort c
    JOIN remote_mimic.mimiciv_derived.charlson cci ON c.hadm_id = cci.hadm_id
),
preop_vitals AS (
    -- Get mean vitals in the 24h window before ICU admission
    SELECT 
        c.stay_id,
        AVG(v.heart_rate) as heart_rate_mean,
        AVG(v.sbp) as sbp_mean,
        AVG(v.dbp) as dbp_mean,
        AVG(v.mbp) as mbp_mean,
        AVG(v.resp_rate) as resp_rate_mean,
        AVG(v.spo2) as spo2_mean
    FROM cohort c
    JOIN remote_mimic.mimiciv_derived.vitalsign v ON c.stay_id = v.stay_id
    WHERE v.charttime BETWEEN (c.icu_intime - INTERVAL '1 week') AND c.icu_intime
    GROUP BY c.stay_id
),
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
        bg.po2,
        bg.fio2,
        (bg.po2 / (bg.fio2/100)) as pf_ratio,
        enz.ck_mb as ck_mb,
        -- Binary flags for EuroSCORE risk factors (derived from ICD)
        MAX(CASE WHEN di.icd_code LIKE 'I252' THEN 1 ELSE 0 END) as prev_mi,
        MAX(CASE WHEN di.icd_code LIKE 'I63%' THEN 1 ELSE 0 END) as stroke_history
    FROM cohort c
    LEFT JOIN remote_mimic.mimiciv_derived.bg bg ON c.hadm_id = bg.hadm_id
    LEFT JOIN remote_mimic.mimiciv_derived.cardiac_marker enz ON c.hadm_id = enz.hadm_id
    LEFT JOIN remote_mimic.mimiciv_hosp.diagnoses_icd di ON c.hadm_id = di.hadm_id
    GROUP BY c.hadm_id, bg.po2, bg.fio2, enz.ck_mb
)

SELECT
    c.*,
    com.charlson_comorbidity_index,
    v.heart_rate_mean, v.sbp_mean, v.dbp_mean, v.mbp_mean, v.resp_rate_mean, v.spo2_mean,
    lab.hematocrit, lab.hemoglobin, lab.wbc, lab.platelet, lab.creatinine, lab.bun,
    e.pf_ratio, e.ck_mb, e.prev_mi, e.stroke_history
FROM cohort c
LEFT JOIN comorbidities com ON c.hadm_id = com.hadm_id
LEFT JOIN preop_vitals v ON c.stay_id = v.stay_id
LEFT JOIN preop_labs lab ON c.hadm_id = lab.hadm_id
LEFT JOIN euroscore_components e ON c.hadm_id = e.hadm_id;