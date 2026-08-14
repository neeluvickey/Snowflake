# 🗄️ Snowflake Table Types — The Complete Landscape

Every table you create in Snowflake carries specific data protection and storage characteristics depending on its **type**. But most people only know about 2 or 3 types — Snowflake actually supports **eight distinct table types**. Understanding the full landscape is critical for cost optimization and proper data lifecycle management.

## 📊 The Full Table Type Family

| # | Type | One-Line Description |
|---|------|---------------------|
| 1 | **Permanent** (default) | Full Time Travel + Fail-safe. Production data. |
| 2 | **Transient** | Reduced protection, no Fail-safe. Staging/replaceable data. |
| 3 | **Temporary** | Session-scoped. Auto-dropped. Scratch work. |
| 4 | **External** | Read-only over files in cloud storage (S3/Azure/GCS). |
| 5 | **Dynamic** | Declarative pipelines with automatic refresh. |
| 6 | **Iceberg** | Open table format (Apache Iceberg) with Snowflake compute. |
| 7 | **Hybrid** | Transactional (OLTP) workloads via Unistore. |
| 8 | **Event** | Optimized for high-volume append-only event/log data. |

### Quick Overview of Types 4–8

**External Tables** — Query files sitting in S3, Azure Blob, or GCS without loading them into Snowflake. Read-only, schema-on-read. Great for data lake integration where you want to query raw files in place. Supports auto-refresh via event notifications when new files land.

**Dynamic Tables** — Define a transformation as a `SELECT` statement, and Snowflake automatically keeps the results fresh. No need to write merge/insert logic or schedule tasks manually. You set a `TARGET_LAG` (e.g., "5 minutes") and Snowflake handles incremental refresh. Ideal for declarative ELT pipelines.

**Iceberg Tables** — Apache Iceberg open table format managed by Snowflake. Your data stays in open Parquet files on your own cloud storage, but you get full Snowflake DML (INSERT, UPDATE, DELETE, MERGE). Enables interoperability with Spark, Flink, Trino, and other engines reading the same data.

**Hybrid Tables** — Purpose-built for transactional (OLTP) workloads via Snowflake's Unistore engine. Support fast single-row lookups, primary keys with enforced uniqueness, secondary indexes, and row-level locking. Use when you need low-latency point reads/writes alongside analytical queries in one platform.

**Event Tables** — Optimized for high-throughput, append-only ingestion of telemetry, logs, and event streams. Used by Snowflake internally for logging (e.g., `SNOWFLAKE.TELEMETRY.EVENTS`). Support structured and semi-structured event data with minimal write latency. Designed for observability and audit use cases.

> **This post** deep-dives into types 1–3 (the persistence-based types). External, Dynamic, Iceberg, Hybrid, and Event tables each get their own dedicated post later in Phase 3.

## 🔷 Why This Matters

- **Storage costs** scale with data protection features — Fail-safe and extended Time Travel store additional copies of your data behind the scenes
- Choosing the wrong table type for staging data can **double or triple** your storage bill with no practical benefit
- Temporary data that outlives its usefulness wastes credits on protection it will never need

## 🏷️ Core Concept

Snowflake offers **three core table types**, each with different levels of data protection:

### Permanent Tables (Default)

**Permanent tables** are the default when you run `CREATE TABLE`. They provide the highest level of data protection:

- **Time Travel**: Configurable from 0 to 90 days (Enterprise Edition+; 1 day on Standard)
- **Fail-safe**: 7 additional days of data recovery by Snowflake Support (non-configurable, always on)
- **Persistence**: Table and data persist until explicitly dropped

Use permanent tables for production data, business-critical records, regulatory/compliance data, and anything you cannot afford to lose.

### Transient Tables

**Transient tables** reduce storage costs by eliminating Fail-safe:

- **Time Travel**: 0 or 1 day only (cannot exceed 1)
- **Fail-safe**: None
- **Persistence**: Table persists until explicitly dropped (survives sessions)

Use transient tables for staging/landing zones, intermediate ETL results, data you can easily reload from source, and development/test tables.

### Temporary Tables

**Temporary tables** are the most ephemeral option:

- **Time Travel**: 0 or 1 day (within the session only)
- **Fail-safe**: None
- **Persistence**: Dropped automatically when the session ends
- **Visibility**: Only visible to the session that created them (no naming conflicts with other sessions)

Use temporary tables for session-scoped scratch work, ad-hoc analysis, intermediate transformations within a stored procedure, and testing.

## 📊 Comparison / Feature Matrix

| Feature | Permanent | Transient | Temporary |
|---------|-----------|-----------|-----------|
| Time Travel | 0–90 days (Enterprise+) | 0–1 day | 0–1 day |
| Fail-safe | 7 days (always) | None | None |
| Persists across sessions | Yes | Yes | No |
| Visible to other sessions | Yes | Yes | No |
| Storage cost | Highest | Medium | Lowest |
| Cloning supported | Yes | Yes | Yes |
| Can be part of a schema | Any schema type | Any schema type | Any schema type |

> **Note:** A temporary table can have the same name as a permanent/transient table in the same schema. The temporary table takes precedence for that session, effectively "shadowing" the persistent table.

## ⚙️ Configuration & Parameters

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `DATA_RETENTION_TIME_IN_DAYS` | 1 (Standard), 1 (Enterprise) | 0–90 (Permanent, Enterprise+), 0–1 (Transient/Temporary) | Number of days Time Travel data is retained |
| `CHANGE_TRACKING` | FALSE | TRUE/FALSE | Enables change tracking for streams |

### Transient/Temporary Databases and Schemas

You can also create **transient databases** and **transient schemas**. Every table created inside a transient database or schema automatically inherits the transient property:

```sql
CREATE TRANSIENT DATABASE staging_db;
CREATE TRANSIENT SCHEMA my_db.staging_schema;
```

> **Important:** You cannot create a permanent table inside a transient schema. All objects inherit the parent's transience.

## 🛠️ SQL Examples

### Basic Usage — Permanent Table

```sql
CREATE OR REPLACE TABLE orders_permanent (
  id INT AUTOINCREMENT,
  customer_name VARCHAR(100),
  order_total NUMBER(10,2),
  created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) DATA_RETENTION_TIME_IN_DAYS = 7;
```

Standard permanent table with 7-day Time Travel. No keyword needed — permanent is the default.

### Basic Usage — Transient Table

```sql
CREATE OR REPLACE TRANSIENT TABLE staging_events (
  id INT AUTOINCREMENT,
  event_data VARCHAR(500),
  loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
```

Transient table for staging. No Fail-safe storage cost. Data can be reloaded from source if lost.

### Basic Usage — Temporary Table

```sql
CREATE OR REPLACE TEMPORARY TABLE session_cache (
  session_id VARCHAR(50),
  temp_data VARIANT
);
```

Session-scoped scratch table. Automatically dropped when the session ends.

### Modification / Management

```sql
-- Check table type
SHOW TABLES LIKE 'orders_permanent';
-- Look at the "kind" column in results: TABLE, TRANSIENT, or TEMPORARY

-- Change Time Travel retention on a permanent table
ALTER TABLE orders_permanent SET DATA_RETENTION_TIME_IN_DAYS = 30;

-- Convert is NOT supported: you cannot ALTER a permanent table to transient
-- Instead, recreate: CREATE OR REPLACE TRANSIENT TABLE ... AS SELECT * FROM ...;
```

## 💰 Cost Implications

Storage cost differences come from **additional copies** Snowflake maintains:

| Protection Layer | Storage Multiplier | Applies To |
|-----------------|-------------------|------------|
| Active storage | 1x | All table types |
| Time Travel | Up to 1x additional (per day retained) | All types (if retention > 0) |
| Fail-safe | Up to 1x additional (7 days) | Permanent tables only |

### Cost Optimization Strategies

1. **Use transient tables for staging** — if you reload data daily from S3/Azure/GCS, Fail-safe protection on that staging table is wasted money
2. **Set `DATA_RETENTION_TIME_IN_DAYS = 0`** on transient tables holding truly disposable data to eliminate even the 1-day Time Travel cost
3. **Use transient schemas** for entire landing/staging layers rather than marking tables individually

## 🔑 Key Takeaways

| | Concept | Summary |
|---|---------|---------|
| 📦 | Permanent | Full protection (Time Travel + Fail-safe). Default. Use for production. |
| ⚡ | Transient | Reduced protection (Time Travel only, max 1 day). Use for staging/replaceable data. |
| 🔒 | Temporary | Session-only. Invisible to others. Auto-dropped. Use for scratch work. |
| 🔄 | Inheritance | Transient DBs/schemas make all child objects transient automatically. |
| 📈 | Cost impact | Fail-safe alone can add ~7x daily change storage on active permanent tables. |

## 💡 Best Practices

### For Development/Testing

- Use **temporary tables** for ad-hoc queries and exploratory analysis
- Use **transient schemas** for your dev/test environments to avoid unnecessary Fail-safe charges
- Remember temporary tables shadow permanent ones with the same name — useful for testing without modifying production

### For Production

- Use **permanent tables** for all business-critical data with `DATA_RETENTION_TIME_IN_DAYS` set to at least 7
- Use **transient tables** for landing/staging zones that are reloaded from external sources
- Create a **transient database** (e.g., `STAGING_DB`) to enforce transience across your entire staging layer
- Document table type decisions in your data architecture guide

### Common Mistakes to Avoid

- ❌ Using permanent tables for staging data you reload daily (wastes Fail-safe storage)
- ❌ Assuming you can convert a permanent table to transient with ALTER (you must recreate)
- ❌ Setting `DATA_RETENTION_TIME_IN_DAYS = 90` on all tables "just in case" (massive storage cost)
- ❌ Forgetting that temporary tables are session-scoped — other users and sessions cannot see them

## 📊 Monitoring & Diagnostics

```sql
-- Check table types in a schema
SHOW TABLES IN SCHEMA my_db.my_schema;
-- Review the "kind" column: TABLE (permanent), TRANSIENT, or TEMPORARY

-- Monitor storage usage including Time Travel and Fail-safe
SELECT
  TABLE_CATALOG,
  TABLE_SCHEMA,
  TABLE_NAME,
  ROUND(ACTIVE_BYTES / (1024*1024*1024), 2) AS ACTIVE_GB,
  ROUND(TIME_TRAVEL_BYTES / (1024*1024*1024), 2) AS TIME_TRAVEL_GB,
  ROUND(FAILSAFE_BYTES / (1024*1024*1024), 2) AS FAILSAFE_GB
FROM SNOWFLAKE.ACCOUNT_USAGE.TABLE_STORAGE_METRICS
WHERE ACTIVE_BYTES > 0
ORDER BY FAILSAFE_BYTES DESC
LIMIT 20;
```

## 🔗 Related Topics

- **External Tables** (Post #24) — read-only tables over files in cloud storage
- **Iceberg Tables** (Post #25) — open table format with Snowflake compute
- **Dynamic Tables** (Post #27) — declarative pipelines with automatic refresh
- [Snowflake Docs: Table Types](https://docs.snowflake.com/en/user-guide/tables-temp-transient) — official reference

---

This is Post 19 of my Snowflake LinkedIn Series — Phase 3: Tables & Data Types.

🔔 Follow along to master Snowflake, one concept at a time.

Next up → Poll: Which table type do you use most in your staging layer? 📊

#Snowflake #TableTypes #DataEngineering #SQL #TimeTravel #CloudData #SnowflakeLinkedInSeries

