-- =============================================================
-- stg_products.sql
-- Staging model for raw Products table
-- Transformations:
--   1. Rename to snake_case
--   2. Strip $ and cast price/cost to FLOAT (already clean in Snowflake
--      if loaded correctly, but TRY_TO_DOUBLE handles edge cases)
--   3. Compute list margin %
--   4. Normalize category names
-- =============================================================

WITH source AS (
    SELECT * FROM {{ source('raw', 'products') }}
),

cleaned AS (
    SELECT
        ProductKey                                              AS product_key,
        TRIM("Product Name")                                    AS product_name,
        TRIM(Brand)                                             AS brand,
        TRIM(Color)                                             AS color,

        -- Strip dollar signs and cast — handles "$6.62 " style values
        TRY_TO_DOUBLE(
            TRIM(REPLACE("Unit Cost USD", '$', ''))
        )                                                       AS unit_cost_usd,

        TRY_TO_DOUBLE(
            TRIM(REPLACE("Unit Price USD", '$', ''))
        )                                                       AS unit_price_usd,

        SubcategoryKey                                          AS subcategory_key,
        TRIM(Subcategory)                                       AS subcategory,
        CategoryKey                                             AS category_key,
        TRIM(Category)                                          AS category,

        -- Derived: list price gross margin %
        ROUND(
            (TRY_TO_DOUBLE(TRIM(REPLACE("Unit Price USD",'$',''))) -
             TRY_TO_DOUBLE(TRIM(REPLACE("Unit Cost USD", '$',''))))
            / NULLIF(TRY_TO_DOUBLE(TRIM(REPLACE("Unit Price USD",'$',''))), 0)
            * 100,
        2)                                                      AS list_margin_pct

    FROM source
)

SELECT * FROM cleaned
