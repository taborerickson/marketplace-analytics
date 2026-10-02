-- assert_fct_orders_covers_all_staged_orders
-- singular data test. Returns the failing rows; zero means pass
-- Asserts: every staged order appears exactly once in fct_orders, and
--   fct_orders contains no order that staging lacks

with staged_orders as (
    select order_id 
    from {{ ref('stg_olist_orders') }}
),
-- count of fact rows per order so duplicated order is 
-- visible as a count above 1
fact_orders as (
    select 
        order_id, 
        count(*) as fact_row_count
    from {{ ref('fct_orders') }}
    group by order_id 
),
-- keeping orders that exist on only one side
compared as (
    select
        coalesce(staged_orders.order_id, fact_orders.order_id) as order_id, 
        staged_orders.order_id is not null as is_in_staging, 
        coalesce(fact_orders.fact_row_count, 0) as fact_row_count
    from staged_orders
    full outer join fact_orders 
        on staged_orders.order_id = fact_orders.order_id
)
select * 
from compared
where not is_in_staging
    or fact_row_count <> 1