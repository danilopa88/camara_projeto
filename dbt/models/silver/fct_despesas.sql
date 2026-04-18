-- fct_despesas.sql
-- Camada Silver: Fato de despesas limpa e tipada
WITH stg AS (
    SELECT * FROM {{ ref('stg_despesas') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['deputado_id', 'data_documento', 'numero_documento', 'valor_bruto']) }} AS despesa_key,
    deputado_id,
    ano,
    mes,
    tipo_despesa,
    data_documento,
    numero_documento,
    valor_bruto,
    nome_fornecedor,
    cnpj_cpf_fornecedor,
    url_documento,
    CURRENT_TIMESTAMP() AS data_processamento
FROM stg
WHERE valor_documento > 0
