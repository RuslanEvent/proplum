{{ config(
    materialized='proplum',
    incremental_strategy='delta_upsert',
    schema = 'dbt_ods_ruslan',
    tags=["aboba_processing","ods"],
    distributed_by = '_id',
    merge_keys=['_id'],
    delete_duplicates = true,
    delta_field = 'dwh_processed_dttm'
) }}


select
  CAST(_id as text) as _id,
	CAST(balance as text) as balance,
	CAST(is_active as boolean) as is_active,
	CAST(created_at as timestamp) as created_at,
	CAST(updated_at as timestamp) as updated_at,
	CAST(customer_id as text) as customer_id,
	CAST(bank_account_id as text) as bank_account_id,
	CAST(dwh_job_id as numeric) as dwh_job_id,
	CAST(dwh_processed_dttm as timestamp) as dwh_processed_dttm
  from stg__mdbalp__aboba_processing.v_accounts
where 1=1
{{ proplum_filter_delta() }}
