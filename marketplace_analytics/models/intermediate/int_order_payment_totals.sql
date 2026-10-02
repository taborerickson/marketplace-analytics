-- int_order_payment_totals
-- one row per order that has at least one payment record
-- reduces payments to the order grain before joining to items

with order_payments as (
    select * from {{ ref('stg_olist_order_payments') }}
),
aggregated as (
    select
        order_id,
        count(*) as payment_count, -- includes zero-value records 
        sum(payment_value) as payment_total
    from order_payments
    group by order_id
)
select *
from aggregated