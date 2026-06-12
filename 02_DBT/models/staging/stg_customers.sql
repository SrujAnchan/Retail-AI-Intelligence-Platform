-- =============================================================
-- stg_customers.sql
-- Staging model for raw Customers table
-- Transformations:
--   1. Rename to snake_case
--   2. Parse birthday to DATE
--   3. Derive customer_age in years
--   4. Standardize casing
--   5. Handle 10 null State Codes
-- =============================================================

WITH source AS (
    SELECT * FROM {{ source('raw', 'customers') }}
),

cleaned AS (
    SELECT
        CustomerKey                                             AS customer_key,
        TRIM(INITCAP(Gender))                                   AS gender,
        TRIM(Name)                                              AS customer_name,
        TRIM(City)                                              AS city,
        COALESCE(TRIM("State Code"), 'UNKNOWN')                 AS state_code,
        TRIM(State)                                             AS state,
        TRIM("Zip Code")                                        AS zip_code,
        TRIM(Country)                                           AS country,
        TRIM(Continent)                                         AS continent,
        TRY_TO_DATE(Birthday, 'MM/DD/YYYY')                     AS birthday,

        -- Derived age at time of analysis
        DATEDIFF(
            'year',
            TRY_TO_DATE(Birthday, 'MM/DD/YYYY'),
            CURRENT_DATE()
        )                                                       AS customer_age_years,

        -- Age band for segmentation
        CASE
            WHEN DATEDIFF('year', TRY_TO_DATE(Birthday,'MM/DD/YYYY'), CURRENT_DATE()) < 35
                THEN 'Under 35'
            WHEN DATEDIFF('year', TRY_TO_DATE(Birthday,'MM/DD/YYYY'), CURRENT_DATE()) < 50
                THEN '35-49'
            WHEN DATEDIFF('year', TRY_TO_DATE(Birthday,'MM/DD/YYYY'), CURRENT_DATE()) < 65
                THEN '50-64'
            ELSE '65+'
        END                                                     AS age_band

    FROM source
)

SELECT * FROM cleaned
