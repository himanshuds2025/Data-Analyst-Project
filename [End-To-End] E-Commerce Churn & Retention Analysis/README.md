# E-Commerce Customer Churn & Retention Analysis
## Overview

This project builds an end-to-end analytics pipeline for customer churn analysis using the Brazilian Olist e-commerce dataset.

The objective was to design a production-style analytical solution that enables marketing teams to identify customers at risk of churn, understand why they leave, and prioritize retention strategies based on customer value.

The project includes:

Data warehouse design (Star Schema)
ETL pipeline in PostgreSQL
Customer segmentation using RFM analysis
Churn risk modeling
Cohort retention analysis
Business-focused SQL analytics
Executive dashboard built in Tableau Public

## Business Problem

Olist is a Brazilian e-commerce marketplace connecting thousands of sellers with customers.

Like most e-commerce businesses, customer acquisition is expensive. Losing existing customers directly impacts long-term profitability.

The marketing team currently lacks a repeatable analytical framework to answer questions such as:

Which customers are most likely to churn?
Which customer segments generate the highest value?
What factors contribute to churn?
Which product categories lose the most customers?
How quickly do customers stop purchasing?

This project addresses those questions through an automated analytical pipeline.

## Business Requirements

The solution should:

Segment customers by purchasing behaviour
Quantify customer churn risk
Identify major churn drivers
Measure customer retention over time
Produce actionable recommendations
Provide an executive dashboard for self-service analytics
