-- =============================================================
-- mart_dim_customer.sql
-- Customer dimension enriched with CLV, RFM segment, order history
-- =============================================================

{{
    config(
        materialized = 'table',
        comment      = 'Customer dimension — demographics + CLV + RFM segment'
    )
}}

SELECT * FROM {{ ref('int_customer_orders') }}
