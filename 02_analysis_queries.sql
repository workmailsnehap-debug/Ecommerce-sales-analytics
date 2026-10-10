-- MySQL 8.x - Business analysis queries
-- Revenue only counts DELIVERED orders (returned/cancelled are excluded).
USE ecommerce_analytics;

-- 1. Headline KPIs ---------------------------------------------------------
SELECT
    COUNT(*)                                             AS delivered_orders,
    ROUND(SUM(sales_amount), 2)                          AS total_revenue,
    ROUND(SUM(profit), 2)                                AS total_profit,
    ROUND(SUM(profit) / SUM(sales_amount) * 100, 2)      AS profit_margin_pct,
    ROUND(AVG(sales_amount), 2)                          AS avg_order_value
FROM sales
WHERE order_status = 'Delivered';

-- 2. Monthly revenue + month-over-month growth -----------------------------
WITH monthly AS (
    SELECT ym, SUM(sales_amount) AS revenue
    FROM sales
    WHERE order_status = 'Delivered'
    GROUP BY ym
)
SELECT ym,
       ROUND(revenue, 2) AS revenue,
       ROUND((revenue - LAG(revenue) OVER (ORDER BY ym))
             / LAG(revenue) OVER (ORDER BY ym) * 100, 2) AS mom_growth_pct
FROM monthly
ORDER BY ym;

-- 3. Revenue, profit and margin by category --------------------------------
SELECT category,
       ROUND(SUM(sales_amount), 2)                     AS revenue,
       ROUND(SUM(profit), 2)                           AS profit,
       ROUND(SUM(profit) / SUM(sales_amount) * 100, 2) AS margin_pct
FROM sales
WHERE order_status = 'Delivered'
GROUP BY category
ORDER BY revenue DESC;

-- 4. Top 10 products by revenue ---------------------------------------------
SELECT product_name, category,
       SUM(quantity)                AS units_sold,
       ROUND(SUM(sales_amount), 2)  AS revenue
FROM sales
WHERE order_status = 'Delivered'
GROUP BY product_name, category
ORDER BY revenue DESC
LIMIT 10;

-- 5. Best-selling product inside each category (window function) -----------
SELECT category, product_name, revenue
FROM (
    SELECT category, product_name,
           ROUND(SUM(sales_amount), 2) AS revenue,
           RANK() OVER (PARTITION BY category ORDER BY SUM(sales_amount) DESC) AS rnk
    FROM sales
    WHERE order_status = 'Delivered'
    GROUP BY category, product_name
) t
WHERE rnk = 1;

-- 6. Revenue by city ---------------------------------------------------------
SELECT city, ROUND(SUM(sales_amount), 2) AS revenue, COUNT(*) AS orders
FROM sales
WHERE order_status = 'Delivered'
GROUP BY city
ORDER BY revenue DESC;

-- 7. Payment method mix -------------------------------------------------------
SELECT payment_method,
       COUNT(*) AS orders,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_orders
FROM sales
GROUP BY payment_method
ORDER BY orders DESC;

-- 8. Does discounting hurt profit? -------------------------------------------
SELECT discount_pct,
       COUNT(*)                                        AS orders,
       ROUND(SUM(sales_amount), 2)                     AS revenue,
       ROUND(SUM(profit) / SUM(sales_amount) * 100, 2) AS margin_pct
FROM sales
WHERE order_status = 'Delivered'
GROUP BY discount_pct
ORDER BY discount_pct;

-- 9. Return and cancellation rate by category ---------------------------------
SELECT category,
       ROUND(SUM(order_status = 'Returned')  * 100.0 / COUNT(*), 2) AS return_rate_pct,
       ROUND(SUM(order_status = 'Cancelled') * 100.0 / COUNT(*), 2) AS cancel_rate_pct
FROM sales
GROUP BY category
ORDER BY return_rate_pct DESC;

-- 10. Customer value: top 10 customers by revenue -----------------------------
SELECT customer_id, city, segment,
       COUNT(*) AS orders,
       ROUND(SUM(sales_amount), 2) AS lifetime_revenue
FROM sales
WHERE order_status = 'Delivered'
GROUP BY customer_id, city, segment
ORDER BY lifetime_revenue DESC
LIMIT 10;

-- 11. Repeat vs one-time customers ---------------------------------------------
SELECT CASE WHEN orders > 1 THEN 'Repeat' ELSE 'One-time' END AS customer_type,
       COUNT(*) AS customers
FROM (
    SELECT customer_id, COUNT(*) AS orders
    FROM sales
    WHERE order_status = 'Delivered'
    GROUP BY customer_id
) c
GROUP BY customer_type;

-- 12. Festive-season effect: revenue share by month number ----------------------
SELECT month, month_name,
       ROUND(SUM(sales_amount), 2) AS revenue,
       ROUND(SUM(sales_amount) * 100.0 / SUM(SUM(sales_amount)) OVER (), 2) AS pct_of_total
FROM sales
WHERE order_status = 'Delivered'
GROUP BY month, month_name
ORDER BY month;
