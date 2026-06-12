-- =============================================================
-- mart_dim_date.sql
-- Complete date spine: 2015-01-01 → 2022-12-31
-- Essential for Power BI time intelligence functions
-- Uses Snowflake's GENERATOR to create every calendar day
-- =============================================================

{{
    config(
        materialized = 'table',
        comment      = 'Full date dimension — required for all time intelligence in Power BI'
    )
}}

WITH date_spine AS (
    SELECT
        DATEADD(
            'day',
            SEQ4(),
            '2015-01-01'::DATE
        )                                           AS full_date
    FROM TABLE(GENERATOR(ROWCOUNT => 3000))  -- ~8 years of dates
    QUALIFY full_date <= '2022-12-31'::DATE
),

final AS (
    SELECT
        full_date                                   AS date_key,  -- YYYY-MM-DD, use as PK
        full_date,

        -- Integer representation (useful for some tools)
        TO_NUMBER(TO_CHAR(full_date, 'YYYYMMDD'))   AS date_int,

        -- Year
        YEAR(full_date)                             AS year,

        -- Quarter
        QUARTER(full_date)                          AS quarter_num,
        CONCAT('Q', QUARTER(full_date)::VARCHAR, ' ',
               YEAR(full_date)::VARCHAR)            AS quarter_label,

        -- Month
        MONTH(full_date)                            AS month_num,
        MONTHNAME(full_date)                        AS month_name,
        TO_CHAR(full_date, 'Mon YYYY')              AS month_label,
        DATE_TRUNC('month', full_date)              AS month_start,

        -- Week
        WEEKOFYEAR(full_date)                       AS week_of_year,
        DATE_TRUNC('week', full_date)               AS week_start,

        -- Day
        DAY(full_date)                              AS day_of_month,
        DAYOFWEEK(full_date)                        AS day_of_week,       -- 0=Sun
        DAYNAME(full_date)                          AS day_name,
        DAYOFYEAR(full_date)                        AS day_of_year,

        -- Flags
        CASE WHEN DAYOFWEEK(full_date) IN (0, 6) THEN TRUE ELSE FALSE END
                                                    AS is_weekend,

        -- Fiscal year (adjust offset if fiscal year ≠ calendar year)
        YEAR(full_date)                             AS fiscal_year,

        -- Relative flags (useful for Power BI default views)
        CASE WHEN full_date = CURRENT_DATE()        THEN TRUE ELSE FALSE END
                                                    AS is_today,
        CASE WHEN full_date <= CURRENT_DATE()       THEN TRUE ELSE FALSE END
                                                    AS is_past_or_today

    FROM date_spine
)

SELECT * FROM final
ORDER BY full_date
