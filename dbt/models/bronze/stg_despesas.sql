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
    SAFE_CAST(idDeputado AS INT64) AS deputy_id,
    ano AS year,
    mes AS month,
    tipoDespesa AS expense_type,
    dataDocumento AS expense_date,
    valorDocumento AS gross_amount,
    valorLiquido AS net_amount,
    numDocumento AS document_number,
    cnpjCpfFornecedor AS supplier_tax_id,
    urlDocumento AS document_url,
    nomeFornecedor AS supplier_name,
    CAST(first_seen AS TIMESTAMP) AS processed_at,
    CAST(
        CASE 
            WHEN current_version_start > first_seen THEN current_version_start 
            ELSE NULL 
        END AS TIMESTAMP
    ) AS modified_at
FROM source
