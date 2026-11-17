-- 02_delay_buckets.sql : how big is the delay problem, and does the review drop look like a cliff or a slope?
-- Population: delivered orders, purchase 2017-01..2018-08 (v_order_base). Review metrics use reviewed orders only.

-- @out: results/02_delay_buckets.csv
SELECT delay_bucket,
       COUNT(*)                                                         AS orders,
       ROUND(100*COUNT(*)/SUM(COUNT(*)) OVER (),2)                      AS pct_of_orders,
       SUM(review_score IS NOT NULL)                                    AS reviewed_orders,
       ROUND(AVG(review_score),2)                                       AS avg_review,
       ROUND(100*SUM(review_score = 1)/SUM(review_score IS NOT NULL),2) AS pct_1_star,
       ROUND(100*SUM(is_bad_review)/SUM(review_score IS NOT NULL),2)    AS pct_bad_review_le2,
       ROUND(SUM(item_revenue),2)                                       AS revenue_brl
FROM v_order_base
GROUP BY delay_bucket
ORDER BY FIELD(delay_bucket,'on_time','1-3','4-9','10+');

-- @out: results/02_delay_by_day.csv
-- day-by-day curve (days clipped to -10..+20) to test cliff vs gradual
SELECT LEAST(GREATEST(delay_days,-10),20)                               AS delay_day_clipped,
       COUNT(*)                                                         AS orders,
       SUM(review_score IS NOT NULL)                                    AS reviewed_orders,
       ROUND(AVG(review_score),2)                                       AS avg_review,
       ROUND(100*SUM(is_bad_review)/SUM(review_score IS NOT NULL),2)    AS pct_bad_review_le2
FROM v_order_base
GROUP BY 1 ORDER BY 1;

-- @out: results/02_monthly_late_rate.csv
SELECT purchase_month, COUNT(*) AS orders, SUM(is_late) AS late_orders,
       ROUND(100*AVG(is_late),2) AS late_pct, ROUND(AVG(review_score),2) AS avg_review,
       ROUND(SUM(item_revenue),2) AS revenue_brl
FROM v_order_base GROUP BY purchase_month ORDER BY purchase_month;

-- @out: results/02_overall.csv
SELECT COUNT(*) AS orders, SUM(is_late) AS late_orders, ROUND(100*AVG(is_late),2) AS late_pct,
       ROUND(AVG(CASE WHEN is_late=0 THEN review_score END),2) AS avg_review_on_time,
       ROUND(AVG(CASE WHEN is_late=1 THEN review_score END),2) AS avg_review_late,
       ROUND(100*SUM(CASE WHEN is_late=0 THEN is_bad_review END)/SUM(CASE WHEN is_late=0 THEN review_score IS NOT NULL END),2) AS bad_pct_on_time,
       ROUND(100*SUM(CASE WHEN is_late=1 THEN is_bad_review END)/SUM(CASE WHEN is_late=1 THEN review_score IS NOT NULL END),2) AS bad_pct_late,
       ROUND(SUM(item_revenue),2) AS revenue_brl
FROM v_order_base;
