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

WITH source_data AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY idDeputado, numDocumento, dataDocumento, valorDocumento, tipoDespesa 
            ORDER BY numDocumento -- Dummy order for identical rows
        ) as row_num
    FROM {{ source('chamber_api', 'raw_despesas') }}
)

SELECT 
    *,
    {{ dbt_utils.generate_surrogate_key(['idDeputado', 'numDocumento', 'dataDocumento', 'valorDocumento', 'tipoDespesa']) }} AS id
FROM source_data
WHERE row_num = 1

{% endsnapshot %}
