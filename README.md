# Retail AI Intelligence Platform

> An end-to-end retail BI platform — from raw CSV ingestion through a Snowflake data warehouse to an AI-powered analytics layer.

---

## Project Summary

This project transforms **62,884 retail transactions** across **8 countries and 5 currencies** into a fully automated business intelligence system. It covers the complete data engineering lifecycle — exploratory analysis, a production dbt pipeline, an interactive Power BI dashboard, and a 4-module AI analytics platform.

| Metric | Value |
|--------|-------|
| Total Transactions | 62,884 |
| Countries | 8 |
| Currencies | 5 (USD, CAD, AUD, EUR, GBP) |
| Date Range | 2016 – 2021 |
| Total Revenue (USD normalized) | $44.6M |
| Gross Margin | 57% |
| dbt Models | 15 across 3 layers |
| Power BI Dashboard Pages | 6 |
| AI Modules | 4 |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    RAW DATA (6 CSV Files)                       │
│     Customers · Products · Stores · Sales · Exchange Rates      │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                  PHASE 1 — EDA (Google Colab)                   │
│   20-step analysis · Data profiling · Quality audit · Planning  │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│               PHASE 2 — dbt Pipeline (Snowflake)                │
│                                                                 │
│  Staging (5 views) → Intermediate (4 views) → Marts (6 tables)  │
│                                                                 │
│  FX Normalization · RFM Segmentation · ABC Classification       │
└──────────────────┬───────────────────────────┬──────────────────┘
                   │                           │
                   ▼                           ▼
┌──────────────────────────┐   ┌──────────────────────────────────┐
│  PHASE 3 — Power BI      │   │   PHASE 4 — AI Platform          │
│                          │   │                                  │
│  6 Dashboard Pages       │   │  Module 1 — NL Query Engine      │
│  40+ Visuals             │   │  Module 2 — Forecasting          │
│  10 DAX Measures         │   │  Module 3 — Anomaly Detection    │
│                          │   │  Module 4 — Insight Generator    │
└──────────────────────────┘   └──────────────────────────────────┘
```

---

## Repository Structure

```
Retail-AI-Intelligence-Platform/
│
├── 01_EDA/
│   ├── README.md
│   └── EDA.ipynb                        ← 20-step data discovery notebook
│
├── 02_DBT/
│   ├── README.md
│   ├── dbt_project.yml
│   ├── packages.yml
│   ├── profiles.yml                     ← fill in your credentials
│   └── models/
│       ├── staging/                     ← 5 models — clean raw data
│       ├── intermediate/                ← 4 models — business logic
│       └── marts/                       ← 6 models — Power BI tables
│
├── 03_AI_PLATFORM/
│   ├── README.md
│   └── retail_ai_platform.ipynb        ← 4-module AI analytics platform
│
├── 04_POWERBI/
│   ├── README.md
│   └── GlobalElectronicsRetailer.pbix  ← Power BI dashboard file
│
├── .gitignore
└── README.md                            ← you are here
```

---

## Phase 1 — Exploratory Data Analysis

**Folder:** `01_EDA/`
**Tool:** Python, Pandas, Matplotlib, Seaborn — Google Colab

A 20-step automated analysis covering dataset discovery, data quality auditing, business interpretation, and architecture planning for all downstream phases.

**Key findings:**

| Finding | Detail |
|---------|--------|
| FK Integrity | Zero orphan records across all 3 relationships |
| Data Quality | One HIGH issue — Delivery Date 79.1% null (online channel by design) |
| Inactive Customers | 3,379 customers with no orders — reactivation opportunity |
| Pareto | Top 20% of SKUs drive 70% of total revenue |
| Peak Year | 2019 at $18M — COVID caused -49% drop in 2020 |
| Top Category | Computers at 34.6% of total revenue |

---

## Phase 2 — dbt Pipeline on Snowflake

**Folder:** `02_DBT/`
**Tools:** dbt Core 1.11, Snowflake, dbt_utils

A 15-model transformation pipeline built across three layers.

### Staging Layer — 5 Models
Cleans raw data. Renames columns to snake_case, parses dates, strips dollar signs from prices, adds derived columns like age band, store type and channel flag.

### Intermediate Layer — 4 Models
Applies business logic. Joins sales to exchange rates to compute USD-normalized revenue. Calculates profit and margin per transaction. Aggregates customer CLV and RFM scores. Computes store revenue per square meter.

### Mart Layer — 6 Models
Final production tables that Power BI connects to directly.

| Model | Rows | Description |
|-------|------|-------------|
| `mart_sales_fact` | 62,884 | Primary fact table — fully enriched |
| `mart_dim_customer` | 15,266 | Customer master with RFM segments |
| `mart_dim_product` | 2,517 | Product master with ABC classification |
| `mart_dim_store` | 67 | Store master with revenue per sqm |
| `mart_dim_date` | 2,922 | Full date spine for time intelligence |
| `mart_executive_summary` | 4,025 | Pre-aggregated monthly KPIs |

### Key Transformations

| Transformation | Formula |
|----------------|---------|
| FX Normalization | `revenue_usd = (quantity × unit_price) / exchange_rate` |
| Gross Profit | `profit_usd = revenue_usd − cost_usd` |
| RFM Scoring | `NTILE(5)` on recency, frequency, monetary |
| ABC Classification | A = top 70% revenue SKUs, B = next 20%, C = tail 10% |

---

## Phase 3 — Power BI Dashboard

**Folder:** `04_POWERBI/`
**Tools:** Power BI Desktop, DAX, Snowflake connector

A 6-page interactive dashboard connected live to the Snowflake mart layer.

| Page | Purpose |
|------|---------|
| Executive Dashboard | KPI cards, revenue trend, category breakdown, country map |
| Sales Analytics | Channel split, YoY growth, category × year heatmap |
| Customer Analytics | RFM segments, CLV by country, age distribution |
| Product Performance | Top 10 SKUs, ABC donut, category treemap, margin analysis |
| Store Performance | Revenue by country, online vs physical split, country trend |
| Currency & FX Impact | Revenue by currency, FX impact, currency mix by year |

---

## Phase 4 — AI Intelligence Platform

**Folder:** `03_AI_PLATFORM/`
**Tools:** Python, Groq API, Llama 3.3 70B, Prophet, Scikit-learn, Plotly

A 4-module AI layer built directly on top of the Snowflake mart tables.

| Module | Technology | What It Does |
|--------|------------|--------------|
| NL Query Engine | Groq + Llama 3.3 70B | Converts plain English to Snowflake SQL and returns grounded answers |
| Forecasting Engine | Prophet | Predicts 6 months of revenue by category, country or channel |
| Anomaly Detector | Isolation Forest | Flags unusual sales patterns with AI-generated business explanations |
| Insight Generator | Groq + Llama 3.3 70B | Auto-generates 5 executive report types from live Snowflake data |

---

## Quick Start

### Run the EDA
```bash
# Open in Google Colab
# Upload EDA.ipynb + all 6 CSV files
# Runtime → Run all
```

### Run the dbt Pipeline
```bash
pip install dbt-snowflake
cp 02_DBT/profiles.yml ~/.dbt/profiles.yml
# Fill in your Snowflake credentials

cd 02_DBT
dbt deps
dbt run
dbt test
```

### Run the AI Platform
```bash
# Open retail_ai_platform.ipynb in Google Colab
# Fill in Groq API key and Snowflake credentials in Cell 2
# Run cells in order
```

### Open the Dashboard
```bash
# Open GlobalElectronicsRetailer.pbix in Power BI Desktop
# Update Snowflake connection with your credentials
# Refresh data
```

---

## Tech Stack

| Category | Tools |
|----------|-------|
| Language | Python, SQL |
| Data Engineering | dbt Core, Snowflake, ETL/ELT Pipelines |
| BI & Visualization | Power BI, DAX, Plotly, Matplotlib, Seaborn |
| AI & LLM | Groq API, Llama 3.3 70B, Prompt Engineering |
| Machine Learning | Prophet, Scikit-learn, Isolation Forest |
| Libraries | Pandas, NumPy, Snowflake Connector |

---

## Dataset

This project uses a publicly available global electronics retailer dataset with the following source tables:

| Table | Rows | Description |
|-------|------|-------------|
| Sales | 62,884 | Order transactions 2016–2021 |
| Customers | 15,266 | Customer demographics |
| Products | 2,517 | Product catalogue with pricing |
| Stores | 67 | Physical store locations + online channel |
| Exchange Rates | 11,215 | Daily FX rates for 5 currencies |
| Data Dictionary | 37 | Column descriptions |

---

## Author

**Srujana N Anchan**
M.E. Computer Science & Engineering
Manipal School of Information Sciences, MAHE Manipal

---

## License

This project is for educational and portfolio purposes.
