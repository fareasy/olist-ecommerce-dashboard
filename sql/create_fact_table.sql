-- Olist Dashboard Fact Table View
-- PostgreSQL SQL Script
-- Creates a view aggregating order items, payments, reviews, delivery metrics, and customer/seller info
-- Exports the view to CSV

-- Drop view if it exists
DROP VIEW IF EXISTS vw_fact_order_items;

-- Create the fact order items view
CREATE VIEW vw_fact_order_items AS

WITH payment_agg AS (
    -- Aggregate total payment value per order
    SELECT 
        order_id,
        SUM(payment_value) AS order_payment_value
    FROM olist_order_payments
    GROUP BY order_id
),

review_agg AS (
    -- Aggregate average review score per order
    SELECT
        order_id,
        AVG(review_score) AS review_score
    FROM olist_order_reviews
    GROUP BY order_id
)

SELECT
    oi.order_id,
    oi.order_item_id,
    
    -- Customer unique identifier
    c.customer_unique_id,

    oi.product_id,
    prod.product_category_name,
    oi.seller_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    
    -- Item-level revenue
    oi.price,
    oi.freight_value,
    (oi.price + oi.freight_value) AS item_revenue,

    -- Order-level payment (not allocated to items)
    pay.order_payment_value,

    -- Delivery days as integer
    CASE 
        WHEN o.order_delivered_customer_date IS NOT NULL
        THEN DATE(o.order_delivered_customer_date) - DATE(o.order_purchase_timestamp)
        ELSE NULL
    END AS delivery_days,

    -- Late delivery flag
    CASE 
        WHEN o.order_delivered_customer_date IS NOT NULL
             AND o.order_delivered_customer_date > o.order_estimated_delivery_date 
        THEN 1 
        ELSE 0 
    END AS is_late,

    -- Delivery delay in days
    CASE 
        WHEN o.order_delivered_customer_date IS NOT NULL
             AND o.order_delivered_customer_date > o.order_estimated_delivery_date
        THEN DATE(o.order_delivered_customer_date) - DATE(o.order_estimated_delivery_date)
        ELSE 0
    END AS delivery_delay_days,

    r.review_score,
    c.customer_state,
    s.seller_state

FROM olist_order_items oi
JOIN olist_orders o 
    ON oi.order_id = o.order_id
JOIN olist_order_customer c 
    ON o.customer_id = c.customer_id
JOIN olist_sellers s 
    ON oi.seller_id = s.seller_id
LEFT JOIN olist_products prod
    ON oi.product_id = prod.product_id
LEFT JOIN review_agg r 
    ON o.order_id = r.order_id
LEFT JOIN payment_agg pay
    ON o.order_id = pay.order_id;

-- ==================================================
-- Export the view to CSV
-- Change the directory target here (example: D drive folder)
-- ==================================================
\copy (
    SELECT * FROM vw_fact_order_items
) TO 'vw_fact_order_items.csv' CSV HEADER;
