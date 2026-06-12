-- =============================================================
-- mart_executive_summary.sql
-- Pre-aggregated monthly KPIs — fast-loading executive dashboard
-- Grain: one row per (year, month, country, category)
-- =============================================================

{{
    config(
        materialized = 'table',
        comment      = 'Pre-aggregated monthly KPIs — Executive Dashboard source'
    )
}}

WITH sales AS (
    SELECT * FROM {{ ref('mart_sales_fact') }}
),

monthly AS (
    SELECT
        order_year                              AS year,
        order_month_num                         AS month_num,
        order_month                             AS month_start,
        store_country,
        category,
        channel,

        -- Revenue
        ROUND(SUM(revenue_usd), 2)              AS revenue_usd,
        ROUND(SUM(profit_usd), 2)               AS profit_usd,
        ROUND(SUM(cost_usd), 2)                 AS cost_usd,

        -- Margin
        ROUND(
            SUM(profit_usd) / NULLIF(SUM(revenue_usd), 0) * 100,
        2)                                      AS margin_pct,

        -- Volume
        COUNT(DISTINCT order_number)            AS total_orders,
        SUM(quantity)                           AS total_units,
        COUNT(DISTINCT customer_key)            AS unique_customers,

        -- AOV
        ROUND(
            SUM(revenue_usd) / NULLIF(COUNT(DISTINCT order_number), 0),
        2)                                      AS avg_order_value_usd

    FROM sales
    GROUP BY 1, 2, 3, 4, 5, 6
),

-- Add prior year revenue for YoY calculation
with_yoy AS (
    SELECT
        m.*,

        -- Prior year revenue (same month, country, category, channel)
        LAG(m.revenue_usd) OVER (
            PARTITION BY m.month_num, m.store_country, m.category, m.channel
            ORDER BY m.year
        )                                       AS prior_year_revenue_usd,

        -- MoM revenue (same country, category, channel)
        LAG(m.revenue_usd) OVER (
            PARTITION BY m.store_country, m.category, m.channel
            ORDER BY m.month_start
        )                                       AS prior_month_revenue_usd

    FROM monthly m
),

final AS (
    SELECT
        *,

        -- YoY growth %
        ROUND(
            (revenue_usd - prior_year_revenue_usd)
            / NULLIF(prior_year_revenue_usd, 0) * 100,
        2)                                      AS yoy_growth_pct,

        -- MoM growth %
        ROUND(
            (revenue_usd - prior_month_revenue_usd)
            / NULLIF(prior_month_revenue_usd, 0) * 100,
        2)                                      AS mom_growth_pct

    FROM with_yoy
)

SELECT * FROM final
ORDER BY month_start, store_country, category
