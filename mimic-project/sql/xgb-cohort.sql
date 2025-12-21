WITH sofa_agg AS (
    SELECT stay_id, MAX(sofa_24hours) AS sofa_max_24h
    FROM remote_mimic.mimiciv_derived.sofa
    GROUP BY stay_id
),
vitals_engineered AS (
    SELECT 
        stay_id,
        heart_rate_mean,
        mbp_mean,
        -- [NEW FEATURE] Shock Index: Heart Rate / Mean Blood Pressure
        -- High shock index (> 0.7-0.9) is a strong predictor of occult shock
        (heart_rate_mean / NULLIF(mbp_mean, 0)) AS shock_index,
        resp_rate_mean,
        temperature_mean
    FROM remote_mimic.mimiciv_derived.first_day_vitalsign
)

SELECT 
    ie.subject_id, ie.hadm_id, ie.stay_id,
    ie.hospital_expire_flag AS label,
    ie.admission_age AS age,
    CASE WHEN ie.gender = 'M' THEN 1 ELSE 0 END AS is_male,
    
    ve.heart_rate_mean, ve.mbp_mean, ve.shock_index, ve.resp_rate_mean,
    
    -- Labs: Using min/max to capture the "range" of instability
    l.glucose_max, l.potassium_max, l.sodium_min,
    fdb.lactate_max, l.bun_max, l.creatinine_max, l.aniongap_max,
    
    c.charlson_comorbidity_index AS charlson_index,
    aps.apsiii, o.oasis, sa.sapsii, s.sofa_max_24h
        
FROM remote_mimic.mimiciv_derived.icustay_detail ie
LEFT JOIN vitals_engineered ve ON ie.stay_id = ve.stay_id
LEFT JOIN remote_mimic.mimiciv_derived.first_day_bg_art fdb ON ie.stay_id = fdb.stay_id
LEFT JOIN remote_mimic.mimiciv_derived.first_day_lab l ON ie.stay_id = l.stay_id
LEFT JOIN remote_mimic.mimiciv_derived.charlson c ON ie.hadm_id = c.hadm_id
LEFT JOIN remote_mimic.mimiciv_derived.apsiii aps ON ie.stay_id = aps.stay_id
LEFT JOIN remote_mimic.mimiciv_derived.oasis o ON ie.stay_id = o.stay_id
LEFT JOIN remote_mimic.mimiciv_derived.sapsii sa ON ie.stay_id = sa.stay_id
LEFT JOIN sofa_agg s ON ie.stay_id = s.stay_id
WHERE ie.admission_age >= 18 AND ie.first_icu_stay = TRUE