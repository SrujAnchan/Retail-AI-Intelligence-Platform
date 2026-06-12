-- =============================================================
-- int_store_metrics.sql
-- Aggregate store-level performance metrics
-- =============================================================

WITH sales AS (
    SELECT * FROM {{ ref('int_sales_with_profit') }}
),

stores AS (
    SELECT * FROM {{ ref('stg_stores') }}
),

store_agg AS (
    SELECT
        store_key,

        ROUND(SUM(revenue_usd), 2)                                  AS total_revenue_usd,
        ROUND(SUM(profit_usd), 2)                                   AS total_profit_usd,
        ROUND(AVG(margin_pct), 2)                                   AS avg_margin_pct,
        COUNT(DISTINCT order_number)                                AS total_orders,
        SUM(quantity)                                               AS total_units,
        COUNT(DISTINCT customer_key)                                AS unique_customers,

        ROUND(SUM(revenue_usd) / NULLIF(COUNT(DISTINCT order_number), 0), 2)
                                                                    AS avg_order_value_usd,

        MIN(order_date)                                             AS first_sale_date,
        MAX(order_date)                                             AS last_sale_date,

        -- Annual run-rate revenue (based on active trading days)
        ROUND(
            SUM(revenue_usd) /
            NULLIF(DATEDIFF('day', MIN(order_date), MAX(order_date)), 0)
            * 365,
        2)                                                          AS annualized_revenue_usd

    FROM sales
    GROUP BY store_key
),

final AS (
    SELECT
        st.store_key,
        st.country,
        st.state,
        st.store_type,
        st.square_meters,
        st.open_date,
        st.store_age_years,
        st.size_band,

        sa.total_revenue_usd,
        sa.total_profit_usd,
        sa.avg_margin_pct,
        sa.total_orders,
        sa.total_units,
        sa.unique_customers,
        sa.avg_order_value_usd,
        sa.first_sale_date,
        sa.last_sale_date,
        sa.annualized_revenue_usd,

        -- Revenue per sqm (physical stores only)
        CASE
            WHEN st.store_type = 'Physical' AND st.square_meters > 0
            THEN ROUND(sa.annualized_revenue_usd / st.square_meters, 2)
            ELSE NULL
        END                                                         AS revenue_per_sqm,

        -- Revenue rank
        RANK() OVER (ORDER BY sa.total_revenue_usd DESC)            AS revenue_rank

    FROM stores st
    LEFT JOIN store_agg sa ON st.store_key = sa.store_key
)

SELECT * FROM final
