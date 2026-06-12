-- =============================================================
-- stg_stores.sql
-- Staging model for raw Stores table
-- Transformations:
--   1. Rename to snake_case
--   2. Parse open_date
--   3. Handle StoreKey=0 (Online channel — no physical attributes)
--   4. Compute store age in years
-- =============================================================

WITH source AS (
    SELECT * FROM {{ source('raw', 'stores') }}
),

cleaned AS (
    SELECT
        StoreKey                                                AS store_key,
        TRIM(Country)                                           AS country,
        TRIM(State)                                             AS state,
        TRY_TO_DOUBLE("Square Meters")                          AS square_meters,
        TRY_TO_DATE("Open Date", 'MM/DD/YYYY')                  AS open_date,

        -- Channel type
        CASE
            WHEN StoreKey = 0 THEN 'Online'
            ELSE 'Physical'
        END                                                     AS store_type,

        -- Store age in years at time of analysis
        CASE
            WHEN StoreKey = 0 THEN NULL
            ELSE DATEDIFF(
                'year',
                TRY_TO_DATE("Open Date", 'MM/DD/YYYY'),
                CURRENT_DATE()
            )
        END                                                     AS store_age_years,

        -- Size band for physical stores
        CASE
            WHEN StoreKey = 0 THEN 'Online'
            WHEN TRY_TO_DOUBLE("Square Meters") < 500   THEN 'Small (<500 sqm)'
            WHEN TRY_TO_DOUBLE("Square Meters") < 1000  THEN 'Medium (500-1000 sqm)'
            WHEN TRY_TO_DOUBLE("Square Meters") < 1500  THEN 'Large (1000-1500 sqm)'
            ELSE 'XLarge (1500+ sqm)'
        END                                                     AS size_band

    FROM source
)

SELECT * FROM cleaned
