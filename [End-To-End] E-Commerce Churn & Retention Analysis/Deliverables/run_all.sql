-- ============================================================
-- run_all.sql – Complete pipeline: DDL → ETL → Quality → Analytics
-- Execute this in pgAdmin to rebuild the entire project from scratch.
-- ============================================================

-- Phase 1: Schema (DDL)
\i 1_DDL.sql


-- Phase 2: Data Population (ETL)
\i 2_ETL.sql

-- Phase 3: Data Quality Checks & Fixes
\i 3_DATA_QUALITY.sql

-- Phase 4: Analytical Views (RFM, Cohort, Churn, etc.)
\i 4_ANALYTICS.sql

-- Optional: Verify row counts
SELECT 'fact_orders', COUNT(*) FROM fact_orders
UNION ALL
SELECT 'dim_customers', COUNT(*) FROM dim_customers
UNION ALL
SELECT 'rfm_segments', COUNT(*) FROM rfm_segments
UNION ALL
SELECT 'churn_risk', COUNT(*) FROM churn_risk;