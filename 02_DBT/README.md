#  02 — DBT Pipeline on Snowflake

## Overview

This folder contains the complete **dbt (Data Build Tool) project** for the Retail AI Intelligence Platform. It transforms raw CSV data loaded into Snowflake into production-ready mart tables that Power BI connects to.

---

## Project Structure

```
02_DBT/
├── dbt_project.yml              ← project config and schema routing
├── packages.yml                 ← dbt_utils dependency
├── profiles.yml                 ← Snowflake connection template
└── models/
    ├── staging/                 ← 5 models — clean raw data (views)
    │   ├── sources.yml
    │   ├── schema.yml
    │   ├── stg_sales.sql
    │   ├── stg_customers.sql
    │   ├── stg_products.sql
    │   ├── stg_stores.sql
    │   └── stg_exchange_rates.sql
    ├── intermediate/            ← 4 models — business logic (views)
    │   ├── int_sales_enriched.sql
    │   ├── int_sales_with_profit.sql
    │   ├── int_customer_orders.sql
    │   └── int_store_metrics.sql
    └── marts/                   ← 6 models — final tables for Power BI (tables)
        ├── schema.yml
        ├── mart_sales_fact.sql
        ├── mart_dim_customer.sql
        ├── mart_dim_product.sql
        ├── mart_dim_store.sql
        ├── mart_dim_date.sql
        └── mart_executive_summary.sql
```

---

## The Three Layers

| Layer        | Models | Materialized As | Purpose                                                   |
|--------------|--------|-----------------|-----------------------------------------------------------|
| Staging      | 5      | Views           | Clean raw data — rename columns, fix types, strip $ signs |
| Intermediate | 4      | Views           | Business logic — FX conversion, profit, RFM scoring       |
| Marts        | 6      | Tables          | Final tables Power BI connects to                         |

---

## What Each Model Does

### Staging Layer

| Model                  | Source              | Key Transformations                                                      |
|------------------------|---------------------|--------------------------------------------------------------------------|
| `stg_sales`            | Sales.csv           | Parse dates, add channel flag (Online/In-Store), surrogate key           |
| `stg_customers`        | Customers.csv       | Parse birthday, derive age and age band (Under 35 / 35-49 / 50-64 / 65+) |
| `stg_products`         | Products.csv        | Strip $ from prices, cast to float, compute list margin %                |
| `stg_stores`           | Stores.csv          | Add store type, size band, store age in years                            |
| `stg_exchange_rates`   | Exchange_Rates.csv  | Parse dates, deduplicate on (date, currency)                             |

### Intermediate Layer

| Model                    | Depends On                                          | Purpose                                              |
|--------------------------|-----------------------------------------------------|------------------------------------------------------|
| `int_sales_enriched`     | stg_sales + stg_products + stg_exchange_rates       | FX join → compute revenue_usd                        |
| `int_sales_with_profit`  | int_sales_enriched                                  | profit_usd, margin%, delivery days, date parts       |
| `int_customer_orders`    | int_sales_with_profit + stg_customers               | CLV, RFM scores (1–5), segment labels                |
| `int_store_metrics`      | int_sales_with_profit + stg_stores                  | Revenue per sqm, annualized revenue, performance rank|

### Mart Layer

| Model                      | Rows   | Purpose                                                  |
|----------------------------|--------|----------------------------------------------------------|
| `mart_sales_fact`          | 62,884 | Primary fact table — all Power BI visuals read from here |
| `mart_dim_customer`        | 15,266 | Customer master with CLV and RFM segments                |
| `mart_dim_product`         | 2,517  | Product master with ABC classification (A/B/C)           |
| `mart_dim_store`           | 67     | Store master with revenue per sqm and performance rank   |
| `mart_dim_date`            | 2,922  | Full date spine for Power BI time intelligence           |
| `mart_executive_summary`   | 4,025  | Pre-aggregated monthly KPIs with YoY and MoM growth      |

---

## Setup Instructions

### 1. Install dbt for Snowflake

```bash
pip install dbt-snowflake
```

### 2. Configure Snowflake Connection

Copy `profiles.yml` to your home directory:

```bash
# Windows
copy profiles.yml C:\Users\YOUR_USERNAME\.dbt\profiles.yml

# Mac / Linux
cp profiles.yml ~/.dbt/profiles.yml
```

Then open `~/.dbt/profiles.yml` and fill in your credentials:

```yaml
retail_bi:
  target: dev
  outputs:
    dev:
      type:      snowflake
      account:   "your_account_identifier"
      user:      "your_username"
      password:  "your_password"
      warehouse: "COMPUTE_WH"
      database:  "RETAIL_RAW"
      schema:    "RAW"
      threads:   4
```

### 3. Load Raw Data into Snowflake

Before running dbt, load the 6 CSV files into Snowflake:

```
Database : RETAIL_RAW
Schema   : RAW
Tables   : CUSTOMERS, PRODUCTS, STORES, SALES, EXCHANGE_RATES
```

### 4. Install Packages

```bash
dbt deps
```

### 5. Test Connection

```bash
dbt debug
```

All checks should show `OK`.

### 6. Run All Models

```bash
dbt run
```


### 7. Run Tests

```bash
dbt test
```


### 8. View Documentation

```bash
dbt docs generate
dbt docs serve
```

Opens full lineage diagram at `http://localhost:8080`

---

## dbt Commands Reference

| Command | What It Does |
|-------------------------------------|--------------------------------------|
| `dbt deps`                          | Download packages (dbt_utils)        |
| `dbt debug`                         | Test Snowflake connection            |
| `dbt run`                           | Build all 15 models in correct order |
| `dbt test`                          | Run all 97 data quality tests        |
| `dbt run --select stg_sales`        | Build one specific model             |
| `dbt run --select +mart_sales_fact` | Build model and all its dependencies |
| `dbt docs generate`                 | Generate documentation website       |
| `dbt docs serve`                    | View docs at localhost:8080          |
---

## Model Lineage
---

## Key Transformations

| Transformation     | Model                   | Formula                                                     |
|--------------------|-------------------------|-------------------------------------------------------------|
| FX Normalization   | `int_sales_enriched`    | `revenue_usd = (quantity × unit_price_usd) / exchange_rate` |
| Gross Profit       | `int_sales_with_profit` | `profit_usd = revenue_usd − cost_usd`                       |
| Gross Margin %     | `int_sales_with_profit` | `margin_pct = (profit_usd / revenue_usd) × 100`             |
| RFM Scoring        | `int_customer_orders`   | `NTILE(5)` on recency, frequency, monetary                  |
| ABC Classification | `mart_dim_product`      | A = top 70% revenue SKUs, B = next 20%, C = tail 10%        |
| Revenue per SQM    | `int_store_metrics`     | `annualized_revenue / square_meters`                        |

---

## Tech Stack

| Tool          | Version | Purpose                  |
|---------------|---------|--------------------------|
| dbt Core      | 1.11    | Transformation framework |
| dbt-snowflake | 1.11    | Snowflake adapter        |
| Snowflake     | —       | Cloud data warehouse     |
| dbt_utils     | 1.3.3   | Surrogate key macro      |
