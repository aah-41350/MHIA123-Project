WITH cohort AS (
    SELECT 
        subject_id, 
        hadm_id, 
        admittime, 
        CASE 
            WHEN adm.hospital_expire_flag = 1 THEN adm.deathtime
            ELSE adm.dischtime
        END AS end_time
    FROM mimic.mimiciv_hosp.admissions adm
    WHERE hadm_id IN {cohort_ids}
),
vitals AS (
    -- Join with derived vitals
    SELECT 
        c.hadm_id,
        v.charttime,
        v.heart_rate,
        v.mbp AS mean_bp,
        v.spo2
    FROM cohort c
    JOIN mimic.mimiciv_derived.vitalsign v ON c.subject_id = v.subject_id
    WHERE v.charttime BETWEEN c.admittime AND c.end_time
),
labs AS (
    -- Join with derived chemistry/blood count
    SELECT 
        c.hadm_id,
        l.charttime,
        l.creatinine,
        l.bun,
        cbc.wbc,
        cbc.platelet,
        bg.lactate
    FROM cohort c
    LEFT JOIN mimic.mimiciv_derived.chemistry l ON c.subject_id = l.subject_id
    LEFT JOIN mimic.mimiciv_derived.complete_blood_count cbc ON c.subject_id = cbc.subject_id
    LEFT JOIN mimic.mimiciv_derived.bg bg ON c.subject_id = bg.subject_id
    WHERE l.charttime BETWEEN c.admittime AND c.end_time
)

SELECT 
    c.hadm_id,
    -- BASELINE AGGREGATES (First 24h)
    AVG(CASE WHEN v.charttime <= c.admittime + INTERVAL 24 HOURS THEN v.heart_rate END) as hr_base,
    AVG(CASE WHEN v.charttime <= c.admittime + INTERVAL 24 HOURS THEN v.mean_bp END) as map_base,
    AVG(CASE WHEN l.charttime <= c.admittime + INTERVAL 24 HOURS THEN l.creatinine END) as creat_base,
    AVG(CASE WHEN l.charttime <= c.admittime + INTERVAL 24 HOURS THEN l.lactate END) as lac_base,

    -- TERMINAL AGGREGATES (Last 24h)
    AVG(CASE WHEN v.charttime >= c.end_time - INTERVAL 24 HOURS THEN v.heart_rate END) as hr_end,
    AVG(CASE WHEN v.charttime >= c.end_time - INTERVAL 24 HOURS THEN v.mean_bp END) as map_end,
    AVG(CASE WHEN l.charttime >= c.end_time - INTERVAL 24 HOURS THEN l.creatinine END) as crea_end,
    AVG(CASE WHEN l.charttime >= c.end_time - INTERVAL 24 HOURS THEN l.lactate END) as lac_end

FROM cohort c
LEFT JOIN vitals v ON c.hadm_id = v.hadm_id
LEFT JOIN labs l ON c.hadm_id = l.hadm_id
GROUP BY c.hadm_id