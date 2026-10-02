-- assert_mart_totals_reconcile_to_fct
-- singular data test. Returns the failing rows; zero rows means pass.
-- Asserts: counts and recorded totals sum across mart_monthly_fulfillment
--   equal the same aggregates taken directly from fct_orders.


with mart_totals as (
    select
        sum(order_count) as order_count,
        sum(delivered_order_count) as delivered_order_count,
        sum(on_time_order_count) as on_time_order_count,
        sum(payment_exception_count) as payment_exception_count,
        sum(recorded_merchandise_total) as merchandise_total,
        sum(recorded_freight_total) as freight_total,
        sum(recorded_item_plus_freight_total) as item_plus_freight_total,
        sum(recorded_payment_total) as payment_total
    from {{ ref('mart_monthly_fulfillment') }}
),
fact_totals as (
    select
        count(*) as order_count,
        count_if(is_delivered) as delivered_order_count,
        count_if(is_on_time) as on_time_order_count,
        count_if(is_payment_exception) as payment_exception_count,
        sum(merchandise_total) as merchandise_total,
        sum(freight_total) as freight_total,
        sum(item_plus_freight_total) as item_plus_freight_total,
        sum(payment_total) as payment_total
    from {{ ref('fct_orders') }}
)
-- Each side is a single row; cross join produces one row. 
select
    mart_totals.order_count as mart_order_count,
    fact_totals.order_count as fact_order_count,
    mart_totals.delivered_order_count as mart_delivered_order_count,
    fact_totals.delivered_order_count as fact_delivered_order_count,
    mart_totals.on_time_order_count as mart_on_time_order_count,
    fact_totals.on_time_order_count as fact_on_time_order_count,
    mart_totals.payment_exception_count as mart_payment_exception_count,
    fact_totals.payment_exception_count as fact_payment_exception_count,
    mart_totals.merchandise_total as mart_merchandise_total,
    fact_totals.merchandise_total as fact_merchandise_total,
    mart_totals.freight_total as mart_freight_total,
    fact_totals.freight_total as fact_freight_total,
    mart_totals.item_plus_freight_total as mart_item_plus_freight_total,
    fact_totals.item_plus_freight_total as fact_item_plus_freight_total,
    mart_totals.payment_total as mart_payment_total,
    fact_totals.payment_total as fact_payment_total
from mart_totals
cross join fact_totals
where mart_totals.order_count is distinct from fact_totals.order_count
    or mart_totals.delivered_order_count is distinct from fact_totals.delivered_order_count
    or mart_totals.on_time_order_count is distinct from fact_totals.on_time_order_count
    or mart_totals.payment_exception_count is distinct from fact_totals.payment_exception_count
    or mart_totals.merchandise_total is distinct from fact_totals.merchandise_total
    or mart_totals.freight_total is distinct from fact_totals.freight_total
    or mart_totals.item_plus_freight_total is distinct from fact_totals.item_plus_freight_total
    or mart_totals.payment_total is distinct from fact_totals.payment_total