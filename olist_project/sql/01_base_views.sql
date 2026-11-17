-- 01_base_views.sql : analysis base. Every number in results/ is built on these views.
-- Rules (see docs/DECISIONS.md): delivered orders only, purchase window 2017-01-01..2018-08-31,
-- delay = DATE(delivered) - DATE(estimated), revenue = SUM(price), freight kept separate,
-- one review per order (latest answer), customer_unique_id for people.

DROP VIEW IF EXISTS v_order_base;
DROP VIEW IF EXISTS v_item_base;
DROP VIEW IF EXISTS v_review_one;

-- one review per order: latest answer wins (547 orders have >1 review)
CREATE VIEW v_review_one AS
SELECT order_id, review_score
FROM (SELECT order_id, review_score,
             ROW_NUMBER() OVER (PARTITION BY order_id
                                ORDER BY review_answer_timestamp DESC, review_creation_date DESC, review_id) AS rn
      FROM order_reviews) x
WHERE rn = 1;

-- ORDER grain: one row per delivered order in the window (items present)
CREATE VIEW v_order_base AS
WITH it AS (
  SELECT i.order_id,
         COUNT(DISTINCT i.seller_id)                                   AS n_sellers,
         MIN(i.seller_id)                                              AS any_seller_id,
         SUM(i.price)                                                  AS item_revenue,
         SUM(i.freight_value)                                          AS freight,
         COUNT(*)                                                      AS n_items,
         MIN(i.shipping_limit_date)                                    AS min_ship_limit,
         COUNT(DISTINCT COALESCE(ct.product_category_name_english,'unknown')) AS n_categories,
         MIN(COALESCE(ct.product_category_name_english,'unknown'))     AS any_category
  FROM order_items i
  LEFT JOIN products p            ON p.product_id = i.product_id
  LEFT JOIN category_translation ct ON ct.product_category_name = p.product_category_name
  GROUP BY i.order_id
),
b AS (
  SELECT o.order_id, c.customer_unique_id, c.customer_state,
         o.order_purchase_timestamp, o.order_delivered_carrier_date, o.order_delivered_customer_date,
         it.n_sellers, it.n_items,
         IF(it.n_sellers = 1, it.any_seller_id, NULL)                  AS seller_id,
         IF(it.n_categories = 1, it.any_category, 'multiple')          AS category,
         it.item_revenue, it.freight, it.min_ship_limit,
         r.review_score,
         DATEDIFF(DATE(o.order_delivered_customer_date), DATE(o.order_estimated_delivery_date)) AS delay_days,
         IF(it.n_sellers = 1 AND o.order_delivered_carrier_date IS NOT NULL,
            GREATEST(DATEDIFF(DATE(o.order_delivered_carrier_date), DATE(it.min_ship_limit)), 0), NULL) AS seller_overrun_days
  FROM orders o
  JOIN customers c ON c.customer_id = o.customer_id
  JOIN it          ON it.order_id = o.order_id
  LEFT JOIN v_review_one r ON r.order_id = o.order_id
  WHERE o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
    AND o.order_purchase_timestamp >= '2017-01-01'
    AND o.order_purchase_timestamp <  '2018-09-01'
)
SELECT b.*,
  DATE_FORMAT(order_purchase_timestamp, '%Y-%m')                       AS purchase_month,
  (delay_days > 0)                                                     AS is_late,
  (review_score <= 2)                                                  AS is_bad_review,
  CASE WHEN delay_days <= 0 THEN 'on_time'
       WHEN delay_days <= 3 THEN '1-3'
       WHEN delay_days <= 9 THEN '4-9'
       ELSE '10+' END                                                  AS delay_bucket,
  -- attribution of lateness (late orders only). Assumes a day of handover delay = a day of delivery delay.
  CASE WHEN delay_days <= 0               THEN NULL
       WHEN n_sellers <> 1                THEN 'excluded_multi_seller'
       WHEN seller_overrun_days IS NULL   THEN 'excluded_no_carrier_date'
       WHEN seller_overrun_days = 0       THEN 'logistics_only'
       WHEN seller_overrun_days >= delay_days THEN 'seller_only'
       ELSE 'both' END                                                 AS delay_class
FROM b;

-- ITEM grain: for category / seller / freight work. Order-level fields repeated per item.
CREATE VIEW v_item_base AS
SELECT i.order_id, i.order_item_id, i.seller_id, s.seller_state,
       COALESCE(ct.product_category_name_english, 'unknown') AS category,
       i.price, i.freight_value, ob.customer_state, ob.purchase_month,
       ob.is_late, ob.review_score, ob.is_bad_review, ob.delay_days
FROM order_items i
JOIN v_order_base ob ON ob.order_id = i.order_id
JOIN sellers s       ON s.seller_id = i.seller_id
LEFT JOIN products p ON p.product_id = i.product_id
LEFT JOIN category_translation ct ON ct.product_category_name = p.product_category_name;
