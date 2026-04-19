-- agg_despesas_partido.sql
-- Agregação de gastos totais por partido
WITH despesas AS (
    SELECT * FROM {{ ref('fct_despesas') }}
),
deputados AS (
    SELECT * FROM {{ ref('dim_deputados') }}
)

SELECT
    dep.party_initials,
    dep.state_initials,
    des.month,
    des.year,
    SUM(des.gross_amount) AS total_amount,
    COUNT(DISTINCT dep.id) AS total_deputies,
    SUM(des.gross_amount) / COUNT(DISTINCT dep.id) AS avg_amount_per_deputy
FROM despesas des
JOIN deputados dep ON des.deputy_id = dep.id
GROUP BY 1, 2, 3, 4
ORDER BY total_amount DESC
