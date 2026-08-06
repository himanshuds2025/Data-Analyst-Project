-- This script is to create all the necessary tables for the star schema of this project.
-- simple difference between fact and dimension is that dimension is description upon which facts are built
-- (eg. customer is a dimension and order & payment is a fact.)


-- Dimension Table: Customer (SCD Type-2, simulated, data is static but im creating it assuming that this data will update)
Begin;
drop table if exists dim_customers CASCADE ;
create table dim_customers (
 customer_sk serial primary key,
 customer_id text not null,
 customer_unique_id text unique not null,
 zip_code_prefix text,
 city text,
 state text,
 valid_from Timestamptz not null,
 valid_to Timestamptz,
 is_current boolean default true
);

-- Dimension Table: Product
drop table if exists dim_products CASCADE;
create table dim_products(
	product_sk serial primary key,
	product_id text unique not null,
	category_name text,
	name_length int,
	description_length int,
	photos_qty int,
	weight_g int,
	length_cm int,
	height_cm int,
	width_cm int
	
);

-- Dimension Table: Seller
drop table if exists dim_sellers CASCADE;
create table dim_sellers(
	seller_sk serial primary key,
	seller_id text unique not null,
	zip_code_prefix text,
	city text,
	state text
);

-- Dimension Table: Date
drop table if exists dim_dates CASCADE;
create table dim_dates(
	date_sk serial primary key,
	full_date date unique not null,
	year int,
	quarter int,
	month int,
	day int,
	weekday_name text
);

-- Dimension Table: Geolocation
drop table if exists dim_geolocations CASCADE;
create table dim_geolocations(
	zip_code_prefix text primary key,
	city text,
	state text,
	lat numeric(10,6),
	lng numeric(10,6)
);

-- Fact Table: Orders (grain = one order)
drop table if exists fact_orders CASCADE;
create table fact_orders(
	order_sk serial primary key,
	order_id text unique not null,
	customer_sk int references dim_customers(customer_sk),
	order_status text,
	purchase_date_sk int references dim_dates(date_sk),
	approve_date_sk int references dim_dates(date_sk),
	delivered_date_sk int references dim_dates(date_sk),
	estimated_delivered_date_sk int references dim_dates(date_sk),
	total_order_amount numeric (10,2)
	
);

-- FacT Table: Payments (grain = one payment per order)
drop table if exists fact_payments CASCADE;
create table fact_payments(
	payment_sk serial primary key,
	order_id text references fact_orders(order_id),
	payment_sequential int,
	payment_type text,
	payment_installments int,
	payment_value numeric(10,2)
);

-- Fact Table: Order Items (grain = one row per order item)
drop table if exists fact_order_items CASCADE;
create table fact_order_items(
	item_sk serial primary key,
	order_id text not null,
	product_sk int references dim_products(product_sk),
	seller_sk int references dim_sellers(seller_sk),
	price numeric(10,2),
	freight_value numeric(10,2),
	quantity int
);

-- Fact Table: Reviews (grain = one review per order)
drop table if exists fact_reviews CASCADE;
create table fact_reviews(
	review_sk serial primary key,
	order_id text references fact_orders(order_id),
	review_id text,
	review_score int,
	review_comment_title text,
	review_comment_message text,
	review_creation_date_sk int references dim_dates(date_sk),
	review_answer_date_sk int references dim_dates(date_sk)
);

Commit;








