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
    d.despesa_key,
    d.ano,
    d.mes,
    d.data_despesa,
    d.tipo_despesa,
    d.valor_bruto,
    d.fornecedor_nome,
    p.nome_civil AS deputado_nome,
    p.partido_sigla,
    p.estado_sigla,
    p.foto_url AS deputado_foto_url,
    -- Campo calculado para facilitar filtros de tempo no Looker
    DATE(d.ano, d.mes, 1) AS mes_referencia 
FROM despesas d
LEFT JOIN deputados p ON d.deputado_id = p.id
