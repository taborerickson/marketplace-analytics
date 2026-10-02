-- stg_olist_order_items
-- one row per order item
-- renames and types the raw order items extract

with source as (
    select * from {{ source('olist', 'order_items') }}
),
renamed as (
    select
        -- surrogate key: built-in unique test can cover composite grain
        order_id || '-' || order_item_id as order_item_key,
        order_id,
        order_item_id::integer as order_item_sequence, -- item position in the order
        product_id,
        seller_id,
        shipping_limit_date::timestamp_ntz as shipping_limit_at,
        price::number(12, 2) as item_price,
        freight_value::number(12, 2) as freight_value
    from source
)
select *
from renamed