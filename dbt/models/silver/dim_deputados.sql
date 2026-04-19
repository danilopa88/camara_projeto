-- dim_deputados.sql
-- Camada Silver: Dados limpos de deputados
WITH stg AS (
    SELECT * FROM {{ ref('stg_deputados') }}
)

SELECT
    id,
    full_name,
    party_initials,
    state_initials,
    api_url,
    photo_url,
    processed_at,
    modified_at
FROM stg
QUALIFY ROW_NUMBER() OVER (PARTITION BY id ORDER BY processed_at DESC) = 1
