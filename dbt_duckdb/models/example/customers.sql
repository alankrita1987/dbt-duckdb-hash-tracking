{{
    config(
    materialized = 'incremental',
    unique_key = 'customer_id'
    )
}}

with source_data as (
    select
        *,
        md5(concat(first_name, last_name, number_of_orders, customer_lifetime_value)) as hash_key
    from {{ ref('customers_int') }}
),

incremental_data as (
    select
        sd.*,
        {% if is_incremental()%}
        case
            when t.hash_key is not null then t.hash_key
            else null
        end as prev_hash_key
        {% else %}
        null::VARCHAR as prev_hash_key
        {% endif %}


    from source_data sd
    
    {% if is_incremental() %}
        left join {{ this }} t
        on sd.customer_id = t.customer_id
    {% endif %}
)

select
    *,
    hash_key as prev_hash_key_test,
    current_localtimestamp() as load_timestamp
from incremental_data