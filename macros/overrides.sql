{% macro proplum_get_load_info_table_name() %}
    {%- set schema_name = var('metadata_schema', target.schema) -%}

    {{ return('"' ~ target.dbname ~ '"."' ~ schema_name ~ '"."dbt_load_info"') }}
{% endmacro %}


{# Override proplum_filter_delta to work on first run (init) as well #}
{% macro greenplum__proplum_filter_delta(source_column='', log_dates=false) %}
    {% set object_name = this.name %}
    {% set existing_relation = load_cached_relation(this) %}

    {# Убираем проверку existing_relation - теперь работает и при init #}
    {% if execute and not flags.WHICH in ['generate','serve'] and not should_full_refresh() %}
        {% if log_dates %}
            {% set safety_period = config.get('safety_period', default='0 days') %}
            {% set load_interval = config.get('load_interval', default='') %}
            {% set dates = proplum_get_extraction_dates(model_target=object_name, safety_period=safety_period, load_interval=load_interval, delta_field=source_column, load_method='filter_delta', flag_commit=true, log_data=true) %}
            AND {{ source_column }} BETWEEN '{{ dates.extraction_from }}'::timestamp AND '{{ dates.extraction_to }}'::timestamp
        {% else %}
            {# Get extraction range from load_info table #}
            {% set load_info_table = proplum_get_load_info_table_name() %}
            {% set extraction_range_sql %}
                SELECT extraction_from, extraction_to, delta_field
                FROM {{ load_info_table }}
                WHERE invocation_id = '{{ invocation_id }}'
                AND object_name = '{{ object_name }}'
                AND status = 1
                LIMIT 1
            {% endset %}

            {% set extraction_range = run_query(extraction_range_sql) %}

            {% if extraction_range and extraction_range.rows %}
                {% set extraction_from = extraction_range.rows[0][0] %}
                {% set extraction_to = extraction_range.rows[0][1] %}
                {% if source_column %}
                    {% set delta_column = source_column %}
                {% else %}
                    {% set delta_column = extraction_range.rows[0][2] %}
                {% endif %}
                AND {{ delta_column }} BETWEEN '{{ extraction_from }}'::timestamp AND '{{ extraction_to }}'::timestamp
            {% elif not existing_relation %}
                {# При первом запуске (init) - вызываем get_extraction_dates для логирования и получения дат #}
                {% set delta_field = config.get('delta_field', source_column) %}
                {% set safety_period = config.get('safety_period', default='0 days') %}
                {% set load_interval = config.get('load_interval', default='') %}
                {% set dates = proplum_get_extraction_dates(model_target=object_name, safety_period=safety_period, load_interval=load_interval, delta_field=delta_field, load_method='filter_delta', flag_commit=true, log_data=true) %}
                AND {{ delta_field }} BETWEEN '{{ dates.extraction_from }}'::timestamp AND '{{ dates.extraction_to }}'::timestamp
            {% endif %}
        {% endif %}
    {% endif %}
{% endmacro %}
