-- fct_despesas.sql
-- Camada Silver: Fato de despesas limpa e tipada
WITH stg AS (
    SELECT * FROM {{ ref('stg_despesas') }}
)

SELECT DISTINCT
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
    document_url
FROM stg
WHERE gross_amount > 0
