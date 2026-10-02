-- stg_olist_order_payments 
-- one row per payment record
-- renames and types the raw order payments extract

with source as (
    select * from {{ source('olist', 'order_payments') }}
),
renamed as (
    select
        -- surrogatt key: built-in unique test can cover composite grain
        order_id || '-' || payment_sequential as order_payment_key,
        order_id,
        payment_sequential::integer as payment_sequence,
        payment_type,
        payment_installments::integer as payment_installments,
        payment_value::number(12, 2) as payment_value
    from source
)
select *
from renamed