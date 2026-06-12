-- =============================================================
-- mart_dim_product.sql
-- Product dimension enriched with revenue, margin, ABC class
-- =============================================================

{{
    config(
        materialized = 'table',
        comment      = 'Product dimension — attributes + sales performance + ABC class'
    )
}}

WITH products AS (
    SELECT * FROM {{ ref('stg_products') }}
),

sales AS (
    SELECT
        product_key,
        ROUND(SUM(revenue_usd), 2)          AS total_revenue_usd,
        ROUND(SUM(profit_usd), 2)           AS total_profit_usd,
        SUM(quantity)                        AS total_units_sold,
        COUNT(DISTINCT order_number)         AS total_orders
    FROM {{ ref('int_sales_with_profit') }}
    GROUP BY product_key
),

-- Revenue cumulative % for ABC
ranked AS (
    SELECT
        product_key,
        total_revenue_usd,
        SUM(total_revenue_usd) OVER ()                              AS grand_total_revenue,
        SUM(total_revenue_usd) OVER (ORDER BY total_revenue_usd DESC
                                     ROWS BETWEEN UNBOUNDED PRECEDING
                                     AND CURRENT ROW)               AS running_revenue,
        ROUND(
            SUM(total_revenue_usd) OVER (ORDER BY total_revenue_usd DESC
                                         ROWS BETWEEN UNBOUNDED PRECEDING
                                         AND CURRENT ROW)
            / NULLIF(SUM(total_revenue_usd) OVER (), 0) * 100,
        2)                                                          AS cumulative_revenue_pct
    FROM sales
),

abc AS (
    SELECT
        product_key,
        cumulative_revenue_pct,
        CASE
            WHEN cumulative_revenue_pct <= 70 THEN 'A — Top (70%)'
            WHEN cumulative_revenue_pct <= 90 THEN 'B — Mid (20%)'
            ELSE                                   'C — Tail (10%)'
        END                                                         AS abc_class
    FROM ranked
),

final AS (
    SELECT
        p.product_key,
        p.product_name,
        p.brand,
        p.color,
        p.category,
        p.category_key,
        p.subcategory,
        p.subcategory_key,
        p.unit_cost_usd,
        p.unit_price_usd,
        p.list_margin_pct,

        -- Sales performance
        COALESCE(s.total_revenue_usd, 0)    AS total_revenue_usd,
        COALESCE(s.total_profit_usd,  0)    AS total_profit_usd,
        COALESCE(s.total_units_sold,  0)    AS total_units_sold,
        COALESCE(s.total_orders,      0)    AS total_orders,

        -- ABC classification
        COALESCE(a.abc_class, 'C — Tail (10%)')  AS abc_class,
        a.cumulative_revenue_pct

    FROM products p
    LEFT JOIN sales s   ON p.product_key = s.product_key
    LEFT JOIN abc   a   ON p.product_key = a.product_key
)

SELECT * FROM final
