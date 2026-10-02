-- int_order_item_totals
-- one row per order that has at least one item
-- reduces items to the order grain before joining to payments
-- prevents row multiplication

with order_items as (
    select * from {{ ref('stg_olist_order_items') }}
),
aggregated as (
    select 
        order_id,
        count(*) as item_count,
        count(distinct seller_id) as seller_count,
        sum(item_price) as merchandise_total, -- merchandise value
        sum(freight_value) as freight_total,
        -- compared agains recorded payments in fct_orders
        (sum(item_price) + sum(freight_value)) as item_plus_freight_total
    from order_items
    group by order_id
)
select *
from aggregated