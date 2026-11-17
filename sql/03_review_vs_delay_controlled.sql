-- 03_review_vs_delay_controlled.sql : is the late-vs-on-time review gap still there after holding state / category / seller fixed?
-- Method: within each stratum compare bad-review rate (score<=2) late vs on-time, then average the gaps weighted by
-- each stratum's late-order count (standardises to the late-order mix). Strata with too few orders on either side are dropped.
-- Association, not causation. A joint regression with all controls is in notebooks/03_controlled_regression.py.

-- @out: results/03a_state_strata.csv
WITH g AS (
  SELECT customer_state AS stratum, SUM(is_late) AS late_n, SUM(1-is_late) AS ontime_n,
         AVG(CASE WHEN is_late=1 THEN is_bad_review END) AS late_bad, AVG(CASE WHEN is_late=0 THEN is_bad_review END) AS ontime_bad,
         AVG(CASE WHEN is_late=1 THEN review_score END)  AS late_avg, AVG(CASE WHEN is_late=0 THEN review_score END)  AS ontime_avg
  FROM v_order_base WHERE review_score IS NOT NULL AND 1=1 GROUP BY customer_state)
SELECT stratum, late_n AS late_reviewed, ontime_n AS ontime_reviewed,
       ROUND(100*late_bad,2) AS late_bad_pct, ROUND(100*ontime_bad,2) AS ontime_bad_pct,
       ROUND(100*(late_bad-ontime_bad),2) AS bad_gap_pp, ROUND(late_avg-ontime_avg,2) AS avg_score_gap
FROM g WHERE late_n >= 20 AND ontime_n >= 20 ORDER BY late_n DESC;

-- @out: results/03b_category_strata.csv
WITH g AS (
  SELECT category AS stratum, SUM(is_late) AS late_n, SUM(1-is_late) AS ontime_n,
         AVG(CASE WHEN is_late=1 THEN is_bad_review END) AS late_bad, AVG(CASE WHEN is_late=0 THEN is_bad_review END) AS ontime_bad,
         AVG(CASE WHEN is_late=1 THEN review_score END)  AS late_avg, AVG(CASE WHEN is_late=0 THEN review_score END)  AS ontime_avg
  FROM v_order_base WHERE review_score IS NOT NULL AND category <> 'multiple' GROUP BY category)
SELECT stratum, late_n AS late_reviewed, ontime_n AS ontime_reviewed,
       ROUND(100*late_bad,2) AS late_bad_pct, ROUND(100*ontime_bad,2) AS ontime_bad_pct,
       ROUND(100*(late_bad-ontime_bad),2) AS bad_gap_pp, ROUND(late_avg-ontime_avg,2) AS avg_score_gap
FROM g WHERE late_n >= 20 AND ontime_n >= 20 ORDER BY late_n DESC;

-- @out: results/03c_seller_strata.csv
WITH g AS (
  SELECT seller_id AS stratum, SUM(is_late) AS late_n, SUM(1-is_late) AS ontime_n,
         AVG(CASE WHEN is_late=1 THEN is_bad_review END) AS late_bad, AVG(CASE WHEN is_late=0 THEN is_bad_review END) AS ontime_bad,
         AVG(CASE WHEN is_late=1 THEN review_score END)  AS late_avg, AVG(CASE WHEN is_late=0 THEN review_score END)  AS ontime_avg
  FROM v_order_base WHERE review_score IS NOT NULL AND seller_id IS NOT NULL GROUP BY seller_id)
SELECT stratum, late_n AS late_reviewed, ontime_n AS ontime_reviewed,
       ROUND(100*late_bad,2) AS late_bad_pct, ROUND(100*ontime_bad,2) AS ontime_bad_pct,
       ROUND(100*(late_bad-ontime_bad),2) AS bad_gap_pp, ROUND(late_avg-ontime_avg,2) AS avg_score_gap
FROM g WHERE late_n >= 20 AND ontime_n >= 20 ORDER BY late_n DESC;

-- @out: results/03_controlled_summary.csv
WITH
gs AS (
  SELECT customer_state AS stratum, SUM(is_late) AS late_n, SUM(1-is_late) AS ontime_n,
         AVG(CASE WHEN is_late=1 THEN is_bad_review END) AS late_bad, AVG(CASE WHEN is_late=0 THEN is_bad_review END) AS ontime_bad,
         AVG(CASE WHEN is_late=1 THEN review_score END)  AS late_avg, AVG(CASE WHEN is_late=0 THEN review_score END)  AS ontime_avg
  FROM v_order_base WHERE review_score IS NOT NULL AND 1=1 GROUP BY customer_state),
gc AS (
  SELECT category AS stratum, SUM(is_late) AS late_n, SUM(1-is_late) AS ontime_n,
         AVG(CASE WHEN is_late=1 THEN is_bad_review END) AS late_bad, AVG(CASE WHEN is_late=0 THEN is_bad_review END) AS ontime_bad,
         AVG(CASE WHEN is_late=1 THEN review_score END)  AS late_avg, AVG(CASE WHEN is_late=0 THEN review_score END)  AS ontime_avg
  FROM v_order_base WHERE review_score IS NOT NULL AND category <> 'multiple' GROUP BY category),
gl AS (
  SELECT seller_id AS stratum, SUM(is_late) AS late_n, SUM(1-is_late) AS ontime_n,
         AVG(CASE WHEN is_late=1 THEN is_bad_review END) AS late_bad, AVG(CASE WHEN is_late=0 THEN is_bad_review END) AS ontime_bad,
         AVG(CASE WHEN is_late=1 THEN review_score END)  AS late_avg, AVG(CASE WHEN is_late=0 THEN review_score END)  AS ontime_avg
  FROM v_order_base WHERE review_score IS NOT NULL AND seller_id IS NOT NULL GROUP BY seller_id)
SELECT 'none (raw)' AS control, 1 AS n_strata, SUM(is_late) AS late_orders_covered, ROUND(100*(AVG(CASE WHEN is_late=1 THEN is_bad_review END)-AVG(CASE WHEN is_late=0 THEN is_bad_review END)),2) AS bad_gap_pp, ROUND(AVG(CASE WHEN is_late=1 THEN review_score END)-AVG(CASE WHEN is_late=0 THEN review_score END),2) AS avg_score_gap FROM v_order_base WHERE review_score IS NOT NULL
UNION ALL
SELECT 'customer_state' AS control, COUNT(*) AS n_strata, SUM(late_n) AS late_orders_covered,
       ROUND(100*SUM((late_bad-ontime_bad)*late_n)/SUM(late_n),2) AS bad_gap_pp,
       ROUND(SUM((late_avg-ontime_avg)*late_n)/SUM(late_n),2) AS avg_score_gap
FROM gs WHERE late_n >= 20 AND ontime_n >= 20
UNION ALL
SELECT 'category (single-category orders)' AS control, COUNT(*) AS n_strata, SUM(late_n) AS late_orders_covered,
       ROUND(100*SUM((late_bad-ontime_bad)*late_n)/SUM(late_n),2) AS bad_gap_pp,
       ROUND(SUM((late_avg-ontime_avg)*late_n)/SUM(late_n),2) AS avg_score_gap
FROM gc WHERE late_n >= 20 AND ontime_n >= 20
UNION ALL
SELECT 'seller (single-seller orders)' AS control, COUNT(*) AS n_strata, SUM(late_n) AS late_orders_covered,
       ROUND(100*SUM((late_bad-ontime_bad)*late_n)/SUM(late_n),2) AS bad_gap_pp,
       ROUND(SUM((late_avg-ontime_avg)*late_n)/SUM(late_n),2) AS avg_score_gap
FROM gl WHERE late_n >= 20 AND ontime_n >= 20;
