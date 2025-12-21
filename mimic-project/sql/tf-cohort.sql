WITH sofa_agg AS (
    SELECT 
        stay_id,
        MAX(sofa_24hours) AS sofa_max_24h -- Max score represents peak severity
    FROM remote_mimic.mimiciv_derived.sofa
    WHERE hr <= 24
    GROUP BY stay_id
)

SELECT 
    ie.subject_id, ie.hadm_id, ie.stay_id,
    ie.hospital_expire_flag AS label,
    ie.admission_age AS age,
    CASE WHEN ie.gender = 'M' THEN 1 ELSE 0 END AS is_male,
        
    -- Aggregated Vitals
    v.heart_rate_mean, v.mbp_mean, v.resp_rate_mean, v.temperature_mean,
        
    -- Critical Lab Markers
    fdb.lactate_max, l.bun_max, l.creatinine_max, l.aniongap_max,
        
    -- Scoring Systems
    c.charlson_comorbidity_index AS charlson_index,
    lo.lods,       -- LODS Score
    o.oasis,       -- OASIS Score
    sa.sapsii,     -- SAPS II Score
    s.sofa_max_24h -- Aggregated SOFA Score
        
FROM remote_mimic.mimiciv_derived.icustay_detail ie
LEFT JOIN remote_mimic.mimiciv_derived.first_day_vitalsign v ON ie.stay_id = v.stay_id
LEFT JOIN remote_mimic.mimiciv_derived.first_day_bg_art fdb ON ie.stay_id = fdb.stay_id
LEFT JOIN remote_mimic.mimiciv_derived.first_day_lab l ON ie.stay_id = l.stay_id
LEFT JOIN remote_mimic.mimiciv_derived.charlson c ON ie.hadm_id = c.hadm_id
LEFT JOIN remote_mimic.mimiciv_derived.lods lo ON ie.stay_id = lo.stay_id
LEFT JOIN remote_mimic.mimiciv_derived.oasis o ON ie.stay_id = o.stay_id
LEFT JOIN remote_mimic.mimiciv_derived.sapsii sa ON ie.stay_id = sa.stay_id
LEFT JOIN sofa_agg s ON ie.stay_id = s.stay_id
    
WHERE ie.admission_age >= 18 
AND ie.first_icu_stay = TRUE