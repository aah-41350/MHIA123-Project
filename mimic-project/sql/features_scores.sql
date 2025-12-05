SELECT
    stay_id,
    MAX(sofa) AS sofa_24h,
    MAX(oasis) AS oasis_24h
FROM mimiciv_derived.sofa
GROUP BY stay_id;
