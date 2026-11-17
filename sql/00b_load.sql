-- Load CSVs (empty string -> NULL). Edit the paths if your CSVs live elsewhere.
-- Reviews and category-translation CSVs use CRLF line endings, so their last column is trimmed of '\r'.
-- Run: mysql --local-infile=1 olist < sql/00b_load.sql

LOAD DATA LOCAL INFILE '/mnt/user-data/uploads/olist_customers_dataset.csv' INTO TABLE customers
  CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '' LINES TERMINATED BY '\n' IGNORE 1 LINES
  (@customer_id, @customer_unique_id, @customer_zip_code_prefix, @customer_city, @customer_state)
  SET customer_id=NULLIF(@customer_id,''), customer_unique_id=NULLIF(@customer_unique_id,''), customer_zip_code_prefix=NULLIF(@customer_zip_code_prefix,''), customer_city=NULLIF(@customer_city,''), customer_state=NULLIF(@customer_state,'');

LOAD DATA LOCAL INFILE '/mnt/user-data/uploads/olist_orders_dataset.csv' INTO TABLE orders
  CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '' LINES TERMINATED BY '\n' IGNORE 1 LINES
  (@order_id, @customer_id, @order_status, @order_purchase_timestamp, @order_approved_at, @order_delivered_carrier_date, @order_delivered_customer_date, @order_estimated_delivery_date)
  SET order_id=NULLIF(@order_id,''), customer_id=NULLIF(@customer_id,''), order_status=NULLIF(@order_status,''), order_purchase_timestamp=NULLIF(@order_purchase_timestamp,''), order_approved_at=NULLIF(@order_approved_at,''), order_delivered_carrier_date=NULLIF(@order_delivered_carrier_date,''), order_delivered_customer_date=NULLIF(@order_delivered_customer_date,''), order_estimated_delivery_date=NULLIF(@order_estimated_delivery_date,'');

LOAD DATA LOCAL INFILE '/mnt/user-data/uploads/olist_order_items_dataset.csv' INTO TABLE order_items
  CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '' LINES TERMINATED BY '\n' IGNORE 1 LINES
  (@order_id, @order_item_id, @product_id, @seller_id, @shipping_limit_date, @price, @freight_value)
  SET order_id=NULLIF(@order_id,''), order_item_id=NULLIF(@order_item_id,''), product_id=NULLIF(@product_id,''), seller_id=NULLIF(@seller_id,''), shipping_limit_date=NULLIF(@shipping_limit_date,''), price=NULLIF(@price,''), freight_value=NULLIF(@freight_value,'');

LOAD DATA LOCAL INFILE '/mnt/user-data/uploads/olist_order_payments_dataset.csv' INTO TABLE order_payments
  CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '' LINES TERMINATED BY '\n' IGNORE 1 LINES
  (@order_id, @payment_sequential, @payment_type, @payment_installments, @payment_value)
  SET order_id=NULLIF(@order_id,''), payment_sequential=NULLIF(@payment_sequential,''), payment_type=NULLIF(@payment_type,''), payment_installments=NULLIF(@payment_installments,''), payment_value=NULLIF(@payment_value,'');

LOAD DATA LOCAL INFILE '/mnt/user-data/uploads/olist_order_reviews_dataset.csv' INTO TABLE order_reviews
  CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '' LINES TERMINATED BY '\n' IGNORE 1 LINES
  (@review_id, @order_id, @review_score, @review_comment_title, @review_comment_message, @review_creation_date, @review_answer_timestamp)
  SET review_id=NULLIF(@review_id,''), order_id=NULLIF(@order_id,''), review_score=NULLIF(@review_score,''), review_comment_title=NULLIF(@review_comment_title,''), review_comment_message=NULLIF(@review_comment_message,''), review_creation_date=NULLIF(@review_creation_date,''), review_answer_timestamp=NULLIF(TRIM(TRAILING '\r' FROM @review_answer_timestamp),'');

LOAD DATA LOCAL INFILE '/mnt/user-data/uploads/olist_products_dataset.csv' INTO TABLE products
  CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '' LINES TERMINATED BY '\n' IGNORE 1 LINES
  (@product_id, @product_category_name, @product_name_lenght, @product_description_lenght, @product_photos_qty, @product_weight_g, @product_length_cm, @product_height_cm, @product_width_cm)
  SET product_id=NULLIF(@product_id,''), product_category_name=NULLIF(@product_category_name,''), product_name_lenght=NULLIF(@product_name_lenght,''), product_description_lenght=NULLIF(@product_description_lenght,''), product_photos_qty=NULLIF(@product_photos_qty,''), product_weight_g=NULLIF(@product_weight_g,''), product_length_cm=NULLIF(@product_length_cm,''), product_height_cm=NULLIF(@product_height_cm,''), product_width_cm=NULLIF(@product_width_cm,'');

LOAD DATA LOCAL INFILE '/mnt/user-data/uploads/olist_sellers_dataset.csv' INTO TABLE sellers
  CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '' LINES TERMINATED BY '\n' IGNORE 1 LINES
  (@seller_id, @seller_zip_code_prefix, @seller_city, @seller_state)
  SET seller_id=NULLIF(@seller_id,''), seller_zip_code_prefix=NULLIF(@seller_zip_code_prefix,''), seller_city=NULLIF(@seller_city,''), seller_state=NULLIF(@seller_state,'');

LOAD DATA LOCAL INFILE '/mnt/user-data/uploads/product_category_name_translation.csv' INTO TABLE category_translation
  CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '' LINES TERMINATED BY '\n' IGNORE 1 LINES
  (@product_category_name, @product_category_name_english)
  SET product_category_name=NULLIF(@product_category_name,''), product_category_name_english=NULLIF(TRIM(TRAILING '\r' FROM @product_category_name_english),'');

LOAD DATA LOCAL INFILE '/mnt/user-data/uploads/olist_geolocation_dataset.csv' INTO TABLE geolocation
  CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '' LINES TERMINATED BY '\n' IGNORE 1 LINES
  (@geolocation_zip_code_prefix, @geolocation_lat, @geolocation_lng, @geolocation_city, @geolocation_state)
  SET geolocation_zip_code_prefix=NULLIF(@geolocation_zip_code_prefix,''), geolocation_lat=NULLIF(@geolocation_lat,''), geolocation_lng=NULLIF(@geolocation_lng,''), geolocation_city=NULLIF(@geolocation_city,''), geolocation_state=NULLIF(@geolocation_state,'');
