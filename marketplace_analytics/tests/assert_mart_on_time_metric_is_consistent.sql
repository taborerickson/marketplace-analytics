-- assert_mart_on_time_metric_is_consistent
-- singular data test. Returns the failing row; zero rows means pass
-- For every mart row, Asserts:
--   - the numberator never exceeds the denominator
--   - the denominator equals the delivered order count
--   - the rate is null exactly when the denominator is zero

select 
    month_state_key, 
    delivered_order_count, 
    on_time_eligible_order_count,
    on_time_order_count,
    on_time_rate
from {{ ref('mart_monthly_fulfillment') }}
where on_time_order_count > on_time_eligible_order_count
    or on_time_eligible_order_count <> delivered_order_count
    or (on_time_eligible_order_count = 0 and on_time_rate is not null) 
    or (on_time_eligible_order_count > 0 and on_time_rate is null) 