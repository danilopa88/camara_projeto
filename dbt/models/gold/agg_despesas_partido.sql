-- agg_despesas_partido.sql
-- Agregação de gastos totais por partido
WITH despesas AS (
    SELECT * FROM {{ ref('fct_despesas') }}
),
deputados AS (
    SELECT * FROM {{ ref('dim_deputados') }}
)

SELECT
    dep.partido_sigla,
    dep.estado_sigla,
    des.mes,
    des.ano,
    SUM(des.valor_bruto) AS total_gasto,
    COUNT(DISTINCT dep.id) AS total_deputados,
    SUM(des.valor_bruto) / COUNT(DISTINCT dep.id) AS gasto_medio_por_deputado
FROM despesas des
JOIN deputados dep ON des.deputado_id = dep.id
GROUP BY 1, 2, 3, 4
ORDER BY total_gasto DESC
