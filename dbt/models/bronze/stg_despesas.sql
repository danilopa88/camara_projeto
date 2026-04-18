-- stg_despesas.sql
WITH source AS (
    SELECT * FROM {{ source('chamber_api', 'raw_despesas') }}
)

SELECT
    SAFE_CAST(idDeputado AS INT64) AS deputado_id,
    ano,
    mes,
    tipoDespesa AS tipo_despesa,
    dataDocumento AS data_despesa,
    valorDocumento AS valor_bruto,
    valorLiquido AS valor_liquido,
    nomeFornecedor AS fornecedor_nome
FROM source
