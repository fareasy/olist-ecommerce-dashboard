-- =========================================
-- Olist E-Commerce Database Schema
-- PostgreSQL SQL Script
-- This script creates tables for Olist Orders, Customers, Products, Sellers, Payments, Reviews, and Geolocation.
-- =========================================

-- 1. Create Olist Order Customer Table
-- Stores customer information
CREATE TABLE olist_order_customer (
    customer_id VARCHAR(32) PRIMARY KEY,
    customer_unique_id VARCHAR(32) NOT NULL,
    customer_zip_code_prefix INTEGER NOT NULL,
    customer_city TEXT,
    customer_state VARCHAR(2)
);

-- 2. Create Olist Orders Table
-- Stores order information linked to customers
CREATE TABLE olist_orders (
    order_id VARCHAR(32) PRIMARY KEY,
    customer_id VARCHAR(32) NOT NULL,
    order_status VARCHAR(20) NOT NULL
        CHECK (order_status IN (
            'created','approved','processing','shipped',
            'delivered','invoiced','canceled','unavailable'
        )),
    order_purchase_timestamp TIMESTAMP NOT NULL,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,

    -- Foreign key to customers
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES olist_order_customer(customer_id)
);

-- 3. Create Olist Order Reviews Table
-- Stores reviews for each order
CREATE TABLE olist_order_reviews (
    review_id VARCHAR(32) PRIMARY KEY,
    order_id VARCHAR(32) NOT NULL,
    review_score SMALLINT CHECK (review_score BETWEEN 1 AND 5),
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP,

    -- Foreign key to orders
    CONSTRAINT fk_reviews_order
        FOREIGN KEY (order_id)
        REFERENCES olist_orders(order_id)
);

-- 4. Create Olist Order Payments Table
-- Stores multiple payment methods for each order
CREATE TABLE olist_order_payments (
    order_id VARCHAR(32) NOT NULL,
    payment_sequential SMALLINT NOT NULL,
    payment_type VARCHAR(20) NOT NULL
        CHECK (payment_type IN (
            'credit_card','debit_card','voucher','boleto','not_defined'
        )),
    payment_installments SMALLINT,
    payment_value NUMERIC(10,2),

    -- Composite primary key for multiple payments per order
    CONSTRAINT olist_order_payments_pkey
        PRIMARY KEY (order_id, payment_sequential),

    -- Foreign key to orders
    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id)
        REFERENCES olist_orders(order_id)
);

-- 5. Create Olist Geolocation Table
-- Stores latitude/longitude for ZIP codes
CREATE TABLE olist_geolocation (
    geolocation_zip_code_prefix INTEGER,
    geolocation_lat DOUBLE PRECISION,
    geolocation_lng DOUBLE PRECISION,
    geolocation_city TEXT,
    geolocation_state VARCHAR(2)
);

-- Aggregate unique geolocation per ZIP code
SELECT 
    geolocation_zip_code_prefix,
    AVG(geolocation_lat) AS avg_lat,
    AVG(geolocation_lng) AS avg_lng,
    MODE() WITHIN GROUP (ORDER BY geolocation_city) AS geolocation_city,
    MODE() WITHIN GROUP (ORDER BY geolocation_state) AS geolocation_state
INTO olist_geolocation_unique
FROM olist_geolocation
GROUP BY geolocation_zip_code_prefix
ORDER BY geolocation_zip_code_prefix;

-- Add missing ZIP codes from customers
INSERT INTO olist_geolocation_unique (geolocation_zip_code_prefix)
SELECT DISTINCT customer_zip_code_prefix
FROM olist_order_customer c
LEFT JOIN olist_geolocation_unique g
  ON c.customer_zip_code_prefix = g.geolocation_zip_code_prefix
WHERE g.geolocation_zip_code_prefix IS NULL;

-- Add missing ZIP codes from sellers
INSERT INTO olist_geolocation_unique (geolocation_zip_code_prefix)
SELECT DISTINCT seller_zip_code_prefix
FROM olist_sellers s
WHERE NOT EXISTS (
    SELECT 1
    FROM olist_geolocation_unique g
    WHERE g.geolocation_zip_code_prefix = s.seller_zip_code_prefix
);

-- Add primary key
ALTER TABLE olist_geolocation_unique
ADD CONSTRAINT olist_geolocation_pkey
PRIMARY KEY (geolocation_zip_code_prefix);

-- Add foreign key from customers to geolocation
ALTER TABLE olist_order_customer
ADD CONSTRAINT fk_geolocation_customer
FOREIGN KEY (customer_zip_code_prefix)
REFERENCES olist_geolocation_unique(geolocation_zip_code_prefix);

-- 6. Create Olist Sellers Table
-- Stores seller information
CREATE TABLE olist_sellers (
    seller_id VARCHAR(32) PRIMARY KEY,
    seller_zip_code_prefix INTEGER,
    seller_city TEXT,
    seller_state VARCHAR(2),

    -- Foreign key to geolocation
    CONSTRAINT fk_geolocation_sellers
        FOREIGN KEY (seller_zip_code_prefix)
        REFERENCES olist_geolocation_unique(geolocation_zip_code_prefix)
);

-- 7. Create Olist Products Table
-- Stores product information
CREATE TABLE olist_products (
    product_id VARCHAR(32) PRIMARY KEY,
    product_category_name TEXT,
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

-- 8. Create Olist Order Items Table
-- Stores details of products in each order
CREATE TABLE olist_order_items (
    order_id VARCHAR(32) NOT NULL,
    order_item_id INT NOT NULL,
    product_id VARCHAR(32) NOT NULL,
    seller_id VARCHAR(32) NOT NULL,
    shipping_limit_date TIMESTAMP,
    price NUMERIC(10,2),
    freight_value NUMERIC(10,2),

    -- Composite primary key for order items
    CONSTRAINT olist_order_items_pkey
        PRIMARY KEY (order_id, order_item_id),

    -- Foreign keys
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES olist_orders(order_id),

    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES olist_products(product_id),

    CONSTRAINT fk_order_items_seller
        FOREIGN KEY (seller_id)
        REFERENCES olist_sellers(seller_id)
);
