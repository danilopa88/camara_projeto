{{ config(
  materialized='view',
  schema='gold'
) }}

-- vw_looker_analytics.sql
-- Essa view une despesas e deputados para consumo direto no Looker Studio

WITH despesas AS (
    SELECT * FROM {{ ref('fct_despesas') }}
),
deputados AS (
    SELECT * FROM {{ ref('dim_deputados') }}
)

SELECT
    d.expense_key,
    d.year,
    d.month,
    d.expense_date,
    d.expense_type,
    d.gross_amount,
    d.supplier_name,
    p.full_name AS deputy_name,
    p.party_initials,
    p.state_initials,
    p.photo_url AS deputy_photo_url,
    -- Reference month for easier filtering in Looker
    DATE(d.year, d.month, 1) AS reference_month 
FROM despesas d
LEFT JOIN deputados p ON d.deputy_id = p.id
