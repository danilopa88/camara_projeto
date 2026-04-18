-- agg_despesas_partido.sql
-- Agregação de gastos totais por partido
WITH despesas AS (
    SELECT * FROM {{ ref('stg_despesas') }}
),
deputados AS (
    SELECT * FROM {{ ref('stg_deputados') }}
)

SELECT
    dep.partido_sigla,
    dep.estado_sigla,
    SUM(des.valor_liquido) AS total_gasto,
    COUNT(DISTINCT dep.deputado_id) AS total_deputados,
    SUM(des.valor_liquido) / COUNT(DISTINCT dep.deputado_id) AS gasto_medio_por_deputado
FROM despesas des
JOIN deputados dep ON des.deputado_id = dep.deputado_id
GROUP BY 1, 2
ORDER BY total_gasto DESC
