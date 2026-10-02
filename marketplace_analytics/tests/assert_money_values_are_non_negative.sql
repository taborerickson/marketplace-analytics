-- assert_money_values_are_non_negative
-- singular data test. Returns the failing rows; zero rows means pass
-- Asserts: no staged item price, item freight value, or payment value is negative.

select
    'stg_olist_order_items' as model_name,
    order_item_key as record_key,
    item_price as first_value,
    freight_value as second_value
from {{ ref('stg_olist_order_items') }}
where item_price < 0
    or freight_value < 0
union all
-- Payments have one money column; second value is null.
select
    'stg_olist_order_payments',
    order_payment_key,
    payment_value,
    null
from {{ ref('stg_olist_order_payments') }}
where payment_value < 0