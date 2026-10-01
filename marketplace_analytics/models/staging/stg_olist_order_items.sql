with source as (
    select * from {{ source('olist', 'order_items') }}
),
renamed as (
    select
        order_id || '-' || order_item_id as order_item_key,
        order_id,
        order_item_id::integer as order_item_sequence,
        product_id,
        seller_id,
        shipping_limit_date::timestamp_ntz as shipping_limit_at,
        price::number(12, 2) as item_price,
        freight_value::number(12, 2) as freight_value
    from source
)
select *
from renamed