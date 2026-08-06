-- This is the data quality check script. 
-- seldom in data pipelines, data needs to go through a filter, and this script is that filter.
-- this will help into maintaining a firm quality to the data that will be analysed.

-- creating log table for data quality logs
DROP TABLE IF EXISTS data_quality_logs CASCADE;
create table data_quality_logs(
	log_id serial primary key,
	check_name text not null,
	check_result boolean,
	row_count_affected int,
	error_message text,
	check_at timestamptz default now()
);

-- check 1: null critical keys in fact tables (customer_sk, seller_sk, product_sk etc.)
insert into data_quality_logs(check_name, check_result, row_count_affected, error_message)
select 
	'fact_orders_null_customer_sk',
	(select count(*) from fact_orders where customer_sk is null) = 0,
	(select count(*) from fact_orders where customer_sk is null),
	case when (select count(*) from fact_orders where customer_sk is null) > 0 then 'Orders with missing customer sk'
	else null end;

insert into data_quality_logs(check_name, check_result, row_count_affected, error_message)
select
	'fact_order_items_null_product_sk',
	(select count(*) from fact_order_items where product_sk is null ) = 0,
	(select count(*) from fact_order_items where product_sk is null ),
	case when (select count(*) from fact_order_items where product_sk is null ) > 0 then 'Order items with missing product SK'
	else null end;

insert into data_quality_logs(check_name, check_result, row_count_affected, error_message)
select
	'fact_order_items_null_seller_sk',
	(select count(*) from fact_order_items where seller_sk is null) = 0,
	(select count(*) from fact_order_items where seller_sk is null),
	case when (select count(*) from fact_order_items where seller_sk is null) > 0 then 'Order items with missing seller SK'
	else null end;
	
-- check 2: negative amount
insert into data_quality_logs(check_name, check_result, row_count_affected, error_message)
select 
	'fact_orders_negative_total',
	(select count(*) from fact_orders where total_order_amount < 0) = 0,
	(select count(*) from fact_orders where total_order_amount < 0),
	case when (select count(*) from fact_orders where total_order_amount < 0) > 0 then 'Order with negative total amount'
	else null end;

insert into data_quality_logs(check_name, check_result, row_count_affected, error_message)
select 
	'fact_order_items_negative_price',
	(select count(*) from fact_order_items where price < 0) = 0,
	(select count(*) from fact_order_items where price < 0),
	case when (select count(*) from fact_order_items where price < 0) > 0 then 'Orders with negative price'
	else null end;


insert into data_quality_logs(check_name, check_result, row_count_affected, error_message)
select 
	'fact_order_items_negative_freight',
	(select count(*) from fact_order_items where freight_value < 0 ) = 0,
	(select count(*) from fact_order_items where freight_value < 0 ),
	case when (select count(*) from fact_order_items where freight_value < 0 ) > 0 then 'Orders with negative freight value'
	else null end;
	
-- check 3: date logic violations (like approve_date < purchase_date, delivered < approved)
insert into data_quality_logs(check_name, check_result, row_count_affected, error_message)
select 	
	'fact_orders_approve_before_purchase',
	(select count(*) from fact_orders where approve_date_sk is not null and approve_date_sk < purchase_date_sk) = 0,
	(select count(*) from fact_orders where approve_date_sk is not null and approve_date_sk < purchase_date_sk),
	case when (select count(*) from fact_orders where approve_date_sk is not null and approve_date_sk < purchase_date_sk) > 0 then
	'Approval date before purchase' else null end;

insert into data_quality_logs(check_name, check_result, row_count_affected, error_message)
select 
	'fact_orders_delivered_before_approve',
	(select count(*) from fact_orders where delivered_date_sk is not null 
	and approve_date_sk is not null and delivered_date_sk < approve_date_sk) = 0,
	(select count(*) from fact_orders where delivered_date_sk is not null 
	and approve_date_sk is not null and delivered_date_sk < approve_date_sk),
	case when (select count(*) from fact_orders where delivered_date_sk is not null 
	and approve_date_sk is not null and delivered_date_sk < approve_date_sk) > 0 then 'Delivered before approved'		
	else null end;
		
-- check 4: duplicate order_id in fact_orders (must be unique)
insert into data_quality_logs(check_name, check_result, row_count_affected, error_message)
select
	'fact_orders_duplicate_order_id',
	(select count(*) from (select order_id from fact_orders group by order_id having count(order_id) > 1) as dup) = 0,
	(select count(*) from (select order_id from fact_orders group by order_id having count(order_id) > 1) as dup),
	case when (select count(*) from (select order_id from fact_orders group by order_id having count(order_id) > 1) as dup) > 0 then
	'Duplicate order ids in fact_orders' else null end;
	
-- check 5: orphaned order items (order_id not in fact_orders)
insert into data_quality_logs(check_name, check_result, row_count_affected, error_message)
select
	'fact_orders_items_orphan_order_id',
	(select count(*) from fact_order_items where order_id not in (select order_id from fact_orders)) = 0,
	(select count(*) from fact_order_items where order_id not in (select order_id from fact_orders)),
	case when (select count(*) from fact_order_items where order_id not in (select order_id from fact_orders)) > 0 then 
	'Order items with missing order' else null end;
	
insert into data_quality_logs(check_name, check_result, row_count_affected, error_message)
select
    'fact_payment_amount_mismatch',
    (select count(*) from fact_orders fo
     left join (select order_id, sum(payment_value) as total_paid from fact_payments group by order_id) fp
	 on fp.order_id = fo.order_id
     where abs(fo.total_order_amount - coalesce(fp.total_paid, 0)) > 0.01) = 0,
    (select count(*) from fact_orders fo
     left join (select order_id, sum(payment_value) as total_paid from fact_payments group by order_id) fp 
	 on fp.order_id = fo.order_id
     where abs(fo.total_order_amount - coalesce(fp.total_paid, 0)) > 0.01),
     case when (select count(*) from fact_orders fo
     left join (select order_id, sum(payment_value) as total_paid from fact_payments group by order_id) fp 
	 on fp.order_id = fo.order_id
     where abs(fo.total_order_amount - coalesce(fp.total_paid, 0)) > 0.01) > 0
         then 'Total order amount vs payment mismatch' else null end;

SELECT * FROM data_quality_logs ORDER BY log_id;



-- fixing the errors that were found after running the above script
-- fix 1: orders without customer sk
begin;
delete from fact_payments where order_id in (select order_id from fact_orders where customer_sk is null);
delete from fact_orders
where customer_sk is null;
commit;
-- fix 2: delivered before approve
update fact_orders
set delivered_date_sk = approve_date_sk
where delivered_date_sk < approve_date_sk;
-- fix 3: order items with missing order
delete from fact_order_items 
where order_id not in (select order_id from fact_orders);