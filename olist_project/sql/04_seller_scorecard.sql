-- 04_seller_scorecard.sql : seller-level view. Single-seller delivered orders only (98.7% of orders; avoids splitting one review across sellers).
-- Sellers with >= 30 such orders. Revenue = SUM(item price); freight share = freight / (price + freight).
-- Flag: top revenue decile AND bad-review rate above the marketplace rate.

-- @out: results/04_seller_scorecard.csv
WITH s AS (
  SELECT ob.seller_id, MIN(se.seller_state) AS seller_state, COUNT(*) AS orders,
         SUM(ob.item_revenue) AS revenue, SUM(ob.freight) AS freight,
         SUM(ob.is_late) AS late_orders,
         SUM(ob.seller_overrun_days > 0) AS seller_late_orders,
         SUM(ob.review_score IS NOT NULL) AS reviewed, AVG(ob.review_score) AS avg_review,
         SUM(ob.is_bad_review) AS bad_reviews
  FROM v_order_base ob JOIN sellers se ON se.seller_id = ob.seller_id
  WHERE ob.seller_id IS NOT NULL GROUP BY ob.seller_id HAVING COUNT(*) >= 30),
m AS (SELECT SUM(is_bad_review)/SUM(review_score IS NOT NULL) AS mkt_bad_rate FROM v_order_base WHERE seller_id IS NOT NULL),
r AS (SELECT s.*, NTILE(10) OVER (ORDER BY revenue) AS revenue_decile FROM s)
SELECT r.seller_id, r.seller_state, r.orders, ROUND(r.revenue,2) AS revenue_brl,
       ROUND(100*r.freight/(r.revenue+r.freight),2) AS freight_share_pct,
       ROUND(100*r.late_orders/r.orders,2) AS late_rate_pct,
       ROUND(100*r.seller_late_orders/r.orders,2) AS handover_late_rate_pct,
       ROUND(r.avg_review,2) AS avg_review,
       ROUND(100*r.bad_reviews/r.reviewed,2) AS bad_review_pct,
       ROUND(r.bad_reviews - r.reviewed*m.mkt_bad_rate,1) AS excess_bad_reviews_vs_market,
       r.revenue_decile,
       (r.revenue_decile = 10 AND r.bad_reviews/r.reviewed > m.mkt_bad_rate) AS flag_high_rev_hurts_ratings
FROM r CROSS JOIN m ORDER BY r.revenue DESC;

-- @out: results/04_seller_flagged.csv
WITH s AS (
  SELECT ob.seller_id, COUNT(*) AS orders, SUM(ob.item_revenue) AS revenue, SUM(ob.is_late) AS late_orders,
         SUM(ob.review_score IS NOT NULL) AS reviewed, AVG(ob.review_score) AS avg_review, SUM(ob.is_bad_review) AS bad_reviews
  FROM v_order_base ob WHERE ob.seller_id IS NOT NULL GROUP BY ob.seller_id HAVING COUNT(*) >= 30),
m AS (SELECT SUM(is_bad_review)/SUM(review_score IS NOT NULL) AS mkt_bad_rate FROM v_order_base WHERE seller_id IS NOT NULL),
r AS (SELECT s.*, NTILE(10) OVER (ORDER BY revenue) AS revenue_decile FROM s)
SELECT r.seller_id, r.orders, ROUND(r.revenue,2) AS revenue_brl, ROUND(100*r.late_orders/r.orders,2) AS late_rate_pct,
       ROUND(r.avg_review,2) AS avg_review, ROUND(100*r.bad_reviews/r.reviewed,2) AS bad_review_pct,
       ROUND(r.bad_reviews - r.reviewed*m.mkt_bad_rate,1) AS excess_bad_reviews_vs_market
FROM r CROSS JOIN m WHERE r.revenue_decile = 10 AND r.bad_reviews/r.reviewed > m.mkt_bad_rate
ORDER BY excess_bad_reviews_vs_market DESC;
