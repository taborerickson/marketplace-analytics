-- 06_raw_independent_checks.sql
-- independent checks that read only the RAW tables, with no dbt model involved

-- P1: raw grain check
-- For each raw table: row count, distinct key count, and null key count.
-- Pass condition: row_count equals distinct_key and null_key is 0 on every row.
SELECT 'orders' AS tbl, COUNT(*) AS row_count,
       COUNT(DISTINCT order_id) AS distinct_key,
       COUNT(*) - COUNT(order_id) AS null_key
FROM MARKETPLACE_ANALYTICS.RAW.OLIST_ORDERS
UNION ALL
SELECT 'order_items', COUNT(*), COUNT(DISTINCT order_id, order_item_id),
       COUNT(*) - COUNT(order_id)
FROM MARKETPLACE_ANALYTICS.RAW.OLIST_ORDER_ITEMS
UNION ALL
SELECT 'order_payments', COUNT(*), COUNT(DISTINCT order_id, payment_sequential),
       COUNT(*) - COUNT(order_id)
FROM MARKETPLACE_ANALYTICS.RAW.OLIST_ORDER_PAYMENTS
UNION ALL
SELECT 'customers', COUNT(*), COUNT(DISTINCT customer_id),
       COUNT(*) - COUNT(customer_id)
FROM MARKETPLACE_ANALYTICS.RAW.OLIST_CUSTOMERS;

-- P8: raw payment reconciliation
-- Aggregates items and payments to the order grain separately, then joins.
-- Uses only raw tables, so it is independent of every dbt model.
WITH items AS (
  SELECT order_id,
         SUM(TRY_TO_NUMBER(price, 12, 2) + TRY_TO_NUMBER(freight_value, 12, 2)) AS item_total
  FROM MARKETPLACE_ANALYTICS.RAW.OLIST_ORDER_ITEMS
  GROUP BY order_id
),
payments AS (
  SELECT order_id,
         SUM(TRY_TO_NUMBER(payment_value, 12, 2)) AS payment_total
  FROM MARKETPLACE_ANALYTICS.RAW.OLIST_ORDER_PAYMENTS
  GROUP BY order_id
)
SELECT
  COUNT(*)                                          AS orders_with_both,
  COUNT_IF(payment_total = item_total)              AS exact_match,
  COUNT_IF(ABS(payment_total - item_total) <= 0.01
           AND payment_total <> item_total)         AS within_1_cent,
  COUNT_IF(ABS(payment_total - item_total) > 0.01)  AS beyond_1_cent,
  MAX(ABS(payment_total - item_total))              AS max_abs_difference
FROM items
JOIN payments USING (order_id);
