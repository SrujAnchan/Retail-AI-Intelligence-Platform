-- =============================================================
-- stg_exchange_rates.sql
-- Staging model for raw Exchange_Rates table
-- Transformations:
--   1. Parse date string to DATE
--   2. Rename columns
--   3. Deduplicate on (date, currency) — keep last
--   4. Add inverse rate for convenience
-- =============================================================

WITH source AS (
    SELECT * FROM {{ source('raw', 'exchange_rates') }}
),

parsed AS (
    SELECT
        TRY_TO_DATE(Date, 'MM/DD/YYYY')     AS rate_date,
        TRIM(Currency)                       AS currency_code,
        TRY_TO_DOUBLE(Exchange)              AS exchange_rate_vs_usd,

        -- Inverse: how many USD = 1 unit of this currency
        ROUND(1.0 / NULLIF(TRY_TO_DOUBLE(Exchange), 0), 6)
                                             AS usd_per_unit,

        -- Row number for deduplication
        ROW_NUMBER() OVER (
            PARTITION BY TRY_TO_DATE(Date, 'MM/DD/YYYY'), TRIM(Currency)
            ORDER BY Date DESC
        )                                    AS rn

    FROM source
    WHERE Date IS NOT NULL
      AND Currency IS NOT NULL
),

deduped AS (
    SELECT
        rate_date,
        currency_code,
        exchange_rate_vs_usd,
        usd_per_unit
    FROM parsed
    WHERE rn = 1
)

SELECT * FROM deduped
