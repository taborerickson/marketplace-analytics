-- stg_olist_customers
-- one row per order-associated customer record
-- exposes raw customers extract with both customer identifiers

with source as (
    select * from {{ source('olist', 'customers') }}
),
renamed as (
    select
        customer_id, -- unique id per order
        customer_unique_id, -- unique id per customer
        customer_zip_code_prefix,
        customer_city,
        customer_state
    from source
)
select *
from renamed