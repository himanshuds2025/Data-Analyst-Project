# E-Commerce Customer Churn & Retention Analysis
---
## Overview

This project builds an end-to-end analytics pipeline for customer churn analysis using the Brazilian Olist e-commerce dataset.

The objective was to design a production-style analytical solution that enables marketing teams to identify customers at risk of churn, understand why they leave, and prioritize retention strategies based on customer value.

The project includes:

- Data warehouse design (Star Schema)
- ETL pipeline in PostgreSQL
- Customer segmentation using RFM analysis
- Churn risk modeling
- Cohort retention analysis
- Business-focused SQL analytics
- Executive dashboard built in Tableau Public 
---
## Business Problem

Olist is a Brazilian e-commerce marketplace connecting thousands of sellers with customers.

Like most e-commerce businesses, customer acquisition is expensive. Losing existing customers directly impacts long-term profitability.

The marketing team currently lacks a repeatable analytical framework to answer questions such as:

- Which customers are most likely to churn?
- Which customer segments generate the highest value?
- What factors contribute to churn?
- Which product categories lose the most customers?
- How quickly do customers stop purchasing?
  
This project addresses those questions through an automated analytical pipeline.
---
## Business Requirements

The solution should:

- Segment customers by purchasing behaviour
- Quantify customer churn risk
- Identify major churn drivers
- Measure customer retention over time
- Produce actionable recommendations
- Provide an executive dashboard for self-service analytics

---
## Tech Stack

| Category | Technologies |
|----------|--------------|
| Database | PostgreSQL |
| SQL | PostgreSQL |
| Visualization | Tableau Public |
| Bulk Imports | DBeaver |
| Spreadsheet | Excel |
---

## Dataset

Source

[Brazilian Olist E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
Contains information on:

Customers,
Orders,
Order Items,
Products,
Sellers,
Reviews,
Payments, and
Geolocation

Dataset size:

~100,000 Orders
~96,000 Customers

---

## Data Warehouse Architecture

![Star Schema](Images/star%20schema.png)
The project follows a dimensional star schema.

### Fact Tables

- fact_orders
- fact_order_items
- fact_reviews
- fact_payments

### Dimension Tables

- dim_customers
- dim_products
- dim_dates
- dim_sellers
- dim_geolocations

---

## ETL Pipeline

The ETL process performs:

- Data cleaning
- Duplicate removal
- Missing value handling
- Date dimension generation
- Surrogate key creation
- Dimension loading
- Fact loading

The warehouse follows a dimensional modeling approach suitable for analytical workloads.

---

## Analytics Performed

### Customer Segmentation (RFM)

| Segment | Recency Score | Frequency Score | Monetary Score | Description |
|---------|---------------|-----------------|----------------|-------------|
| **Champion** | ≥ 4 | ≥ 4 | ≥ 4 | High recency, high frequency, high spend – best customers |
| **Loyal** | ≥ 3 | ≥ 3 | ≥ 3 | Good on all three metrics – strong, consistent customers |
| **Potential** | ≥ 2 | ≥ 2 | ≥ 2 | Moderate scores – could become loyal with engagement |
| **At Risk** | = 1 | ≥ 3 | Any | Low recency but historically frequent – used to engage, now slipping |
| **Lost** | = 1 | ≤ 2 | Any | Low recency and low frequency – unlikely to return |
| **Other** | Any | Any | Any | Does not meet criteria for any segment above |

### Cohort Retention
Monthly cohorts are analysed to determine how customer retention changes after the first purchase.

### Churn Risk

| Risk Level | Recency (days since last order) | Description |
|------------|--------------------------------|-------------|
| **High**   | > 90 days                       | Customer has been inactive for more than 3 months – likely already churned |
| **Medium** | 61 – 90 days                    | Customer is showing signs of disengagement – needs re‑engagement campaign |
| **Low**    | ≤ 60 days                       | Customer is recently active – low risk of churn |

---

### Churn Driver Analysis

The project investigates whether churn is associated with:

- Delivery time
- Review score
- Product category
- Customer value

---

### Category Contribution Analysis

Rather than analysing every product category equally, the project focuses on categories with meaningful customer volume.
Top 10 most sold categories were taken into consideration for this analysis who had customers greater than 1000.

---

## Dashboard

![Dashboard](Images/Dashboard%20Image.png)

---

## Key Insights

### Delivery Performance
- Delivery delay is the strongest observed churn driver
- Churned customers wait an average of **12.69** days
- Active customers wait 6.58 days
### Customer Retention
- Average Month 1 retention is only **5.22%**
- Retention falls **below 1%** from Month 2 onward
- Most customers never make a second purchase
### Customer Satisfaction
- Active customers average **4.33** review score
- Churned customers average **4.08** review score
- Lower satisfaction is associated with higher churn
### High Value Customers
- Champion customers spend an average of: **R$313.7**
- However, **14,381** Champion customers are classified as High Churn Risk, representing the highest-value customers currently at risk.

---

## Business Recommendations

### Improve Delivery Performance

- Customers who churn experience **significantly longer delivery times** than active customers (12.69 vs. 6.58 days).
- Reducing delivery delays through improved logistics, carrier monitoring, and proactive shipment updates could improve customer retention.

### Launch First-Purchase Retention Campaigns

- Customer retention drops sharply after the first purchase, with only 5.22% of customers returning in the following month.
- Introduce first-month incentives such as personalized offers, loyalty rewards, or follow-up email campaigns to encourage a second purchase before customers become inactive.

### Prioritize High-Volume Product Categories

- Focus retention efforts on product categories that contribute the largest share of churned customers, including Bed Bath Table, Health & Beauty, and Sports & Leisure.
- Improving customer experience in these categories offers the greatest opportunity to reduce overall churn.
  
---

## How to Run

### Prerequisites 
- PostgreSQL: Installed and running on your system.
- Dataset: The Olist dataset (9 CSV files) downloaded from [data source](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
  
### Step-by-Step Setup

#### Create the Database
- Open your terminal or command prompt and connect to PostgreSQL. Then, create a new database for the project.
  ```CREATE DATABASE olist_warehouse;```
#### Import the Raw Data
- Use the COPY command to import the 9 CSV files into your database. You can do this via the psql command-line tool or pgAdmin's import tool [0†L14]. The exact command will depend on your file paths. For example:
  ```COPY olist_customers_dataset FROM '/path/to/your/olist_customers_dataset.csv' DELIMITER ',' CSV HEADER;```
- Note: Ensure all 9 tables are created and populated with the correct schema before proceeding.

#### Run the ETL Pipeline
- Navigate to the /Deliverables folder of this project. From the address bar in File Explorer, open a command prompt and execute the master script:
```"C:\Program Files\PostgreSQL\18\bin\psql" -U postgres -d olist_warehouse -f run_all.sql```

- This single command will execute all four scripts in order: 1_DDL.sql, 2_ETL.sql, 3_DATA_QUALITY.sql, and 4_ANALYTICS.sql.

- **Expected Output**
  - Star Schema Creation: All dimension (dim_*) and fact (fact_*) tables for the data warehouse are created.
  - Data Cleaning: The ETL process cleans and transforms the raw data, handling duplicates, missing values, and generating surrogate keys.
  - Materialized Views: Five analytical views (rfm_segments, cohort_retention, churn_risk, churn_drivers, churn_category_analysis) are created and populated with data.
  - Summary Statistics: The final output of the script will display row counts for key tables and materialized views, confirming the pipeline ran successfully.

### Run this command in
--------------------------------
Alternative Way: 

 Run in order 
- 1_DDL.sql
- 2_ETL.sql
- 3_DATA_QUALITY
- 4_ANALYTICS.sql

















