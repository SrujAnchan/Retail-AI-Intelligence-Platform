-- =============================================================
-- int_sales_enriched.sql
-- Join sales to exchange rates → compute revenue_usd
-- Logic:
--   revenue_usd = quantity * unit_price_usd / exchange_rate_vs_usd
--   For USD transactions, exchange_rate = 1.0 (no conversion needed)
--   LEFT JOIN to exchange rates — flag any missing rate dates
-- =============================================================

WITH sales AS (
    SELECT * FROM {{ ref('stg_sales') }}
),

products AS (
    SELECT
        product_key,
        unit_price_usd,
        unit_cost_usd,
        list_margin_pct,
        product_name,
        brand,
        color,
        subcategory,
        subcategory_key,
        category,
        category_key
    FROM {{ ref('stg_products') }}
),

fx AS (
    SELECT * FROM {{ ref('stg_exchange_rates') }}
),

-- Join sales to products to get unit prices
sales_with_price AS (
    SELECT
        s.sale_key,
        s.order_number,
        s.line_item,
        s.order_date,
        s.delivery_date,
        s.customer_key,
        s.store_key,
        s.product_key,
        s.quantity,
        s.currency_code,
        s.channel,
        p.unit_price_usd,
        p.unit_cost_usd,
        p.product_name,
        p.brand,
        p.category,
        p.category_key,
        p.subcategory,
        p.subcategory_key,

        -- Revenue in local list price USD (pre-FX)
        ROUND(s.quantity * p.unit_price_usd, 2)  AS revenue_list_usd,
        ROUND(s.quantity * p.unit_cost_usd,  2)  AS cost_list_usd

    FROM sales s
    LEFT JOIN products p ON s.product_key = p.product_key
),

-- Join exchange rates on (order_date, currency_code)
enriched AS (
    SELECT
        sp.*,
        COALESCE(fx.exchange_rate_vs_usd, 1.0)  AS exchange_rate,

        -- TRUE USD-normalized revenue
        ROUND(sp.revenue_list_usd / NULLIF(COALESCE(fx.exchange_rate_vs_usd, 1.0), 0), 2)
                                                  AS revenue_usd,

        -- TRUE USD-normalized cost
        ROUND(sp.cost_list_usd / NULLIF(COALESCE(fx.exchange_rate_vs_usd, 1.0), 0), 2)
                                                  AS cost_usd,

        -- Flag rows where FX rate was missing (fallback to 1.0)
        CASE
            WHEN fx.exchange_rate_vs_usd IS NULL AND sp.currency_code != 'USD'
            THEN TRUE ELSE FALSE
        END                                       AS fx_rate_missing_flag

    FROM sales_with_price sp
    LEFT JOIN fx
        ON  sp.order_date    = fx.rate_date
        AND sp.currency_code = fx.currency_code
)

SELECT * FROM enriched
