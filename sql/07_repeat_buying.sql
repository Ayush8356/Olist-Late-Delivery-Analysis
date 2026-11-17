-- 07_repeat_buying.sql : ONE question. How many customers come back, and does the first-order experience move it?
-- Person = customer_unique_id. Cohort = customers whose FIRST delivered order is in v_order_base and was delivered on/before
-- 2018-03-04, so every cohort member had a full 180 days to return before the 2018-09-01 data cut-off (no right-censoring).
-- Repeat = a later order (status not canceled/unavailable) purchased AFTER the first order was delivered, within 180 days of that delivery.

-- @out: results/07_repeat_overall.csv
SELECT COUNT(DISTINCT c.customer_unique_id) AS unique_customers,
       SUM(n.n_orders >= 2) AS customers_with_2plus_delivered_orders_all_time,
       ROUND(100*SUM(n.n_orders >= 2)/COUNT(*),2) AS repeat_pct_all_time
FROM (SELECT c.customer_unique_id, COUNT(*) AS n_orders FROM orders o JOIN customers c ON c.customer_id=o.customer_id
      WHERE o.order_status='delivered' GROUP BY c.customer_unique_id) n
JOIN (SELECT DISTINCT customer_unique_id FROM customers) c ON c.customer_unique_id = n.customer_unique_id;

-- @out: results/07_repeat_by_experience.csv
WITH f AS (
  SELECT customer_unique_id, order_id, pt, dd FROM (
    SELECT c.customer_unique_id, o.order_id, o.order_purchase_timestamp AS pt, o.order_delivered_customer_date AS dd,
           ROW_NUMBER() OVER (PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp, o.order_id) AS rn
    FROM orders o JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL) x WHERE rn = 1),
coh AS (
  SELECT f.customer_unique_id, f.dd, ob.is_late, ob.review_score,
         CASE WHEN ob.review_score IS NULL THEN 'no review' WHEN ob.review_score <= 2 THEN '1-2 stars'
              WHEN ob.review_score = 3 THEN '3 stars' ELSE '4-5 stars' END AS review_band,
         EXISTS (SELECT 1 FROM orders o2 JOIN customers c2 ON c2.customer_id = o2.customer_id
                 WHERE c2.customer_unique_id = f.customer_unique_id AND o2.order_id <> f.order_id
                   AND o2.order_status NOT IN ('canceled','unavailable')
                   AND o2.order_purchase_timestamp > f.dd
                   AND o2.order_purchase_timestamp <= DATE_ADD(f.dd, INTERVAL 180 DAY)) AS repeated
  FROM f JOIN v_order_base ob ON ob.order_id = f.order_id
  WHERE DATE(f.dd) <= '2018-03-04'),
g AS (
  SELECT 'all cohort' AS grp, COUNT(*) n, SUM(repeated) r FROM coh
  UNION ALL SELECT CONCAT('delivery: ', IF(is_late=1,'late','on time')), COUNT(*), SUM(repeated) FROM coh GROUP BY is_late
  UNION ALL SELECT CONCAT('review: ', review_band), COUNT(*), SUM(repeated) FROM coh GROUP BY review_band)
SELECT grp, n AS customers, r AS repeaters, ROUND(100*r/n,2) AS repeat_pct_180d,
       ROUND(100*((r/n + 3.8416/(2*n)) - 1.96*SQRT((r/n)*(1-r/n)/n + 3.8416/(4*n*n)))/(1+3.8416/n),2) AS ci95_low_pct,
       ROUND(100*((r/n + 3.8416/(2*n)) + 1.96*SQRT((r/n)*(1-r/n)/n + 3.8416/(4*n*n)))/(1+3.8416/n),2) AS ci95_high_pct
FROM g ORDER BY FIELD(LEFT(grp,3),'all','del','rev'), grp;
