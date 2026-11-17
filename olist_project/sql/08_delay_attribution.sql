-- 08_delay_attribution.sql : who is behind late deliveries, seller or logistics?
-- Late single-seller orders only. seller_overrun_days = days the carrier handover came after the item shipping limit
-- (MIN shipping_limit_date per order). Classes: logistics_only (handover on time), seller_only (handover delay >= total delay),
-- both (handover late but total delay is longer). Assumes a day of handover delay shifts delivery by a day; it is a heuristic.

-- @out: results/08_delay_attribution.csv
SELECT delay_class, COUNT(*) AS late_orders,
       ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (),2) AS pct_of_late_orders,
       ROUND(AVG(delay_days),1) AS avg_delay_days,
       ROUND(AVG(review_score),2) AS avg_review,
       ROUND(100*SUM(is_bad_review)/SUM(review_score IS NOT NULL),2) AS bad_review_pct,
       ROUND(SUM(item_revenue),2) AS revenue_brl
FROM v_order_base WHERE is_late = 1 AND delay_class NOT LIKE 'excluded%'
GROUP BY delay_class ORDER BY late_orders DESC;

-- @out: results/08_attribution_by_state.csv
SELECT customer_state, COUNT(*) AS late_orders,
       ROUND(100*SUM(delay_class='logistics_only')/COUNT(*),1) AS logistics_only_pct,
       ROUND(100*SUM(delay_class='seller_only')/COUNT(*),1)    AS seller_only_pct,
       ROUND(100*SUM(delay_class='both')/COUNT(*),1)           AS both_pct,
       ROUND(AVG(delay_days),1) AS avg_delay_days
FROM v_order_base WHERE is_late = 1 AND delay_class NOT LIKE 'excluded%'
GROUP BY customer_state HAVING COUNT(*) >= 30 ORDER BY late_orders DESC;

-- @out: results/08_top_sellers_seller_driven_lateness.csv
SELECT seller_id, COUNT(*) AS orders, SUM(is_late) AS late_orders,
       SUM(delay_class IN ('seller_only','both')) AS seller_driven_late_orders,
       ROUND(100*SUM(delay_class IN ('seller_only','both'))/COUNT(*),2) AS seller_driven_late_pct_of_orders,
       ROUND(SUM(CASE WHEN delay_class IN ('seller_only','both') THEN item_revenue END),2) AS seller_driven_late_revenue_brl
FROM v_order_base WHERE seller_id IS NOT NULL GROUP BY seller_id HAVING COUNT(*) >= 30
ORDER BY seller_driven_late_orders DESC LIMIT 25;
