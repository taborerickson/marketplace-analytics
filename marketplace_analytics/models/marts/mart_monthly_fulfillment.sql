-- mart_monthly_fulfillment 
-- one row per purchase month and order-associated customer state
-- monthly ordre counts, recorded values, payment exceptions, and on-time delivery

with orders as (
    select * from {{ ref('fct_orders') }}
),
aggregated as (
    select 
        purchase_month,
        customer_state, -- state recorded on the order
        -- order counts
        count(*) as order_count, 
        count_if(is_delivered) as delivered_order_count, 
        count_if(order_status = 'canceled') as canceled_order_count, 
        count_if(order_status = 'unavailable') as unavailable_order_count,
        count_if(has_items) as orders_with_items_count,
        count_if(has_payments) as orders_with_payments_count,
        count_if(is_payment_exception) as payment_exception_count,
        -- recorded values across all order statuses
        sum(merchandise_total) as recorded_merchandise_total,
        sum(freight_total) as recorded_freight_total,
        sum(item_plus_freight_total) as recorded_item_plus_freight_total,
        sum(payment_total) as recorded_payment_total,
        -- on-time denominator (status delivered with a delivery date)
        count_if(is_delivered) as on_time_eligible_order_count,
        -- on-time numerator 
        count_if(is_on_time) as on_time_order_count 
    from orders 
    group by purchase_month, customer_state
),
final as (
    select 
        -- surrogate key: built-in unique test can cover composite grain
        to_char(purchase_month, 'YYYY-MM') || '-' || customer_state as month_state_key,
        purchase_month,
        customer_state, 
        order_count,
        delivered_order_count,
        canceled_order_count,
        unavailable_order_count,
        orders_with_items_count,
        orders_with_payments_count,
        payment_exception_count,
        recorded_merchandise_total,
        recorded_freight_total,
        recorded_item_plus_freight_total,
        recorded_payment_total,
        on_time_eligible_order_count,
        on_time_order_count,
        -- ratio between 0 and 1
        (on_time_order_count / nullif(on_time_eligible_order_count, 0)) as on_time_rate
    from aggregated
)
select *
from final