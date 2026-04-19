-- stg_despesas.sql
-- Extrai campos do snapshot de despesas (CDC)
WITH source AS (
    SELECT * FROM {{ ref('sn_despesas') }}
    WHERE dbt_valid_to IS NULL
)

SELECT
    SAFE_CAST(idDeputado AS INT64) AS deputado_id,
    ano,
    mes,
    tipoDespesa AS tipo_despesa,
    dataDocumento AS data_despesa,
    valorDocumento AS valor_bruto,
    valorLiquido AS valor_liquido,
    numDocumento AS numero_documento,
    cnpjCpfFornecedor AS cnpj_cpf_fornecedor,
    urlDocumento AS url_documento,
    nomeFornecedor AS fornecedor_nome,
    CURRENT_TIMESTAMP() AS data_processamento
FROM source
