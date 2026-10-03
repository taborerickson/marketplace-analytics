# Design Decisions

## Layers and materializations

| Layer | Models | Materialization | Reason |
|---|---|---|---|
| Staging | 4 | View | Rename and cast only. Always reflects the raw tables. |
| Intermediate | 2 | View | Order-grain aggregations, cheap to compute on demand. |
| Marts | 3 | Table | Queried repeatedly, so the results are stored. |

## Aggregate before joining

Items and payments are each reduced to one row per order (`int_order_item_totals`, `int_order_payment_totals`) before they meet in `fct_orders`.

Known-answer example: one order with items (price 10, freight 2) and (price 20, freight 3), and payments of 15 and 20. The correct totals are 35 for item-plus-freight and 35 for payments. Joining items directly to payments produces 4 rows and 70 on both sides. The difference is still 0, so the inflated result looks reconciled. Three unit tests hold the answer at 35, and `docs/debugging_notes.md` records what happened when the defect was introduced on purpose.

## Fact grain and coverage

- `fct_orders` has one row per source order, for every status.
- It starts from all staged orders and left joins the aggregates, so no order is dropped.
- `has_items` and `has_payments` flag missing child records. Totals stay null when records are missing, because a missing record is not a zero-value transaction.
- Source exceptions are flagged and kept, not corrected or removed: 8 delivered orders without a delivery date and 6 canceled orders with one.

## Customer identity

- `customer_id` is the order-associated record. The source issues a new one for every order.
- `customer_unique_id` identifies the repeat customer (96,096 customers across 99,441 orders).
- `fct_orders` carries the location recorded on the order. `dim_customers` carries the location on the customer's latest order. Historical geography is never rewritten with the latest location.

## Settled rules

| # | Topic | Rule |
|---|---|---|
| 1 | Money type | `NUMBER(12,2)`, exact decimal |
| 2 | Timestamp type | `TIMESTAMP_NTZ`. The source time zone is not stated. |
| 3 | Delivered order | Status `delivered` and a delivery date present |
| 4 | On-time delivery | Delivery calendar date on or before the estimated calendar date, among delivered orders |
| 5 | Payment exception | Absolute difference above 0.01, only when items and payments both exist |
| 6 | Value totals | All statuses included and labeled "recorded" |
| 7 | Sparse edge months | Kept and documented |
| 8 | Source anomalies | Zero installments, zero-value payments, and payment type `not_defined` are kept |
| 9 | Customer attributes | Latest order by purchase timestamp, ties broken by `order_id` |

## Other choices

- **Strict casts in staging.** An unparseable value fails the build instead of silently becoming null.
- **Raw tables are all text.** Typing happens in staging, which preserves leading zeros in ZIP prefixes and the exact source values.
- **Surrogate keys** on composite grains, so the built-in `unique` test applies without an extra package.
- **Null rate, not zero,** when a group has no delivered orders. A zero would read as "nothing arrived on time".
- **Ownership metadata** is set once for all models in `dbt_project.yml`.

## Testing approach

| Layer of assurance | What it covers |
|---|---|
| 46 generic tests | Keys, relationships, accepted values, required columns |
| 5 singular tests | Order coverage, reconciliation to the raw sources, mart consistency, on-time metric rules, non-negative money |
| 3 unit tests | The known-answer fixture, run on mocked rows before the model builds |
| SQL scripts in `sql/validation/` | Independent checks run directly in Snowflake |

The source reconciliation test compares the fact to the raw tables, not to
another model. A test that compares two outputs of the same logic passes even
when both are wrong.

## Limitations

- **Sparse edge months.** The first month (2016-09) and the last month (2018-10) have 4 orders each. Their rates are not comparable to full months.
- **One calendar month has no orders:** 2016-11. The mart has 25 months across a 26-month span.
- **Null rates.** Nine month-and-state rows have no delivered orders, so their on-time rate is null by design.
- **Small denominators.** Low-volume states and months can show extreme rates. Read each rate with its denominator.
- **Cohort view.** Outcomes describe what eventually happened to a month's purchases in this historical extract. They are not a live operational view.
- **Not revenue.** Merchandise value and recorded payments are marketplace values, not company revenue.
- **Unexplained exceptions.** The 303 payment exceptions are reported, not explained. The extract does not say why they differ.
- **Static data.** The project loads a fixed historical extract once. There is no incremental loading, freshness check, or scheduled run.
