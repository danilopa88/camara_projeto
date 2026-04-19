-- stg_despesas.sql
-- Extrai campos do snapshot de despesas com lógica de auditoria (CDC)
WITH snapshot_data AS (
    SELECT 
        *,
        MIN(dbt_valid_from) OVER (PARTITION BY id) as first_seen,
        dbt_valid_from as current_version_start
    FROM {{ ref('sn_despesas') }}
),

source AS (
    SELECT * FROM snapshot_data
    WHERE dbt_valid_to IS NULL
)

SELECT
    id,
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
    CAST(first_seen AS TIMESTAMP) AS data_processamento,
    CAST(
        CASE 
            WHEN current_version_start > first_seen THEN current_version_start 
            ELSE NULL 
        END AS TIMESTAMP
    ) AS data_modificacao
FROM source
