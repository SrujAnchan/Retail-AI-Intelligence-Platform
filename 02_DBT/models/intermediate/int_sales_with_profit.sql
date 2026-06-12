-- =============================================================
-- int_sales_with_profit.sql
-- Add profit, margin, delivery_days to enriched sales
-- This is the "widest" intermediate — all line-item metrics live here
-- =============================================================

WITH enriched AS (
    SELECT * FROM {{ ref('int_sales_enriched') }}
),

with_profit AS (
    SELECT
        -- ── Identifiers ────────────────────────────────────────
        sale_key,
        order_number,
        line_item,
        order_date,
        delivery_date,
        customer_key,
        store_key,
        product_key,
        channel,
        currency_code,
        exchange_rate,
        fx_rate_missing_flag,

        -- ── Product context ────────────────────────────────────
        product_name,
        brand,
        category,
        category_key,
        subcategory,
        subcategory_key,

        -- ── Measures (USD normalized) ──────────────────────────
        quantity,
        unit_price_usd,
        unit_cost_usd,
        revenue_usd,
        cost_usd,

        ROUND(revenue_usd - cost_usd, 2)                    AS profit_usd,

        ROUND(
            (revenue_usd - cost_usd) / NULLIF(revenue_usd, 0) * 100,
        2)                                                  AS margin_pct,

        -- ── Fulfilment speed ───────────────────────────────────
        CASE
            WHEN delivery_date IS NOT NULL AND order_date IS NOT NULL
            THEN DATEDIFF('day', order_date, delivery_date)
            ELSE NULL
        END                                                 AS delivery_days,

        -- ── Delivery flag ──────────────────────────────────────
        CASE
            WHEN delivery_date IS NULL         THEN 'No Delivery Date'
            WHEN DATEDIFF('day', order_date, delivery_date) < 0
                                               THEN 'Negative (Error)'
            WHEN DATEDIFF('day', order_date, delivery_date) <= 3
                                               THEN 'Fast (≤3 days)'
            WHEN DATEDIFF('day', order_date, delivery_date) <= 7
                                               THEN 'Standard (4-7 days)'
            ELSE                                    'Slow (8+ days)'
        END                                                 AS delivery_speed_band,

        -- ── Date parts for aggregation ─────────────────────────
        DATE_TRUNC('month', order_date)                     AS order_month,
        DATE_TRUNC('quarter', order_date)                   AS order_quarter,
        YEAR(order_date)                                    AS order_year,
        MONTH(order_date)                                   AS order_month_num,
        DAYOFWEEK(order_date)                               AS order_day_of_week

    FROM enriched
    WHERE revenue_usd > 0   -- exclude zero-revenue anomalies
)

SELECT * FROM with_profit
