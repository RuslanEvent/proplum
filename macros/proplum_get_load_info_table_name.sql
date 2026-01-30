{% macro proplum_get_load_info_table_name() %}
    {%- set schema_name = var('metadata_schema', target.schema) -%}

    {{ return('"' ~ target.dbname ~ '"."' ~ schema_name ~ '"."dbt_load_info"') }}
{% endmacro %}
