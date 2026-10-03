# Debugging Note: Join Fanout in fct_orders

## What was done
On the branch `defect-fanout-exercise`, a deliberate defect was introduced in `fct_orders`: items were joined to payments before aggregating, instead of aggregating each to the order grain first. The defect was then detected, diagnosed, and reverted. The main branch never contained the defect. 

## Symptom
1. `dbt build` failed on the unit test `fct_orders_keeps_35_and_flags_exceptions`. The known-answer order (items 10 + 2 and 20 + 3, payments 15 and 20) returned 70 for item-plus-freight and 70 for payments, where 35 and 35 were expected. dbt skipped the model, so the existing table was not overwritten. 
2. With unit tests excluded, the model built and the singular test `assert_fct_totals_reconcile_to_source` failed on 3 measures: 

| Measure | Source | Fact | Difference | 
|---|---:|---:|---:|
| merchandise_total | 13,591,643.70 | 14,209,115.34 | 617,471.64 | 
| freight_total | 2,251,909.54 | 2,357,428.51 | 105,518.97 |
| payment_total | 16,008,872.12 | 20,308,134.71 | 4,299,262.59 |

## What did not catch it
- The payment difference on the known-answer order stayed 0, because both sides were doubled. 
- The unique test and the order coverage test passed, because the defect still returned one row per order. 
- `assert_mart_totals_reconcile_to_fct` passed, because the mart was built from the inflated fact. Comparing two inflated totals did not prove anything.

## Diagnosis
An order with 2 items and 2 payments produces 2 x 2 = 4 joined rows. Each item value sums once per payment, and each payment once per item.

## Fix
Reverted the defect commit, which restores the aggregate-then-join design (`int_order_item_totals` and `int_order_payment_totals`). The rebuild passed: `PASS=63 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=63`.

## Takeaway
Reconcile to an independent source, not to another output of the same logic, and keep a small known-answer fixture for every join that changes grain.
