-- This is the ETL script. 
-- basic concept of ETL while working with star schema is that dimensions need to be populated first before the facts
-- this happens because facts are dependent on dimensions.
-- proceeding like this avoids any dependency issues.


Begin;
insert into dim_dates (full_date, year, quarter, month, day, weekday_name)
select distinct 
    d::Date,
    extract(year from d)::int,
    extract(quarter from d)::int,
    extract(month from d)::int,
    extract(day from d)::int,
    to_char(d, 'Day')
from (
    select order_purchase_timestamp::timestamptz as d from olist_orders_dataset
    union
    select order_approved_at::timestamptz as d from olist_orders_dataset
    union
    select order_delivered_carrier_date::timestamptz as d from olist_orders_dataset
    union
    select order_delivered_customer_date::timestamptz as d from olist_orders_dataset
    union
    select order_estimated_delivery_date::timestamptz as d from olist_orders_dataset
) as dates
where d is not null
order by d;

-- Populating dim_products
insert into dim_products (
	product_id,
	category_name,
	name_length,
	description_length, 
	photos_qty, 
	weight_g, 
	length_cm, 
	height_cm, 
	width_cm
)
select distinct 
	p.product_id,
	t.product_category_name_english as category_name,
	p.product_name_lenght,
	p.product_description_lenght,
	product_photos_qty,
	product_weight_g,
	product_length_cm,
	product_height_cm,
	product_width_cm
from olist_products_dataset as p
left join product_category_name_translation t
	on t.product_category_name = p.product_category_name;

-- Populating Sellers
insert into dim_sellers (
	seller_id,
	zip_code_prefix,
	city,
	state
)
select distinct
	s.seller_id,
	s.seller_zip_code_prefix,
	s.seller_city as city,
	s.seller_state as state
from olist_sellers_dataset as s;

-- Populating dim_customers 
insert into dim_customers (
	customer_id,
	customer_unique_id,
	zip_code_prefix,
	city,
	state,
	valid_from,
	valid_to,
	is_current
)
select distinct on (c.customer_unique_id)
	c.customer_id,
	c.customer_unique_id,
	c.customer_zip_code_prefix,
	c.customer_city,
	c.customer_state,
	now(),
	'infinity'::timestamptz,
	True
from olist_customers_dataset as c
order by c.customer_unique_id, c.customer_id;

-- Populating dim_geolocations
insert into dim_geolocations (
	zip_code_prefix,
	city,
	state,
	lat,
	lng
)
select distinct on (g.geolocation_zip_code_prefix)
	g.geolocation_zip_code_prefix,
	g.geolocation_city,
	g.geolocation_state,
	g.geolocation_lat,
	g.geolocation_lng	
from olist_geolocation_dataset as g
ORDER BY geolocation_zip_code_prefix;

-- Populating fact_orders
insert into fact_orders (
	order_id,
	customer_sk,
	order_status,
	purchase_date_sk,
	approve_date_sk,
	delivered_date_sk,
	estimated_delivered_date_sk,
	total_order_amount
	
)
select 
	o.order_id,
	dc.customer_sk,
	o.order_status,
	dp.date_sk as purchase_date_sk,
	da.date_sk as approve_date_sk,
	dd.date_sk as delivered_date_sk,
	de.date_sk as estimated_delivered_date_sk,
	coalesce(sum(pay.payment_value), 0) as total_order_amount
	
	
from olist_orders_dataset as o
-- facts now need to be joined on dim tables
left join olist_customers_dataset c
    on c.customer_id = o.customer_id

left join dim_customers dc
    on dc.customer_unique_id = c.customer_unique_id
   and dc.is_current = true
LEFT JOIN dim_dates dp ON dp.full_date = o.order_purchase_timestamp::DATE
LEFT JOIN dim_dates da ON da.full_date = o.order_approved_at::DATE
LEFT JOIN dim_dates dd ON dd.full_date = o.order_delivered_customer_date::DATE
LEFT JOIN dim_dates de ON de.full_date = o.order_estimated_delivery_date::DATE
left join olist_order_payments_dataset pay on pay.order_id = o.order_id
LEFT JOIN olist_order_reviews_dataset r ON r.order_id = o.order_id
group by o.order_id,
	o.order_status,
	dc.customer_sk,
	da.date_sk,
	dd.date_sk,
	dp.date_sk,
	de.date_sk
	;


-- Populating fact_order_items
insert into fact_order_items (
	order_id,
	product_sk,
	seller_sk,
	price,
	freight_value,
	quantity
)
select
	oi.order_id,
	dp.product_sk,
	ds.seller_sk,
	oi.price,
	oi.freight_value,
	1 as quantity
from olist_order_items_dataset as oi
inner join dim_products dp on dp.product_id = oi.product_id
inner join dim_sellers ds on ds.seller_id = oi.seller_id;

-- Populating fact_payments
insert into fact_payments (
	order_id,
	payment_sequential,
	payment_type,
	payment_installments,
	payment_value
)
select 
	op.order_id,
	op.payment_sequential,
	op.payment_type,
	op.payment_installments,
	op.payment_value
from olist_order_payments_dataset as op
where op.order_id in (select order_id from fact_orders);

-- Populating fact_reviews
insert into fact_reviews(
	order_id,
	review_id,
	review_score,
	review_comment_title,
	review_comment_message,
	review_creation_date_sk,
	review_answer_date_sk
)
select
	r.order_id,
	r.review_id,
	r.review_score,
	r.review_comment_title,
	r.review_comment_message,
	dc.date_sk,
	da.date_sk
from olist_order_reviews_dataset as r
left join dim_dates dc
	on dc.full_date = r.review_creation_date::date
left join dim_dates da
	on da.full_date = r.review_answer_timestamp::date
where r.order_id in (
	select order_id
	from fact_orders
);

commit;

