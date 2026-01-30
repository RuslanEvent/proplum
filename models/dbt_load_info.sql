{{ config(
    materialized='incremental',
    incremental_strategy='append',
    appendonly = true,
    orientation = 'column',
    compresstype = 'zstd',
    compresslevel = '1',
    schema = 'schema_name'
) }}

    SELECT
        CAST(NULL AS text) as invocation_id,
        CAST(NULL AS text) as object_name,
        CAST(NULL AS int8) as status,
        CAST(NULL as timestamp) as extraction_from,
        CAST(NULL as timestamp) as extraction_to,
        CAST(NULL as timestamp) as updated_at,
        CAST(NULL as timestamp) as created_at,
        CAST(NULL as timestamp) as extraction_from_original,
        CAST(NULL as timestamp) as extraction_to_original,
        CAST(NULL as text) as model_sql,
        CAST(NULL as text) as load_method,
        CAST(NULL as text) as extraction_type,
        CAST(NULL as text) as load_type,
        CAST(NULL as int8) as row_cnt,
        CAST(NULL as text) as delta_field
    WHERE 1=0