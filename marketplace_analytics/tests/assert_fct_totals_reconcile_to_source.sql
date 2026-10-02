-- assert_fct_totals_reconcile_to_source
-- singular data test (custom SQL). Returns the failing rows; zero rows means pass
-- Asserts: the order count and the merchandise, freight, and payment totals in
--   fct_orders equal the same figures computed directly from the raw source tables.


with source_totals as (
    select 
        'order_count' as measure, 
        count(*) as source_value
    from {{ source('olist', 'orders') }}
    union all
    select 
        'merchandise_total', 
        sum(price::number(12, 2))
    from {{ source('olist', 'order_items') }}
    union all
    select 
        'freight_total', 
        sum(freight_value::number(12, 2))
    from {{ source('olist', 'order_items') }}
    union all
    select 
        'payment_total', 
        sum(payment_value::number(12, 2))
    from {{ source('olist', 'order_payments') }}
),
fact_totals as (
    select 
        'order_count' as measure, 
        count(*) as fact_value
    from {{ ref('fct_orders') }}
    union all
    select 
        'merchandise_total', 
        sum(merchandise_total)
    from {{ ref('fct_orders') }}
    union all
    select 
        'freight_total', 
        sum(freight_total)
    from {{ ref('fct_orders') }}
    union all
    select 
        'payment_total', 
        sum(payment_total)
    from {{ ref('fct_orders') }}
)
-- One row per measure that does not match. The difference column shows the
--   size and direction of the problem in the test failure output.
select
    source_totals.measure,
    source_totals.source_value,
    fact_totals.fact_value,
    (fact_totals.fact_value - source_totals.source_value) as fact_minus_source
from source_totals
inner join fact_totals
    on source_totals.measure = fact_totals.measure
where source_totals.source_value is distinct from fact_totals.fact_value