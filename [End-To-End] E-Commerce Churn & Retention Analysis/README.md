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

Customers
Orders
Order Items
Products
Sellers
Reviews
Payments
Geolocation

Dataset size:

~100,000 Orders
~96,000 Customers

---

## Data Model

![Star Schema](Images/star%20schema.png)
The project follows a dimensional star schema...

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

...

---

## Analytics Performed

### Customer Segmentation (RFM)

...

### Cohort Retention

...

### Churn Driver Analysis

...

---

## Dashboard

![Dashboard](images/dashboard.png)

---

## Key Insights

- Insight 1
- Insight 2
- Insight 3

---

## Business Recommendations

- Recommendation 1
- Recommendation 2

---

## How to Run

In the same folder of 'deliverables', run cmd from the address bar in the file explorer.

### Run this command in
"C:\Program Files\PostgreSQL\18\bin\psql" -U postgres -d postgres -f run_all.sql

    OR

-- Run in order 
1_DDL.sql
2_ETL.sql
3_DATA_QUALITY
4_ANALYTICS.sql















exports.sql
```
