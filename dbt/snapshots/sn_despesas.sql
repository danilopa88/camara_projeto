{% snapshot sn_despesas %}

{{
    config(
      target_database=env_var('GCP_PROJECT_ID'),
      target_schema=env_var('ENVIRONMENT', 'dev') ~ '_snapshots',
      unique_key='id',
      strategy='check',
      check_cols=['valorDocumento', 'valorLiquido', 'dataDocumento', 'tipoDespesa'],
    )
}}

SELECT * FROM {{ source('chamber_api', 'raw_despesas') }}

{% endsnapshot %}
