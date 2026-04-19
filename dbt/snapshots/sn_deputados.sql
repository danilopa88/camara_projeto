{% snapshot sn_deputados %}

{{
    config(
      target_database=env_var('GCP_PROJECT_ID'),
      target_schema=env_var('ENVIRONMENT', 'dev') ~ '_snapshots',
      unique_key='id',
      strategy='check',
      check_cols=['nome', 'siglaPartido', 'siglaUf', 'urlFoto'],
    )
}}

{# 
   Configuração do Snapshot (SCD Type 2):
   - strategy='check': Monitora mudanças nos campos listados em check_cols.
   - unique_key='id': ID único e estável do deputado vindo da API.
#}

-- Seleção direta dos dados brutos de deputados para rastreio de alterações
SELECT * FROM {{ source('chamber_api', 'raw_deputados') }}

{% endsnapshot %}
