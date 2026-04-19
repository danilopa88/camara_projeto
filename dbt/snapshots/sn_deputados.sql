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

SELECT * FROM {{ source('chamber_api', 'raw_deputados') }}

{% endsnapshot %}
