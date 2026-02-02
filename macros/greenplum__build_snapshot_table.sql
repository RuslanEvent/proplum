{# Fix for greenplum snapshot: explicit text casting for dbt_is_deleted on initial table creation #}
{% macro greenplum__build_snapshot_table(strategy, sql) %}
    {% set columns = config.get('snapshot_table_column_names') or get_snapshot_table_column_names() %}

    select *,
        {{ strategy.scd_id }} as {{ columns.dbt_scd_id }},
        {{ strategy.updated_at }} as {{ columns.dbt_updated_at }},
        {{ strategy.updated_at }} as {{ columns.dbt_valid_from }},
        {{ get_dbt_valid_to_current(strategy, columns) }}
      {%- if strategy.hard_deletes == 'new_record' -%}
        , false as {{ columns.dbt_is_deleted }}
      {% endif -%}
    from (
        {{ sql }}
    ) sbq

{% endmacro %}
