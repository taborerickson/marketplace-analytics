-- on_time_delivery_by_state
-- one row per oder-associated customer state, all months combined
-- on-time delivery 

with mart as (
    select * from {{ ref('mart_monthly_fulfillment') }}
),
by_state as (
    select 
        customer_state,
        sum(order_count) as order_count,
        sum(on_time_eligible_order_count) as on_time_eligible_order_count,
        sum(on_time_order_count) as on_time_order_count
    from mart 
    group by customer_state
)
select 
    customer_state,
    order_count,
    on_time_eligible_order_count,
    on_time_order_count,
    round(
        (on_time_order_count / nullif(on_time_eligible_order_count, 0)), 4
    ) as on_time_rate 
from by_state 
order by on_time_eligible_order_count desc, customer_state