-- =============================================================
-- stg_sales.sql
-- Staging model for raw Sales table
-- Transformations:
--   1. Rename columns to snake_case
--   2. Cast date strings to DATE
--   3. Cast numeric fields
--   4. Derive channel flag (online vs in-store)
--   5. Trim string columns
-- =============================================================

WITH source AS (
    SELECT * FROM {{ source('raw', 'sales') }}
),

renamed AS (
    SELECT
        -- Keys
        "Order Number"                              AS order_number,
        "Line Item"                                 AS line_item,
        TRY_TO_DATE("Order Date",    'MM/DD/YYYY')  AS order_date,
        TRY_TO_DATE("Delivery Date", 'MM/DD/YYYY')  AS delivery_date,
        CustomerKey                                 AS customer_key,
        StoreKey                                    AS store_key,
        ProductKey                                  AS product_key,

        -- Measures
        TRY_TO_NUMBER(Quantity)                     AS quantity,
        TRIM("Currency Code")                       AS currency_code,

        -- Derived
        CASE
            WHEN StoreKey = 0 THEN 'Online'
            ELSE 'In-Store'
        END                                         AS channel,

        -- Surrogate key for the line item grain
        {{ dbt_utils.generate_surrogate_key(
            ['\"Order Number\"', '\"Line Item\"']
        ) }}                                        AS sale_key

    FROM source
    WHERE "Order Number" IS NOT NULL
      AND "Line Item"    IS NOT NULL
)

SELECT * FROM renamed
