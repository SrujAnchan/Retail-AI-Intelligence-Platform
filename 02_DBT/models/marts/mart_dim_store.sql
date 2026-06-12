-- =============================================================
-- mart_dim_store.sql
-- Store dimension enriched with performance metrics
-- =============================================================

{{
    config(
        materialized = 'table',
        comment      = 'Store dimension — attributes + revenue + revenue/sqm'
    )
}}

SELECT * FROM {{ ref('int_store_metrics') }}
