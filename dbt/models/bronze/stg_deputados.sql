-- stg_deputados.sql
-- Extrai campos do JSON bruto de deputados
WITH source AS (
    SELECT * FROM {{ source('chamber_api', 'raw_deputados') }}
)

SELECT
    SAFE_CAST(id AS INT64) AS deputado_id,
    nome AS nome_civil,
    siglaPartido AS partido_sigla,
    siglaUf AS estado_sigla,
    uri AS api_url,
    urlFoto AS foto_url
FROM source
