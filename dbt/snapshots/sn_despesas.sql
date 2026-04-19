{% snapshot sn_despesas %}

{{
    config(
      target_database=env_var('GCP_PROJECT_ID'),
      target_schema=env_var('ENVIRONMENT', 'dev') ~ '_snapshots',
      unique_key='id',
      strategy='check',
      check_cols=['valorDocumento', 'valorLiquido', 'tipoDespesa'],
    )
}}

{# 
   Configuração do Snapshot de Despesas:
   - unique_key='id': Chave gerada via hash para garantir unicidade técnica.
   - strategy='check': Detecta mudanças nos valores e tipos de despesa.
#}

WITH source_data AS (
    /* 
       Tratamento de Duplicados Identicos:
       - Algumas linhas da API podem vir duplicadas. Usamos ROW_NUMBER para 
         garantir que apenas uma ocorrência única entre no snapshot, 
         evitando falhas de unique_key.
    */
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY 
                idDeputado, 
                numDocumento, 
                dataDocumento, 
                CAST(valorDocumento AS STRING), 
                tipoDespesa 
            ORDER BY numDocumento 
        ) as row_num
    FROM {{ source('chamber_api', 'raw_despesas') }}
)

SELECT 
    *,
    /* 
       Geração de Surrogate Key (ID único):
       - Como a API não fornece um ID único por despesa, criamos um hash 
         estável baseado nos campos de negócio.
    */
    {{ dbt_utils.generate_surrogate_key(['idDeputado', 'numDocumento', 'dataDocumento', 'valorDocumento', 'tipoDespesa']) }} AS id
FROM source_data
-- Filtra apenas a primeira linha de grupos duplicados
WHERE row_num = 1

{% endsnapshot %}
