-- dim_deputados.sql
-- Camada Silver: Dados limpos de deputados
WITH stg AS (
    SELECT * FROM {{ ref('stg_deputados') }}
)

SELECT
    id,
    nome_civil,
    partido_sigla,
    estado_sigla,
    api_url,
    foto_url,
    CURRENT_TIMESTAMP() AS data_processamento
FROM stg
QUALIFY ROW_NUMBER() OVER (PARTITION BY id ORDER BY data_processamento DESC) = 1
