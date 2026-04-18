
{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}

        {{ default_schema }}

    {%- else -%}

        {# 
           Em BigQuery, queremos que o custom_schema_name (bronze, silver, gold) 
           substitua o sufixo do dataset padrão (dev_silver -> dev_gold).
           Como definimos o ENVIRONMENT na env var, o target.schema já é algo como 'dev_silver'.
           Vamos extrair o prefixo (dev, prod) e concatenar com o custom_schema_name.
        #}
        {%- set environment = target.dataset.split('_')[0] -%}
        {{ environment }}_{{ custom_schema_name | trim }}

    {%- endif -%}

{%- endmacro %}
