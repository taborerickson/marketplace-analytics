-- 04_order_foundation_checks.sql
-- checks the order-level models in DBT_DEV.

-- Q1: fact checks
select 
    count(*) as fact_rows,
    count(distinct order_id) as distinct_orders,
    count_if(not has_items) as orders_without_items,
    count_if(not has_payments) as orders_without_payments,
    count_if(has_items and has_payments) as orders_with_payments_and_items,
    count(payment_difference) as orders_with_payment_difference,
    count_if(is_payment_exception) as payment_exceptions,
    max(abs(payment_difference)) as max_abs_payment_diff,
    count_if(is_delivered) as delivered_orders,
    count_if(is_on_time) as on_time_orders,
    count_if(is_delivered_missing_delivery_date) as delivered_missing_date,
    count_if(is_canceled_with_delivery_date) as canceled_with_date
from 
    marketplace_analytics.dbt_dev.fct_orders;

-- Q2: row counts for the other three models 
select 
    'int_order_item_totals' as model, 
    count(*) as row_count
from marketplace_analytics.dbt_dev.int_order_item_totals
union all
select 
    'int_order_payment_totals',
    count(*)
from marketplace_analytics.dbt_dev.int_order_payment_totals
union all 
select 
    'dim_customers',
    count(*)
from marketplace_analytics.dbt_dev.dim_customers;

-- Q3: dimension integrity
select 
    sum(order_count) as total_orders,
    count_if(order_count = 0) as customers_without_orders,
    max(order_count) as max_orders_per_customer
from marketplace_analytics.dbt_dev.dim_customers;

-- Q4: no-fanout check against raw
select 
    'fct_orders' as source,
    sum(merchandise_total) as merchandise,
    sum(freight_total) as freight,
    sum(payment_total) as payments
from marketplace_analytics.dbt_dev.fct_orders
union all 
select 
    'raw',
    (
        select 
            sum(price::number(12, 2)) 
        from marketplace_analytics.raw.olist_order_items
    ),
    (
        select 
            sum(freight_value::number(12, 2))
        from marketplace_analytics.raw.olist_order_items 
    ),
    (
        select 
            sum(payment_value::number(12, 2)) 
        from marketplace_analytics.raw.olist_order_payments
    );
