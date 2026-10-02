-- payment_exceptions
-- one row per order flagged as a payment exception
-- lists orders where recorded payments and item-plus-freight totals differ by more than 0.01

with orders as (
    select * from {{ ref('fct_orders') }}
)
select 
    order_id, 
    order_status,
    purchase_month,
    customer_state,
    item_count, 
    seller_count,
    payment_count,
    merchandise_total,
    freight_total,
    item_plus_freight_total,
    payment_total,
    payment_difference -- positive means more was paid the item-plus-freight total
from orders
where is_payment_exception
order by abs(payment_difference) desc, order_id