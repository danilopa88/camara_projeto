-- stg_deputados.sql
-- Extrai campos do snapshot de deputados com lógica de auditoria (CDC)
WITH snapshot_data AS (
    SELECT 
        *,
        MIN(dbt_valid_from) OVER (PARTITION BY id) as first_seen,
        dbt_valid_from as current_version_start
    FROM {{ ref('sn_deputados') }}
),

source AS (
    SELECT * FROM snapshot_data
    WHERE dbt_valid_to IS NULL
)

SELECT
    SAFE_CAST(id AS INT64) AS id,
    nome AS full_name,
    siglaPartido AS party_initials,
    siglaUf AS state_initials,
    uri AS api_url,
    urlFoto AS photo_url,
    CAST(first_seen AS TIMESTAMP) AS processed_at,
    CAST(
        CASE 
            WHEN current_version_start > first_seen THEN current_version_start 
            ELSE NULL 
        END AS TIMESTAMP
    ) AS modified_at
FROM source
