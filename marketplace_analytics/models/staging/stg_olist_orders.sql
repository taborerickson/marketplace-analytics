with source as (
    select * from {{ source('olist', 'orders') }}
),
renamed as (
    select
        order_id,
        customer_id,
        order_status,
        order_purchase_timestamp::timestamp_ntz as purchased_at,
        order_approved_at::timestamp_ntz as approved_at,
        order_delivered_carrier_date::timestamp_ntz as delivered_to_carrier_at,
        order_delivered_customer_date::timestamp_ntz as delivered_to_customer_at,
        order_estimated_delivery_date::timestamp_ntz as estimated_delivery_at
    from source
)
select * 
from renamed