-- stg_deputados.sql
-- Extrai campos do snapshot de deputados (CDC)
WITH source AS (
    SELECT * FROM {{ ref('sn_deputados') }}
    WHERE dbt_valid_to IS NULL
)

SELECT
    SAFE_CAST(id AS INT64) AS deputado_id,
    nome AS nome_civil,
    siglaPartido AS partido_sigla,
    siglaUf AS estado_sigla,
    uri AS api_url,
    urlFoto AS foto_url,
    CURRENT_TIMESTAMP() AS data_processamento
FROM source
