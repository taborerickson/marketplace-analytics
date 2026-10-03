-- 05_mart_monthly_fulfillment_checks.sql
-- checks mart_monthly_fulfillment in DBT_DEV

-- Q5: mart counts against foundation baselines
select 
    sum(order_count) as order_count,
    sum(delivered_order_count) as delivered_orders,
    sum(on_time_eligible_order_count) as on_time_eligible,
    sum(on_time_order_count) as on_time_orders,
    sum(canceled_order_count) as canceled_orders,
    sum(unavailable_order_count) as unavailable_orders,
    sum(orders_with_items_count) as orders_with_items,
    sum(orders_with_payments_count) as orders_with_payments,
    sum(payment_exception_count) as payment_exceptions
from marketplace_analytics.dbt_dev.mart_monthly_fulfillment;

-- Q6: mart value totals and grain structure 
select
    sum(recorded_merchandise_total) as merchandise,
    sum(recorded_freight_total) as freight,
    sum(recorded_item_plus_freight_total) as item_plus_freight,
    sum(recorded_payment_total) as payments,
    count(*) as mart_rows,
    count(distinct month_state_key) as distinct_keys,
    count(distinct customer_state) as states,
    count(distinct purchase_month) as months,
    min(purchase_month) as first_month,
    max(purchase_month) as last_month,
    count_if(on_time_order_count > on_time_eligible_order_count) as on_time_exceeds_eligible,
    count_if(on_time_eligible_order_count = 0) as rows_zero_eligible,
    count_if(on_time_rate is null) as rows_null_rate
from marketplace_analytics.dbt_dev.mart_monthly_fulfillment;
