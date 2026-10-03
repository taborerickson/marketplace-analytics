-- 03_staging_row_counts.sql
-- Confirms dbt staging views return the same row counts as the raw tables.
-- Expected: orders 99441 | order_items 112650 | order_payments 103886 | customers 99441

select 
    'stg_olist_orders' as model,
    count(*) as row_count
from marketplace_analytics.dbt_dev.stg_olist_orders
union all
select 
    'stg_olist_order_items',
    count(*)
from marketplace_analytics.dbt_dev.stg_olist_order_items
union all
select 
    'stg_olist_order_payments',
    count(*)
from marketplace_analytics.dbt_dev.stg_olist_order_payments
union all 
select 
    'stg_olist_customers',
    count(*)
from marketplace_analytics.dbt_dev.stg_olist_customers;

