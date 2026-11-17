-- 05_freight_burden.sql : freight burden by category and customer state. NOT profitability (no cost data).
-- Item grain on delivered orders in the window. ratio = SUM(freight) / SUM(price).

-- @out: results/05_freight_by_category.csv
SELECT category, COUNT(*) AS items, COUNT(DISTINCT order_id) AS orders,
       ROUND(SUM(price),2) AS revenue_brl, ROUND(SUM(freight_value),2) AS freight_brl,
       ROUND(SUM(freight_value)/SUM(price),3) AS freight_to_price_ratio,
       ROUND(100*SUM(freight_value)/(SUM(price)+SUM(freight_value)),2) AS freight_share_of_basket_pct,
       ROUND(AVG(price),2) AS avg_item_price,
       RANK() OVER (ORDER BY SUM(freight_value)/SUM(price) DESC) AS burden_rank
FROM v_item_base GROUP BY category HAVING COUNT(*) >= 200
ORDER BY freight_to_price_ratio DESC;

-- @out: results/05_freight_by_state.csv
SELECT customer_state, COUNT(*) AS items, COUNT(DISTINCT order_id) AS orders,
       ROUND(SUM(price),2) AS revenue_brl, ROUND(SUM(freight_value),2) AS freight_brl,
       ROUND(SUM(freight_value)/SUM(price),3) AS freight_to_price_ratio,
       ROUND(100*SUM(freight_value)/(SUM(price)+SUM(freight_value)),2) AS freight_share_of_basket_pct,
       ROUND(100*COUNT(DISTINCT CASE WHEN is_late=1 THEN order_id END)/COUNT(DISTINCT order_id),2) AS late_pct
FROM v_item_base GROUP BY customer_state HAVING COUNT(*) >= 200
ORDER BY freight_to_price_ratio DESC;
