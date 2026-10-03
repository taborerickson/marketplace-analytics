-- 02_raw_load.sql
-- creates file format and stage
-- creates snowflake-managed storage location for uploaded files
-- creates raw tables (text)
-- loads each table; completes verification checks 

use role sysadmin; 
use warehouse marketplace_wh; 
use schema marketplace_analytics.raw; 

-- creating file format and stage 
create file format if not exists marketplace_analytics.raw.olist_csv
    type = csv 
    skip_header = 1 
    field_delimiter = ','
    field_optionally_enclosed_by = '"'
    empty_field_as_null = true 
    null_if = ('')
    encoding = 'UTF8'
    comment = 'Olist source CSV format'; 

-- snowflake-managed storage location for the uploaded files 
create stage if not exists marketplace_analytics.raw.olist_stage 
    file_format = marketplace_analytics.raw.olist_csv
    comment = 'Upload location for Olist source CSVs'; 

-- creating raw tables 
create table if not exists marketplace_analytics.raw.olist_orders (
    order_id varchar, 
    customer_id varchar, 
    order_status varchar, 
    order_purchase_timestamp varchar, 
    order_approved_at varchar, 
    order_delivered_carrier_date varchar, 
    order_delivered_customer_date varchar, 
    order_estimated_delivery_date varchar
); 

create table if not exists marketplace_analytics.raw.olist_order_items (
    order_id varchar, 
    order_item_id varchar, 
    product_id varchar, 
    seller_id varchar, 
    shipping_limit_date varchar, 
    price varchar, 
    freight_value varchar
);

create table if not exists marketplace_analytics.raw.olist_order_payments (
    order_id varchar, 
    payment_sequential varchar, 
    payment_type varchar, 
    payment_installments varchar, 
    payment_value varchar
);

create table if not exists marketplace_analytics.raw.olist_customers (
    customer_id varchar, 
    customer_unique_id varchar, 
    customer_zip_code_prefix varchar, 
    customer_city varchar, 
    customer_state varchar
);

-- show tables in schema marketplace_analytics.raw; 

-- Upload step (Snowsight UI, not SQL):
-- Database Explorer > MARKETPLACE_ANALYTICS > RAW > Stages > OLIST_STAGE > + Files
-- Upload the four Olist CSVs unchanged:
--   olist_orders_dataset.csv
--   olist_order_items_dataset.csv
--   olist_order_payments_dataset.csv
--   olist_customers_dataset.csv

-- Loading each table 
copy into marketplace_analytics.raw.olist_orders 
    from @marketplace_analytics.raw.olist_stage
    pattern = '.*olist_orders_dataset\\.csv.*'
    on_error = 'ABORT_STATEMENT'; 

copy into marketplace_analytics.raw.olist_order_items
    from @marketplace_analytics.raw.olist_stage 
    pattern = '.*olist_order_items_dataset\\.csv.*'
    on_error = 'ABORT_STATEMENT'; 

copy into marketplace_analytics.raw.olist_order_payments
    from @marketplace_analytics.raw.olist_stage 
    pattern = '.*olist_order_payments_dataset\\.csv.*'
    on_error = 'ABORT_STATEMENT'; 

copy into marketplace_analytics.raw.olist_customers
    from @marketplace_analytics.raw.olist_stage 
    pattern = '.*olist_customers_dataset\\.csv.*'
    on_error = 'ABORT_STATEMENT'; 


-- Verification 
list @marketplace_analytics.raw.olist_stage; 

-- Expected row counts (must match local CSV data rows):
--   orders 99441 | order_items 112650 | order_payments 103886 | customers 99441
select 
    'orders' as table_name, 
    count(*) as row_count
from 
    marketplace_analytics.raw.olist_orders 
union all 
select 
    'order_items', 
    count(*) 
from 
    marketplace_analytics.raw.olist_order_items
union all 
select 
    'order_payments', 
    count(*)
from 
    marketplace_analytics.raw.olist_order_payments
union all 
select 
    'customers', 
    count(*)
from 
    marketplace_analytics.raw.olist_customers; 
