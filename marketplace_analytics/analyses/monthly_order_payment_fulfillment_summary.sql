-- monthly_order_payment_fulfillment_summary
-- one row per purchase month; all state combined
-- monthly orders, recorded values, payment exceptions, on-time rate

with mart as (
    select * from {{ ref('mart_monthly_fulfillment') }}
),
monthly as (
    select 
        purchase_month,
        sum(order_count) as order_count, 
        sum(delivered_order_count) as delivered_order_count,
        sum(canceled_order_count) as canceled_order_count,
        sum(unavailable_order_count) as unavailable_order_count,
        sum(payment_exception_count) as payment_exception_count,
        -- recorded values include all order statuses
        sum(recorded_merchandise_total) as recorded_merchandise_total,
        sum(recorded_freight_total) as recorded_freight_total,
        sum(recorded_payment_total) as recorded_payment_total,
        sum(on_time_eligible_order_count) as on_time_eligible_order_count,
        sum(on_time_order_count) as on_time_order_count
    from mart
    group by purchase_month
)
select 
    purchase_month,
    order_count,
    delivered_order_count,
    canceled_order_count,
    unavailable_order_count,
    payment_exception_count,
    recorded_merchandise_total,
    recorded_freight_total,
    recorded_payment_total,
    on_time_eligible_order_count,
    on_time_order_count,
    round(
        (on_time_order_count / nullif(on_time_eligible_order_count, 0)), 4
    ) as on_time_rate 
from monthly 
order by purchase_month