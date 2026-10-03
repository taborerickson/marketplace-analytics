-- 07_fresh_schema_rebuild_checks.sql
-- Compares key figures between the development schema (DBT_DEV)
-- and the fresh rebuild schema (DBT_REBUILD).
-- The two rows must be identical. 
-- Requires: dbt build --target rebuild

select 'dbt_dev' as schema_name, f.*, m.*, d.*
from (
    -- order fact: coverage, exceptions, delivery, and value totals
    select 
        count(*) as fact_rows,
        count_if(not has_items) as orders_without_items, 
        count_if(not has_payments) as orders_without_payments,
        count_if(is_payment_exception) as payment_exceptions,
        max(abs(payment_difference)) as max_abs_difference,
        count_if(is_delivered) as delivered_orders,
        count_if(is_on_time) as on_time_orders,
        sum(merchandise_total) as merchandise,
        sum(freight_total) as freight,
        sum(payment_total) as payments
    from marketplace_analytics.dbt_dev.fct_orders
) as f 
cross join (
    -- mart: row count and the order count it sums to
    select 
        count(*) as mart_rows,
        sum(order_count) as mart_order_count
    from marketplace_analytics.dbt_dev.mart_monthly_fulfillment
) as m 
cross join (
    -- customer dimension row count
    select count(*) as dim_customer_rows
    from marketplace_analytics.dbt_dev.dim_customers
) as d 

union all 

select 'dbt_rebuild', f.*, m.*, d.*
from (
    select
        count(*) as fact_rows,
        count_if(not has_items) as orders_without_items, 
        count_if(not has_payments) as orders_without_payments,
        count_if(is_payment_exception) as payment_exceptions,
        max(abs(payment_difference)) as max_abs_difference,
        count_if(is_delivered) as delivered_orders,
        count_if(is_on_time) as on_time_orders,
        sum(merchandise_total) as merchandise,
        sum(freight_total) as freight,
        sum(payment_total) as payments
    from marketplace_analytics.dbt_rebuild.fct_orders 
) as f
cross join (
    select 
        count(*) as mart_rows, 
        sum(order_count) as mart_order_count
    from marketplace_analytics.dbt_rebuild.mart_monthly_fulfillment
) as m
cross join (
    select count(*) as dim_customer_rows
    from marketplace_analytics.dbt_rebuild.dim_customers
) as d;