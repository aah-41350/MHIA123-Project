SELECT
    stay_id,
    AVG(heart_rate) AS hr_mean,
    AVG(mean_bp) AS map_mean,
    AVG(resp_rate) AS rr_mean,
    AVG(temperature) AS temp_mean
FROM mimiciv_derived.vitalsign
GROUP BY stay_id;
