-- fct_despesas.sql
-- Camada Silver: Fato de despesas limpa e tipada
WITH stg AS (
    SELECT * FROM {{ ref('stg_despesas') }}
);

WITH clean_stg AS(
SELECT 
    {{ dbt_utils.generate_surrogate_key(['id', 'deputy_id', 'expense_date', 'document_number', 'gross_amount']) }} AS expense_key,
    id,
    deputy_id,
    year,
    month,
    expense_type,
    expense_date,
    document_number,
    gross_amount,
    supplier_name,
    supplier_tax_id,
    document_url,
    processed_at,
    modified_at
FROM stg
WHERE gross_amount > 0
)

SELECT *, ROW_NUMBER() OVER(PARTITION BY expense_key ORDER BY processed_at DESC) as rn
FROM clean_stg
WHERE rn = 1