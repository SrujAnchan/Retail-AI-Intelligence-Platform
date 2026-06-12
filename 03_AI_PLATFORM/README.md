
# 03 — AI Intelligence Platform

## Overview

This folder contains the **Retail AI Intelligence Platform** — a 4-module AI layer built on top of the dbt/Snowflake data warehouse. It enables natural language querying, revenue forecasting, anomaly detection, and automated insight generation directly from the mart tables.

---

## File

| File | Description |
|------|-------------|
| `retail_ai_platform.ipynb` | Complete 4-module AI platform — run in Google Colab |

---

## Architecture

```
                     User Input
                         │
                         ▼
┌──────────────────────────────────────────────────┐
│           retail_ai_platform.ipynb               │
│                                                  │
│  ┌──────────────┐   ┌──────────────────────────┐ │
│  │  Module 1    │   │       Module 2           │ │
│  │  NL Query    │   │   Forecasting Engine     │ │
│  │  Engine      │   │   (Prophet)              │ │
│  └──────────────┘   └──────────────────────────┘ │
│  ┌──────────────┐   ┌──────────────────────────┐ │
│  │  Module 3    │   │       Module 4           │ │
│  │  Anomaly     │   │   Insight Generator      │ │
│  │  Detector    │   │   (LLM Reports)          │ │
│  └──────────────┘   └──────────────────────────┘ │
└──────────────────────┬───────────────────────────┘
                       │
                       ▼
              Snowflake Mart Tables
         (MART_SALES_FACT, MART_DIM_CUSTOMER,
          MART_DIM_PRODUCT, MART_DIM_STORE,
          MART_EXECUTIVE_SUMMARY)
```

---

## The 4 Modules

### Module 1 — Natural Language Query Engine (Cells 1–8)

Converts plain English business questions into Snowflake SQL, executes them against the mart tables, and returns human-readable answers.

| Step | What Happens |
|------|--------------|
| User types a question | e.g. "Which store had the highest revenue in 2019?" |
| LLM generates SQL | Groq Llama 3.3 70B writes valid Snowflake SQL using schema context |
| SQL runs on Snowflake | Executes against mart tables, returns a DataFrame |
| LLM formats answer | Second LLM call writes a plain English business answer with real numbers |

**Example:**
```
Question : "Which product category generated the most revenue?"
SQL      : SELECT category, ROUND(SUM(revenue_usd),2) AS total_revenue
           FROM RAW_MARTS.MART_SALES_FACT
           GROUP BY category ORDER BY total_revenue DESC LIMIT 1
Answer   : "Computers generated the most revenue at $16,623,225 —
            accounting for 37% of total revenue."
```

---

### Module 2 — Sales Forecasting Engine (Cells 9–13)

Pulls monthly revenue from Snowflake and trains a Prophet time-series model to predict the next 6 months with 95% confidence intervals.

| Feature | Detail |
|---------|--------|
| Model | Meta Prophet |
| Forecast horizon | 6 months (configurable) |
| Dimensions | Total, by Category, by Country, by Channel |
| COVID handling | Lockdown period added as a known shock event |
| Output | Interactive Plotly chart + forecast table with confidence bounds |

**Selector options:**
```
1 → Total Revenue
2 → By Category  (Computers, Audio, Cell phones, etc.)
3 → By Country   (United States, UK, Australia, etc.)
4 → By Channel   (Online, In-Store)
```

---

### Module 3 — Anomaly Detection Engine (Cells 14–20)

Uses Isolation Forest to scan revenue patterns across multiple dimensions and flags statistically unusual months. Detected anomalies are then explained by the LLM in business terms.

| Feature | Detail |
|---------|--------|
| Algorithm | Isolation Forest (scikit-learn) |
| Features used | Revenue, order count, total units, avg margin |
| Dimensions | Overall monthly, by category, by country |
| Severity labels | Critical, High, Medium, Normal |
| AI explanation | Groq LLM explains each anomaly in business context |

**Example output:**
```
Dec 2019 → SPIKE    +Holiday season sales boost
Feb 2020 → DROP     COVID-19 initial impact on supply chain
Apr 2016 → DROP     Easter holiday seasonal slump
```

---

### Module 4 — Auto Insight Generator (Cells 21–26)

Collects all KPIs from Snowflake mart tables and uses structured LLM prompting to automatically write business reports — no manual analysis required.

| Report Type | Content |
|-------------|---------|
| Executive Report | Full business overview — revenue, growth, risks, recommendations |
| Category Report | Product performance deep dive |
| Customer Report | RFM segment analysis and retention insights |
| Store Report | Geographic performance and store efficiency |
| Weekly Briefing | Short sharp summary — wins, concerns, focus areas |

**How it works:**
```
9 SQL queries → collect all KPIs from mart tables
      ↓
Structured prompt built with real data
      ↓
Groq Llama 3.3 70B writes the full report
      ↓
Report saved to downloadable .txt file
```

---

## Setup Instructions

### 1. Prerequisites

You need:
- A free **Groq API key** — sign up at [console.groq.com](https://console.groq.com)
- Access to the **Snowflake mart tables** built in `02_DBT`

### 2. Open in Google Colab

1. Go to [colab.research.google.com](https://colab.research.google.com)
2. Upload `retail_ai_platform.ipynb`
3. Fill in your credentials in **Cell 2**:

```python
GROQ_API_KEY = "your_groq_api_key_here"

SNOWFLAKE_CONFIG = {
    "account":   "your_snowflake_account_identifier",
    "user":      "your_snowflake_username",
    "password":  "your_snowflake_password",
    "warehouse": "COMPUTE_WH",
    "database":  "RETAIL_RAW",
    "schema":    "RAW_MARTS",
}
```

> ⚠️ Never share or commit your credentials. Keep Cell 2 private.

### 3. Run the Modules

Run cells in order. Each module is clearly labelled:

| Cells | Module |
|-------|--------|
| 1 – 8 | Module 1 — NL Query Engine |
| 9 – 13 | Module 2 — Forecasting Engine |
| 14 – 20 | Module 3 — Anomaly Detection |
| 21 – 26 | Module 4 — Insight Generator |

---

## Cell Reference

| Cell | Purpose |
|------|---------|
| 1 | Install all dependencies |
| 2 | Configuration — credentials and settings |
| 3 | Snowflake connection and query runner |
| 4 | Schema context for the LLM |
| 5 | Groq LLM functions (generate SQL + generate answer) |
| 6 | Main chat function |
| 7 | Test with sample questions |
| 8 | Interactive chat loop |
| 9 | Install forecasting dependencies (Prophet, Plotly) |
| 10 | Forecasting data loader from Snowflake |
| 11 | Prophet model training and prediction |
| 12 | Plotly forecast visualisation |
| 13 | Interactive forecast selector |
| 14 | Install anomaly detection dependencies |
| 15 | Anomaly data loader (monthly / store / category) |
| 16 | Isolation Forest detector with severity scoring |
| 17 | Anomaly visualisation with red markers |
| 18 | Full multi-dimension anomaly scan |
| 19 | Interactive anomaly explorer |
| 20 | AI-powered anomaly explanation |
| 21 | Business snapshot collector (9 SQL queries) |
| 22 | Insight prompt builder (5 report types) |
| 23 | AI insight generator — Executive Report |
| 24 | All report types selector |
| 25 | Save report to downloadable file |
| 26 | Daily briefing generator |

---

## Tech Stack

| Tool | Purpose |
|------|---------|
| Python | Core language |
| Groq API | LLM inference (fast, free tier available) |
| Llama 3.3 70B | Language model for SQL generation and report writing |
| Prophet | Time-series forecasting |
| Scikit-learn | Isolation Forest anomaly detection |
| Snowflake Connector | Query mart tables directly from Python |
| Plotly | Interactive forecast and anomaly charts |
| Pandas | Data handling and transformation |

---

## Sample Questions for Module 1

```
"What is the total revenue across all years?"
"Which product category generated the most revenue?"
"Which country had the highest number of orders?"
"What are the top 5 products by revenue?"
"How many customers are in the Champions RFM segment?"
"What was the revenue in 2019 vs 2020?"
"Which store had the highest revenue per square meter?"
"What is the revenue split between Online and In-Store channels?"
```
