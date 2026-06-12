-- =============================================================
-- mart_sales_fact.sql
-- Final fact table — one row per order line item
-- Fully enriched with USD revenue, profit, customer & store context
-- This is the PRIMARY table Power BI connects to
-- Materialized as TABLE for query performance
-- =============================================================

{{
    config(
        materialized = 'table',
        cluster_by   = ['order_date', 'category'],
        comment      = 'Final enriched sales fact — USD normalized, fully joined'
    )
}}

WITH sales AS (
    SELECT * FROM {{ ref('int_sales_with_profit') }}
),

customers AS (
    SELECT
        customer_key,
        customer_name,
        gender,
        city,
        state        AS customer_state,
        country      AS customer_country,
        continent,
        age_band,
        customer_age_years
    FROM {{ ref('stg_customers') }}
),

stores AS (
    SELECT
        store_key,
        country      AS store_country,
        state        AS store_state,
        store_type,
        size_band    AS store_size_band,
        square_meters
    FROM {{ ref('stg_stores') }}
),

final AS (
    SELECT
        -- ── Surrogate / natural keys ───────────────────────────
        s.sale_key,
        s.order_number,
        s.line_item,

        -- ── Dates ─────────────────────────────────────────────
        s.order_date,
        s.delivery_date,
        s.order_month,
        s.order_quarter,
        s.order_year,
        s.order_month_num,
        s.order_day_of_week,

        -- ── Dimension keys (for relationships in Power BI) ────
        s.customer_key,
        s.store_key,
        s.product_key,

        -- ── Customer context ──────────────────────────────────
        c.customer_name,
        c.gender,
        c.customer_country,
        c.continent,
        c.age_band,

        -- ── Store context ─────────────────────────────────────
        st.store_country,
        st.store_state,
        st.store_type,
        st.store_size_band,
        s.channel,

        -- ── Product context ───────────────────────────────────
        s.product_name,
        s.brand,
        s.category,
        s.category_key,
        s.subcategory,
        s.subcategory_key,

        -- ── Currency ──────────────────────────────────────────
        s.currency_code,
        s.exchange_rate,
        s.fx_rate_missing_flag,

        -- ── Core measures ─────────────────────────────────────
        s.quantity,
        s.unit_price_usd,
        s.unit_cost_usd,
        s.revenue_usd,
        s.cost_usd,
        s.profit_usd,
        s.margin_pct,

        -- ── Fulfilment ────────────────────────────────────────
        s.delivery_days,
        s.delivery_speed_band

    FROM sales s
    LEFT JOIN customers  c  ON s.customer_key = c.customer_key
    LEFT JOIN stores     st ON s.store_key    = st.store_key
)

SELECT * FROM final
