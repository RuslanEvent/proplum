# Macros Documentation

Документация по кастомным макросам проекта proplum.

---

## generate_schema_name.sql

### Назначение
Переопределяет стандартное поведение dbt для генерации имени схемы.

### Проблема
По умолчанию dbt конкатенирует `target.schema` + `custom_schema_name`, создавая схемы вида `dbt_ruslan_ods`. Это неудобно для работы с существующими схемами в DWH.

### Решение
Макрос использует **только** `custom_schema_name` без добавления префикса `target.schema`:
- Если `custom_schema_name` указан — используется он напрямую
- Если не указан — используется `target.schema` по умолчанию

### Пример
```yaml
# dbt_project.yml или model config
schema: dbt_ods_ruslan  # Таблица создастся именно в dbt_ods_ruslan, а не в dbt_ruslan_dbt_ods_ruslan
```

---

## proplum_get_load_info_table_name.sql

### Назначение
Возвращает полное квалифицированное имя таблицы `dbt_load_info` для логирования загрузок.

### Как работает
Формирует имя таблицы в формате: `"database"."schema"."dbt_load_info"`

Схема берётся из:
1. Переменной `metadata_schema` (если задана)
2. `target.schema` (по умолчанию)

### Использование
```sql
{% set load_info_table = proplum_get_load_info_table_name() %}
SELECT * FROM {{ load_info_table }}
```

---

## greenplum__snapshot_merge_sql.sql

### Назначение
Фикс для работы snapshot в Greenplum.

### Проблема
Оригинальный макрос `greenplum__snapshot_merge_sql` в адаптере вызывал сам себя рекурсивно, что приводило к бесконечному циклу и ошибке.

### Решение
Макрос делегирует выполнение в `postgres__snapshot_merge_sql`, который корректно генерирует MERGE SQL для PostgreSQL-совместимых баз.

### Ошибка без фикса
```
RecursionError: maximum recursion depth exceeded
```

---

## greenplum__snapshot_staging_table.sql

### Назначение
Фикс для корректной типизации в staging таблице snapshot для Greenplum.

### Проблема
При создании staging таблицы для snapshot, колонка `dbt_change_type` создавалась без явного указания типа. В Greenplum это приводило к ошибкам типизации при UNION операциях.

### Решение
Добавлено явное приведение типа `'insert'::text`, `'update'::text`, `'delete'::text` для колонки `dbt_change_type` во всех CTE (insertions, updates, deletes, deletion_records).

### Ключевые изменения
```sql
-- Было (неявный тип)
'insert' as dbt_change_type

-- Стало (явный тип)
'insert'::text as dbt_change_type
```

### Ошибка без фикса
```
ERROR: UNION types text and unknown cannot be matched
```

---

## greenplum__proplum_filter_delta.sql

### Назначение
Переопределение макроса `proplum_filter_delta` для корректной работы при первом запуске (init).

### Проблема
Оригинальный макрос `proplum_filter_delta` проверял существование relation (`existing_relation`) и если таблица не существовала (первый запуск), фильтр по дате не применялся и данные в `dbt_load_info` не логировались.

### Решение
Убрана проверка `existing_relation` из основного условия. Теперь:
1. При обычном запуске — читает диапазон дат из `dbt_load_info`
2. При первом запуске (init) — вызывает `proplum_get_extraction_dates` для:
   - Логирования в `dbt_load_info`
   - Получения корректного диапазона дат

### Логика работы
```
if log_dates=true:
    → Всегда вызывает proplum_get_extraction_dates с логированием

if log_dates=false:
    → Пытается прочитать даты из dbt_load_info
    → Если таблица новая (init) → вызывает proplum_get_extraction_dates
```

### Использование
```sql
SELECT *
FROM {{ source('raw', 'orders') }}
WHERE 1=1
{{ proplum_filter_delta('updated_at') }}
```

---

## Общая схема зависимостей

```
greenplum__proplum_filter_delta
    └── proplum_get_load_info_table_name
            └── (читает из dbt_load_info)

greenplum__snapshot_staging_table
    └── (используется при dbt snapshot)

greenplum__snapshot_merge_sql
    └── postgres__snapshot_merge_sql
            └── (выполняет MERGE в target таблицу)

generate_schema_name
    └── (вызывается автоматически dbt при создании relation)
```
