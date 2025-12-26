/* Step 1: Identify Cardiac Surgery Patients 
We use DRG codes for high specificity. 
(Codes 291-293 are Heart Failure, we want Surgery 215-267 range roughly in MS-DRG)
Alternatively, use ICD-10-PCS codes for CABG/Valve.
*/

WITH cardiac_surgery_admissions AS (
    SELECT 
        pat.subject_id,
        adm.hadm_id,
        adm.admittime,
        adm.dischtime,
        adm.deathtime,
        adm.hospital_expire_flag AS label, -- 1 = Died, 0 = Survived
        
        -- Calculate the 'Endpoint' time: Death time if died, else Discharge time
        CASE 
            WHEN adm.hospital_expire_flag = 1 THEN adm.deathtime
            ELSE adm.dischtime
        END AS end_time,

        -- Calculate Age
        age.age AS age,
        pat.gender
    FROM mimic.mimiciv_hosp.admissions adm
    JOIN mimic.mimiciv_hosp.patients pat ON adm.subject_id = pat.subject_id
    JOIN mimic.mimiciv_hosp.drgcodes drg ON adm.hadm_id = drg.hadm_id
    JOIN mimic.mimiciv_derived.age age ON adm.hadm_id = age.hadm_id
    WHERE 
        -- Filter for Adult patients
        age.age >= 18
        -- Filter for Cardiac Surgery (Example DRG codes/descriptions)
        AND (
            LOWER(drg.drg_type) = 'hcfa' 
            AND (
                drg.drg_code IN ('104', '105', '106', '107', '108', '109') -- Valid HCFA codes for Cardiac Valve/CABG
                OR LOWER(drg.description) LIKE '%coronary bypass%'
                OR LOWER(drg.description) LIKE '%cardiac valve%'
            )
        )
)
SELECT * FROM cardiac_surgery_admissions;