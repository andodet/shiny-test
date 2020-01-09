library(dplyr)

print("Importing data...")
sales_raw <- readRDS("app/data/sales_raw.rds")

print("Formatting data...")
sales_raw <- sales_raw %>% 
  mutate(order_purchase_timestamp = as.Date(order_purchase_timestamp),
         order_approved_at = as.Date(order_approved_at),
         order_delivered_carrier_date = as.Date(order_delivered_carrier_date),
         order_delivered_customer_date = as.Date(order_delivered_customer_date),
         order_estimated_delivery_date = as.Date(order_estimated_delivery_date),
         shipping_limit_date = as.Date(shipping_limit_date),
         year_month = as.factor(strftime(order_purchase_timestamp, "%Y-%m")),
         year_week = as.factor(strftime(order_purchase_timestamp, "%Y-%W")))

# Aggregate data
print("Aggregating data...")
sales_agg <- sales_raw %>% 
  group_by(customer_id, order_id, order_status, order_purchase_timestamp, order_approved_at, 
           order_delivered_carrier_date, order_delivered_customer_date, payment_type, customer_city,
           customer_state, customer_zip_code_prefix, year_month, year_week, product_category_name) %>% 
  summarise(tot_payment_value = sum(payment_value),
            tot_price = sum(price),
            tot_freight_value = sum(freight_value),
            tot_items = n_distinct(product_id),
            avg_item_price = tot_price / tot_items) %>% 
  ungroup() %>% 
  mutate(approval_time = as.numeric(order_approved_at - order_purchase_timestamp),
         delivery_process_time = as.numeric(order_delivered_carrier_date - order_approved_at),
         delivery_time = as.numeric(order_delivered_customer_date - order_delivered_carrier_date))

print("Exporting data...")
saveRDS(sales_agg, "app/data/sales_agg.rds")