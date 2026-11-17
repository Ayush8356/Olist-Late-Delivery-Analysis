-- 06_revenue_associated.sql : revenue ASSOCIATED with late / bad-review orders. Orders were already paid; nothing here is "lost" revenue.
-- Revenue = SUM(item price) (no freight). Bad review = score <= 2. Orders with no review count as "not bad".
-- INR is for scale only: @fx is a single parameter (INR per 1 BRL). Fixed 17 Nov 2026 at 16.233, exchange-rates.org, see docs/DECISIONS.md.
SET @fx = 16.233;  -- fixed 17 Nov 2026, exchange-rates.org, see docs/DECISIONS.md

-- @out: results/06_revenue_segments.csv
WITH t AS (SELECT SUM(item_revenue) AS tot FROM v_order_base)
SELECT seg.segment, seg.orders, ROUND(seg.revenue,2) AS revenue_brl,
       ROUND(seg.revenue*@fx,0) AS revenue_inr_scale, ROUND(100*seg.revenue/t.tot,2) AS pct_of_total_revenue
FROM (
  SELECT '1 all delivered orders' AS segment, COUNT(*) AS orders, SUM(item_revenue) AS revenue FROM v_order_base
  UNION ALL SELECT '2 late orders', COUNT(*), SUM(item_revenue) FROM v_order_base WHERE is_late=1
  UNION ALL SELECT '3 bad-review orders (<=2 stars)', COUNT(*), SUM(item_revenue) FROM v_order_base WHERE is_bad_review=1
  UNION ALL SELECT '4 late AND bad', COUNT(*), SUM(item_revenue) FROM v_order_base WHERE is_late=1 AND is_bad_review=1
  UNION ALL SELECT '5 late, not bad', COUNT(*), SUM(item_revenue) FROM v_order_base WHERE is_late=1 AND COALESCE(is_bad_review,0)=0
  UNION ALL SELECT '6 bad, not late', COUNT(*), SUM(item_revenue) FROM v_order_base WHERE is_late=0 AND is_bad_review=1
) seg CROSS JOIN t ORDER BY seg.segment;

-- @out: results/06_excess_bad_reviews.csv
-- Excess bad reviews associated with lateness = (late bad rate - on-time bad rate) x late reviewed orders.
WITH x AS (
  SELECT SUM(is_late=1) AS late_reviewed,
         SUM(CASE WHEN is_late=1 THEN is_bad_review END)/SUM(is_late=1) AS late_bad,
         SUM(CASE WHEN is_late=0 THEN is_bad_review END)/SUM(is_late=0) AS ontime_bad,
         SUM(is_bad_review) AS all_bad
  FROM v_order_base WHERE review_score IS NOT NULL),
y AS (SELECT SUM(item_revenue)/COUNT(*) AS avg_rev_late_bad FROM v_order_base WHERE is_late=1 AND is_bad_review=1)
SELECT x.late_reviewed, ROUND(100*x.late_bad,2) AS late_bad_pct, ROUND(100*x.ontime_bad,2) AS ontime_bad_pct,
       ROUND((x.late_bad-x.ontime_bad)*x.late_reviewed,0) AS excess_bad_reviews,
       x.all_bad, ROUND(100*(x.late_bad-x.ontime_bad)*x.late_reviewed/x.all_bad,2) AS excess_as_pct_of_all_bad_reviews,
       ROUND((x.late_bad-x.ontime_bad)*x.late_reviewed*y.avg_rev_late_bad,0) AS revenue_on_excess_bad_orders_brl,
       ROUND((x.late_bad-x.ontime_bad)*x.late_reviewed*y.avg_rev_late_bad*@fx,0) AS revenue_on_excess_bad_orders_inr_scale,
       @fx AS fx_inr_per_brl
FROM x CROSS JOIN y;

-- @out: results/06_by_state.csv
SELECT customer_state, COUNT(*) AS orders, ROUND(100*AVG(is_late),2) AS late_pct,
       SUM(is_late=1 AND is_bad_review=1) AS late_and_bad_orders,
       ROUND(SUM(CASE WHEN is_late=1 AND is_bad_review=1 THEN item_revenue END),2) AS late_and_bad_revenue_brl,
       ROUND(100*SUM(CASE WHEN is_late=1 AND is_bad_review=1 THEN item_revenue END)/
             (SELECT SUM(item_revenue) FROM v_order_base WHERE is_late=1 AND is_bad_review=1),2) AS share_of_all_late_and_bad_revenue_pct
FROM v_order_base GROUP BY customer_state ORDER BY late_and_bad_revenue_brl DESC;

-- @out: results/06_top_sellers_late_and_bad.csv
SELECT seller_id, COUNT(*) AS orders, SUM(is_late) AS late_orders, ROUND(100*AVG(is_late),2) AS late_pct,
       SUM(is_late=1 AND is_bad_review=1) AS late_and_bad_orders,
       ROUND(SUM(CASE WHEN is_late=1 AND is_bad_review=1 THEN item_revenue END),2) AS late_and_bad_revenue_brl
FROM v_order_base WHERE seller_id IS NOT NULL GROUP BY seller_id
ORDER BY late_and_bad_revenue_brl DESC LIMIT 25;
