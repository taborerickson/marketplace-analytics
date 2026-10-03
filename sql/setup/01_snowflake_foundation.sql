-- 01_snowflake_foundation.sql 
-- creates the Snowflake objects for the marketplace analytics project. 
-- Safe to re-run: uses 'if not exists' and does not drop or replace objects. 
-- Run as a role allowed to create warehouses and databases (sysadmin). 

use role sysadmin; 

create warehouse if not exists marketplace_wh 
    warehouse_size = 'xsmall'
    auto_suspend = 60
    auto_resume = true 
    initially_suspended = true 
    comment = 'Compute for marketplace analtycis project'; 

create database if not exists marketplace_analytics 
    comment = 'Marketplace payments and fulfillment analytics'; 

create schema if not exists marketplace_analytics.raw 
    comment = 'Raw Olist extracts, loaded as-is'; 

create schema if not exists marketplace_analytics.dbt_dev
    comment = 'dbt development build target'; 

-- verification 
show warehouses like 'marketplace_wh'; 
show schemas in database marketplace_analytics; 
