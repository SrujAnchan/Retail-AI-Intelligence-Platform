-- =============================================================
-- int_customer_orders.sql
-- Aggregate customer-level metrics from enriched sales
-- Produces: CLV, order frequency, recency, RFM scores
-- =============================================================

WITH sales AS (
    SELECT * FROM {{ ref('int_sales_with_profit') }}
),

customers AS (
    SELECT * FROM {{ ref('stg_customers') }}
),

-- Step 1: aggregate per customer
customer_agg AS (
    SELECT
        customer_key,

        -- Monetary
        ROUND(SUM(revenue_usd), 2)                              AS total_revenue_usd,
        ROUND(SUM(profit_usd), 2)                               AS total_profit_usd,
        ROUND(AVG(margin_pct), 2)                               AS avg_margin_pct,

        -- Frequency
        COUNT(DISTINCT order_number)                            AS total_orders,
        COUNT(*)                                                AS total_line_items,
        SUM(quantity)                                           AS total_units,

        -- AOV
        ROUND(SUM(revenue_usd) / NULLIF(COUNT(DISTINCT order_number), 0), 2)
                                                                AS avg_order_value_usd,

        -- Recency
        MAX(order_date)                                         AS last_order_date,
        MIN(order_date)                                         AS first_order_date,
        DATEDIFF('day', MAX(order_date), CURRENT_DATE())        AS days_since_last_order,
        DATEDIFF('day', MIN(order_date), MAX(order_date))       AS customer_active_days,

        -- Channel behaviour
        COUNT(DISTINCT CASE WHEN channel = 'Online'   THEN order_number END)
                                                                AS online_orders,
        COUNT(DISTINCT CASE WHEN channel = 'In-Store' THEN order_number END)
                                                                AS instore_orders

    FROM sales
    GROUP BY customer_key
),

-- Step 2: RFM scores using NTILE(5)
rfm_scored AS (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY days_since_last_order ASC)  AS r_score,  -- lower recency = higher score
        NTILE(5) OVER (ORDER BY total_orders DESC)           AS f_score,
        NTILE(5) OVER (ORDER BY total_revenue_usd DESC)      AS m_score
    FROM customer_agg
),

-- Step 3: Combine RFM into segment label
rfm_segmented AS (
    SELECT
        *,
        CONCAT(r_score::VARCHAR, f_score::VARCHAR, m_score::VARCHAR)
                                                             AS rfm_score,
        r_score + f_score + m_score                          AS rfm_total,

        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal'
            WHEN r_score >= 3 AND f_score >= 2                   THEN 'Potential Loyalist'
            WHEN r_score >= 4 AND f_score <= 2                   THEN 'New Customer'
            WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3  THEN 'At Risk'
            WHEN r_score <= 2 AND f_score >= 4 AND m_score >= 4  THEN 'Cannot Lose Them'
            WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2  THEN 'Lost'
            WHEN r_score <= 3 AND f_score <= 2                   THEN 'Hibernating'
            ELSE 'Needs Attention'
        END                                                  AS rfm_segment

    FROM rfm_scored
),

-- Step 4: Join back to customer dimension
final AS (
    SELECT
        c.customer_key,
        c.customer_name,
        c.gender,
        c.city,
        c.state,
        c.country,
        c.continent,
        c.birthday,
        c.customer_age_years,
        c.age_band,

        -- Order metrics
        r.total_revenue_usd,
        r.total_profit_usd,
        r.avg_margin_pct,
        r.total_orders,
        r.total_line_items,
        r.total_units,
        r.avg_order_value_usd,
        r.last_order_date,
        r.first_order_date,
        r.days_since_last_order,
        r.customer_active_days,
        r.online_orders,
        r.instore_orders,

        -- RFM
        r.r_score,
        r.f_score,
        r.m_score,
        r.rfm_score,
        r.rfm_total,
        r.rfm_segment,

        -- Active flag
        CASE
            WHEN r.total_orders IS NULL THEN FALSE
            ELSE TRUE
        END                                                  AS has_orders

    FROM customers c
    LEFT JOIN rfm_segmented r ON c.customer_key = r.customer_key
)

SELECT * FROM final
