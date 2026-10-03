# Metric Definitions

Every metric is defined once, in `fct_orders`, and aggregated in `mart_monthly_fulfillment`. The mart stores numerators and denominators next to every rate. Values shown are verified results on the full dataset. 

## Order count
- **Rule:** every source order across all eight order statuses
- **Column:** `mart_monthly_fulfillment.order_count`
- **Verified value:** 99,441 (raw, staging, fact, and the mart all agree)

## Delivered order
- **Rule:** order status is `delivered` and a customer delivery date is present.
- **Columns:** `fct_orders.is_delivered`, `mart_monthly_fulfillment.delivered_order_count`
- **Excluded:** 8 orders with status `delivered` and no delivery date. They are flagged with `is_delivered_missing_delivery_date` and kept in the fact.
- **Verified value:** 96,470

## On-time delivery
- **Rule:** the delivery calendar date is on or before the estimated delivery calendar date. Dates are compared, not timestamps.
- **Numerator:** `on_time_order_count` (delivered orders that meet the rule)
- **Denominator:** `on_time_eligible_order_count` (delivered orders, equal to
  `delivered_order_count`)
- **Rate:** `on_time_rate` is numerator divided by denominator (a ratio between 0 and 1). It is null when the denominator is zero.
- **Not eligible:** orders that are not delivered. `fct_orders.is_on_time` is null for them, so they are in neither the numerator nor the denominator.
- **Verified value:** 89,936 of 96,470; rate of 0.9323

## Payment exception 

- **Rule:** the order has both items and payments, and the absolute difference between the recorded payment total and the item-plus-freight total is greater than 0.01
- **Columns:** `fct_orders.payment_difference` (payment total minus item-plus-freight total), `fct_orders.is_payment_exception`, `mart_monthly_fulfillment.payment_exception_count`
- **Not an exception:** an order missing items or payments. Its difference is null and the flag is false. A difference of exactly 0.01 is not an exception.
- **Verified values:** 98,665 orders have both sides. 98,089 match exactly, 273 differ by 0.01 or less, and 303 are exceptions. The largest absolute difference is 182.81.

## Recorded values
- **Rule:** sums across all order statuses, including canceled and unavailable orders. These are recorded marketplace values, not company revenue.
- **Columns and verified values:**

| Column | Definition | Verified value |
|---|---|---:|
| `recorded_merchandise_total` | Sum of item prices | 13,591,643.70 |
| `recorded_freight_total` | Sum of item freight values | 2,251,909.54 |
| `recorded_item_plus_freight_total` | Merchandise plus freight | 15,843,553.24 |
| `recorded_payment_total` | Sum of recorded payment values | 16,008,872.12 |

## Coverage and status counts

| Column | Definition | Verified value |
|---|---|---:|
| `orders_with_items_count` | Orders with at least one item record | 98,666 |
| `orders_with_payments_count` | Orders with at least one payment record | 99,440 |
| `canceled_order_count` | Orders with status `canceled` | 625 |
| `unavailable_order_count` | Orders with status `unavailable` | 609 |

775 orders have no items and 1 order has no payments.


