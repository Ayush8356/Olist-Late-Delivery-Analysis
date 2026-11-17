-- Olist schema. MySQL 8.0. Run: mysql olist < sql/00_schema.sql ; then load with 00b_load.sql
DROP TABLE IF EXISTS geolocation, order_payments, order_reviews, order_items, orders,
                     customers, products, sellers, category_translation;

CREATE TABLE customers (
  customer_id VARCHAR(32) PRIMARY KEY,
  customer_unique_id VARCHAR(32) NOT NULL,
  customer_zip_code_prefix VARCHAR(5), customer_city VARCHAR(64), customer_state CHAR(2),
  KEY (customer_unique_id));

CREATE TABLE orders (
  order_id VARCHAR(32) PRIMARY KEY, customer_id VARCHAR(32), order_status VARCHAR(16),
  order_purchase_timestamp DATETIME, order_approved_at DATETIME,
  order_delivered_carrier_date DATETIME, order_delivered_customer_date DATETIME,
  order_estimated_delivery_date DATETIME,
  KEY (customer_id), KEY (order_purchase_timestamp));

CREATE TABLE order_items (
  order_id VARCHAR(32), order_item_id INT, product_id VARCHAR(32), seller_id VARCHAR(32),
  shipping_limit_date DATETIME, price DECIMAL(10,2), freight_value DECIMAL(10,2),
  PRIMARY KEY (order_id, order_item_id), KEY (seller_id), KEY (product_id));

CREATE TABLE order_payments (
  order_id VARCHAR(32), payment_sequential INT, payment_type VARCHAR(20),
  payment_installments INT, payment_value DECIMAL(10,2),
  PRIMARY KEY (order_id, payment_sequential));

-- review_id is NOT unique in the source (same review_id appears on several orders)
CREATE TABLE order_reviews (
  review_id VARCHAR(32), order_id VARCHAR(32), review_score TINYINT,
  review_comment_title TEXT, review_comment_message TEXT,
  review_creation_date DATETIME, review_answer_timestamp DATETIME,
  KEY (order_id));

CREATE TABLE products (
  product_id VARCHAR(32) PRIMARY KEY, product_category_name VARCHAR(64),
  product_name_lenght INT, product_description_lenght INT, product_photos_qty INT,
  product_weight_g INT, product_length_cm INT, product_height_cm INT, product_width_cm INT);

CREATE TABLE sellers (
  seller_id VARCHAR(32) PRIMARY KEY, seller_zip_code_prefix VARCHAR(5),
  seller_city VARCHAR(64), seller_state CHAR(2));

CREATE TABLE category_translation (
  product_category_name VARCHAR(64) PRIMARY KEY, product_category_name_english VARCHAR(64));

CREATE TABLE geolocation (
  geolocation_zip_code_prefix VARCHAR(5), geolocation_lat DOUBLE, geolocation_lng DOUBLE,
  geolocation_city VARCHAR(64), geolocation_state CHAR(2));
