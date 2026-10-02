-- dim_customers
-- one row per customer (customer_unique_id)
-- gives latest descriptive attributes per customer and order history summary

with customers as (
    select * from {{ ref('stg_olist_customers') }}
),
orders as (
    select * from {{ ref('stg_olist_orders') }}
),
-- one row per order-associated customer record
customer_orders as (
    select
        c.customer_unique_id,
        c.customer_zip_code_prefix,
        c.customer_city,
        c.customer_state,
        o.order_id,
        o.purchased_at
    from customers as c 
    -- keeps records even if there is no order
    left join orders as o 
        on c.customer_id = o.customer_id
),
ranked as (
    select 
        customer_unique_id, 
        customer_zip_code_prefix,
        customer_city,
        customer_state,
        row_number() over (
            partition by customer_unique_id
            order by purchased_at desc nulls last, order_id desc 
        ) as recency_rank,
        -- customer-level summary values
        count(order_id) over (
            partition by customer_unique_id
        ) as order_count,
        min(purchased_at) over (
            partition by customer_unique_id
        ) as first_purchased_at,
        max(purchased_at) over (
            partition by customer_unique_id
        )as latest_purchased_at
    from customer_orders
),
-- keeps only latest row per customer
final as (
    select 
        customer_unique_id,
        customer_zip_code_prefix as latest_zip_code_prefix,
        customer_city as latest_city,
        customer_state as latest_state,
        order_count,
        first_purchased_at,
        latest_purchased_at
    from ranked
    where recency_rank = 1
)
select *
from final