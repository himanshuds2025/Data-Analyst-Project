-- This is the analytics script.
-- Business Questions:
-- 1. Which customers are most valuable? (RFM)
-- 2. How well do customers return over time? (Cohort)
-- 3. Which customers are at risk of churn? (Churn Risk)
-- 4. What factors are associated with churn? (Churn Drivers)
-- 5. What products do churned customers usually buy? (Churn Category Analysis)



-- firstly, i will create RFM for this dataset. RFM basically means recency, frequency, and monetary value.
-- recency means when was the last time a customer ordered? 5 days ago? 1 year ago? (lower is better).
-- frequency means how often have they ordered in a given period? 5 orders? 100 orders? (higher is better).
-- monetary means what was the total revenue generated from a customer $5k? $40k? (higher is better).


-- 1. RFM Segmentation (Value & Behavior) : Who are the customers?
	-- 5 = best for recency (most recent), frequency (most frequent), monetary (highest spend)
drop materialized view if exists rfm_segments CASCADE;
create materialized view rfm_segments as 
with customer_metrics as (
	select 
		dc.customer_unique_id,
		max(fo.purchase_date_sk) as last_order_date,
		count(distinct fo.order_id) as frequency,
		sum(fo.total_order_amount) as monetary,
		(select max(full_date) from dim_dates) - max(dp.full_date) as recency_days
	from fact_orders fo
	join dim_customers dc on dc.customer_sk = fo.customer_sk
	join dim_dates dp on dp.date_sk = fo.purchase_date_sk
	group by dc.customer_unique_id
	
),
rfm_scores as (
	select 
		customer_unique_id,
		recency_days,
		frequency,
		monetary,
		ntile(5) over (order by recency_days desc) as recency_score,   --5 = most recent
		ntile(5) over (order by frequency asc) as frequency_score,  --5 = most frequent
		ntile(5) over (order by monetary asc) as monetary_score --5 == highest spend
	from customer_metrics
)
select
	customer_unique_id,
	recency_days,
	frequency,
	monetary,
	recency_score,
	frequency_score,
	monetary_score,
	(recency_score + frequency_score + monetary_score) as total_score,
	case 
		when recency_score >= 4 and frequency_score >=4 and monetary_score >= 4 then 'Champion'
		when recency_score >= 3 and frequency_score >=3 and monetary_score >= 3 then 'Loyal'
		when recency_score >= 2 and frequency_score >=2 and monetary_score >= 2 then 'Potential'
		when recency_score = 1 and frequency_score >=3 then 'At Risk'
		when recency_score = 1 and frequency_score <=2 then 'Lost'
		else 'Other'
	end as segment	
from rfm_scores;

 -- view result :
	-- select segment, round(avg(monetary),1)as monetary, count(*) from rfm_segments
	-- group by segment
	-- order by monetary desc;

-- 2. Cohort retention (monthly cohorts) : Do they come back?
DROP MATERIALIZED VIEW IF EXISTS cohort_retention CASCADE;
CREATE MATERIALIZED VIEW cohort_retention AS 
WITH cohort_base AS (
    SELECT
        dc.customer_unique_id,
        DATE_TRUNC('month', MIN(dp.full_date) OVER (PARTITION BY dc.customer_unique_id)) AS first_purchase_month,
        DATE_TRUNC('month', dp.full_date) AS order_month,
        EXTRACT(YEAR FROM AGE(DATE_TRUNC('month', dp.full_date), 
                              DATE_TRUNC('month', MIN(dp.full_date) OVER (PARTITION BY dc.customer_unique_id)))) * 12
        + EXTRACT(MONTH FROM AGE(DATE_TRUNC('month', dp.full_date), 
                                  DATE_TRUNC('month', MIN(dp.full_date) OVER (PARTITION BY dc.customer_unique_id)))) AS months_since_first
    FROM fact_orders fo
    JOIN dim_customers dc ON dc.customer_sk = fo.customer_sk
    JOIN dim_dates dp ON dp.date_sk = fo.purchase_date_sk   
),
cohort_size AS (
    SELECT 
        first_purchase_month,
        COUNT(DISTINCT customer_unique_id) AS total_customers
    FROM cohort_base
    GROUP BY first_purchase_month
)
SELECT
    cb.first_purchase_month,
    cb.months_since_first,
    COUNT(DISTINCT cb.customer_unique_id) AS active_customers,
    cs.total_customers,
    ROUND(COUNT(DISTINCT cb.customer_unique_id)::NUMERIC / cs.total_customers * 100, 2) AS active_percentage
FROM cohort_base cb
JOIN cohort_size cs ON cs.first_purchase_month = cb.first_purchase_month
WHERE cb.months_since_first >= 0
GROUP BY cb.first_purchase_month, cb.months_since_first, cs.total_customers
ORDER BY cb.first_purchase_month, cb.months_since_first;

 -- view result :
	-- 	SELECT
	--     months_since_first,
	--     ROUND(AVG(active_percentage), 2) AS avg_retention_percent
	-- FROM cohort_retention
	-- GROUP BY months_since_first
	-- ORDER BY months_since_first;

-- 3. Churn Risk : Who is likely churned?
drop materialized view if exists churn_risk CASCADE;
create materialized view churn_risk as 
with customer_metrics as (
select
	dc.customer_unique_id,
	max(dp.full_date) as last_order_date,
	count(distinct fo.order_id) as frequency,
	sum(fo.total_order_amount) as monetary,
	avg(dd.full_date - dp.full_date) as avg_delivery_days,
	avg(r.review_score) as avg_review_score
from fact_orders fo
join dim_customers dc on dc.customer_sk = fo.customer_sk
join dim_dates dp on dp.date_sk  = fo.purchase_date_sk
left join dim_dates dd on dd.date_sk  = fo.delivered_date_sk
left join fact_reviews r on r.order_id = fo.order_id
group by dc.customer_unique_id
),
latest_date as (select max(full_date) as ref_date from dim_dates)
select
	cm.customer_unique_id,
	cm.last_order_date,
	(ld.ref_date - cm.last_order_date) as recency_days,
	cm.frequency,
	cm.monetary,
	cm.avg_delivery_days,
	cm.avg_review_score,
	case 
		when (ld.ref_date - cm.last_order_date) >90 then 'High'
		when (ld.ref_date - cm.last_order_date) >60 then 'Medium'
		else 'Low'
	end as churn_risk,
	case 
		when cm.frequency < 2 then 'Single Order' else 'Repeat'
	end as purchase_behaviour
from customer_metrics cm
cross join latest_date ld;
	
	-- view result (FULL TABLE)
		-- select * from churn_risk;
		
	-- distribution level result (GROUPED RESULT) :
		-- SELECT churn_risk, COUNT(*) FROM churn_risk GROUP BY churn_risk;

-- 4. Churn Drivers : Why are they churning?
drop materialized view if exists churn_drivers CASCADE;
create materialized view churn_drivers as 
with customer_status as (
select 
	customer_unique_id,
	case 
		when recency_days > 90 then 'Churned'
		else 'Active'
	end as status
from churn_risk
),
customer_metrics as (
select
	dc.customer_unique_id,
	avg(dd.full_date - dp.full_date) as avg_delivery_days,
	avg(r.review_score) as avg_review_score,
	count(distinct fo.order_id) as order_count,
	sum(fo.total_order_amount) as total_spent,
	-- most used payment method
	mode() within group (order by payment_type) as preferred_payment
from fact_orders fo
join dim_customers dc on dc.customer_sk = fo.customer_sk
left join dim_dates dd on dd.date_sk = fo.delivered_date_sk
left join dim_dates dp on dp.date_sk = fo.purchase_date_sk
left join fact_payments fp on fp.order_id = fo.order_id
left join fact_reviews r on r.order_id = fo.order_id
group by dc.customer_unique_id
)
select
	cs.status,
	count(distinct cm.customer_unique_id)as customer_count,
	round(avg(cm.avg_delivery_days),2) as avg_delivery_days,
	round(avg(cm.avg_review_score),2) as avg_review_score,
	round(avg(cm.total_spent),2) as avg_customer_lifetime_spend,
	round(avg(cm.order_count),2) as avg_order_count,
	-- most used payment method
	mode() within group (order by cm.preferred_payment) as most_common_payment
from customer_status cs
join customer_metrics cm on cm.customer_unique_id = cs.customer_unique_id
group by cs.status;

	-- view result
		-- select * from churn_drivers;

-- 5. Churn Category Analysis (what do churned customers usually buy?)
DROP MATERIALIZED VIEW IF EXISTS churn_category_analysis CASCADE;
CREATE MATERIALIZED VIEW churn_category_analysis AS
WITH customer_status AS (
    SELECT
        customer_unique_id,
        CASE WHEN recency_days > 90 THEN 'Churned' ELSE 'Active' END AS status
    FROM churn_risk
),
category_customers AS (
    SELECT
        pr.category_name,
        cs.customer_unique_id,
        cs.status
    FROM fact_order_items foi
    JOIN fact_orders fo ON fo.order_id = foi.order_id
    JOIN dim_customers dc ON dc.customer_sk = fo.customer_sk
    JOIN dim_products pr ON pr.product_sk = foi.product_sk
    JOIN customer_status cs ON cs.customer_unique_id = dc.customer_unique_id
    GROUP BY pr.category_name, cs.customer_unique_id, cs.status   
)
SELECT
    category_name AS category,
    COUNT(DISTINCT customer_unique_id) AS total_customers,
    COUNT(DISTINCT CASE WHEN status = 'Churned' THEN customer_unique_id END) AS churned_customers,
    ROUND(
        COUNT(DISTINCT CASE WHEN status = 'Churned' THEN customer_unique_id END)::NUMERIC 
        / NULLIF(COUNT(DISTINCT customer_unique_id), 0) * 100, 2
    ) AS churn_rate_percent,
    (SELECT COUNT(DISTINCT order_id) FROM fact_order_items foi2 
     JOIN dim_products pr2 ON pr2.product_sk = foi2.product_sk 
     WHERE pr2.category_name = category_customers.category_name) AS total_orders
FROM category_customers
GROUP BY category_name
ORDER BY churn_rate_percent DESC;

 	-- overall churn rate of all the products:
		-- SELECT
	 --    		ROUND(
	 --        		100.0 * SUM(churned_customers) / SUM(total_customers),2) AS overall_customer_churn_rate
		-- FROM churn_category_analysis;
		
	-- view result (ALL CATEGORIES)
		-- SELECT
	 --    		category,
	 --    		total_customers,
	 --    		churned_customers,
	 --    		churn_rate_percent,
	 --    		total_orders
		-- FROM churn_category_analysis
		-- WHERE total_customers >= 1000
		-- ORDER BY churned_customers DESC;

	-- churn contribution of categories that have business impact
		-- SELECT
		--     category,
		--     churned_customers,
		--     ROUND(
		--         100.0 * churned_customers /
		--         SUM(churned_customers) OVER (),
		--         2
		--     ) AS churn_contribution_percent
		-- FROM churn_category_analysis
		-- ORDER BY churn_contribution_percent DESC
		-- LIMIT 10;


--- FOR EXPORT TABLEAU 


	-- 	WITH customer_category_counts AS (
	--     SELECT 
	--         fo.customer_sk,
	--         pr.category_name,
	--         COUNT(*) AS category_order_count,
	--         ROW_NUMBER() OVER (PARTITION BY fo.customer_sk ORDER BY COUNT(*) DESC) AS rn
	--     FROM fact_orders fo
	--     JOIN fact_order_items foi ON foi.order_id = fo.order_id
	--     JOIN dim_products pr ON pr.product_sk = foi.product_sk
	--     GROUP BY fo.customer_sk, pr.category_name
	-- ),
	-- primary_categories AS (
	--     SELECT 
	--         customer_sk, 
	--         category_name AS primary_category
	--     FROM customer_category_counts
	--     WHERE rn = 1
	-- )
	-- SELECT 
	--     cr.customer_unique_id,
	--     cr.last_order_date,
	--     cr.recency_days,
	--     cr.frequency,
	--     cr.monetary,
	--     ROUND(cr.avg_delivery_days, 2) AS avg_delivery_days,
	--     ROUND(cr.avg_review_score, 2) AS avg_review_score,
	--     cr.churn_risk,
	--     CASE 
	--         WHEN cr.churn_risk = 'High' THEN 'Churned'
	--         ELSE 'Active'
	--     END AS status,
	--     cr.purchase_behaviour,
	--     rs.segment,
	--     rs.recency_score,
	--     rs.frequency_score,
	--     rs.monetary_score,
	--     pc.primary_category
	-- FROM churn_risk cr
	-- JOIN dim_customers dc ON dc.customer_unique_id = cr.customer_unique_id
	-- LEFT JOIN rfm_segments rs ON rs.customer_unique_id = cr.customer_unique_id
	-- LEFT JOIN primary_categories pc ON pc.customer_sk = dc.customer_sk;