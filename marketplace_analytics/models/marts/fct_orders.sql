-- fct_orders
-- one row per order
-- order-level fact with item and payment totals
-- flags for coverage, payment exception, and delivery

with orders as (
    select * from {{ ref('stg_olist_orders') }}
),
customers as (
    select * from {{ ref('stg_olist_customers') }}
),
--============================================================
-- Deliberate defect (exercise branch only)
-- Items are joined to payments before aggregating. 
-- An order with 2 items and 2 payments becomes 4 rows
-- every total is counted twice 
item_payment_rows as (
    select 
        i.order_id, 
        i.seller_id, 
        i.item_price, 
        i.freight_value, 
        p.payment_value 
    from {{ ref('stg_olist_order_items') }} as i 
    inner join {{ ref('stg_olist_order_payments') }} as p 
        on i.order_id = p.order_id
),
item_totals as (
    select 
        order_id, 
        count(*) as item_count, 
        count(distinct seller_id) as seller_count,
        sum(item_price) as merchandise_total,
        sum(freight_value) as freight_total,
        (sum(item_price) + sum(freight_value)) as item_plus_freight_total
    from item_payment_rows
    group by order_id
),
payment_totals as (
    select 
        order_id,
        count(*) as payment_count,
        sum(payment_value) as payment_total
    from item_payment_rows
    group by order_id
),

--============================================================
joined as (
    select 
        o.order_id,
        o.customer_id,
        c.customer_unique_id,
        c.customer_zip_code_prefix,
        c.customer_city,
        c.customer_state,
        o.order_status,
        o.purchased_at,
        -- first day of the purchase month
        date_trunc('month', o.purchased_at)::date as purchase_month,
        o.approved_at,
        o.delivered_to_carrier_at,
        o.delivered_to_customer_at,
        o.estimated_delivery_at,
        -- coverage flags
        it.order_id is not null as has_items,
        pt.order_id is not null as has_payments,
        it.item_count,
        it.seller_count,
        it.merchandise_total,
        it.freight_total,
        it.item_plus_freight_total,
        pt.payment_count,
        pt.payment_total,
        (pt.payment_total - it.item_plus_freight_total) as payment_difference
    from orders as o 
    left join customers as c 
        on o.customer_id = c.customer_id 
    left join item_totals as it 
        on o.order_id = it.order_id 
    left join payment_totals as pt 
        on o.order_id = pt.order_id
),
final as (
    select 
        joined.*,
        -- payment exception
        case 
            when has_items and has_payments 
                then abs(payment_difference) > 0.01
            else false
        end as is_payment_exception,
        -- delivered status
        (
            order_status='delivered' 
            and delivered_to_customer_at is not null
        ) as is_delivered,
        -- on time deliveries
        case 
            when (
                order_status='delivered'
                and delivered_to_customer_at is not null 
            ) then delivered_to_customer_at::date <= estimated_delivery_at::date 
        end as is_on_time,
        -- source exceptions
        (
            order_status='delivered'
            and delivered_to_customer_at is null 
        ) as is_delivered_missing_delivery_date,
        (
            order_status='canceled'
            and delivered_to_customer_at is not null 
        ) as is_canceled_with_delivery_date
    from joined
)
select *
from final