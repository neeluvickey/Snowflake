# ⚙️ Virtual Warehouses — Snowflake's Compute Engine Explained

You've heard "separate storage and compute." But what does compute actually look like in Snowflake?

It's called a **Virtual Warehouse**. Let's break it down 👇

---

A Virtual Warehouse is a cluster of compute resources that executes queries, loads data, and runs transformations.

It does **NOT** store data. It only processes it.

Think of it as an on-demand engine you can start, stop, resize, and multiply — without touching a single byte of your stored data.

---

## 🔷 Why Virtual Warehouses Matter

In traditional systems, adding more users = slower queries for everyone. Resources are shared and contention is inevitable.

In Snowflake:
- Each warehouse is **fully isolated** — dedicated compute, no shared resources
- One team's heavy workload **does not affect** another team's performance
- You can spin up dedicated warehouses per team, per workload, or per priority level
- Multiple warehouses can query the **same data** simultaneously with zero contention

This is the power of **compute isolation** — made possible by Snowflake's separation of storage and compute.

---

## 🏷️ Warehouse Types

Snowflake offers **3 warehouse types**, each optimized for different workload patterns:

| Type | Description | Best For |
|------|-------------|----------|
| ✅ **Standard** | General-purpose compute with balanced CPU and memory | Analytics queries, data engineering, ETL/ELT, reporting |
| ✅ **Snowpark-Optimized** | 16x more memory per node than Standard | ML model training, large DataFrames, memory-intensive UDFs, Python/Java/Scala workloads |
| ✅ **Interactive** | Optimized query engine for low-latency, high-concurrency | Real-time dashboards, data-powered APIs, alerting, agentic AI workloads |

### Standard Warehouse
The default type. Works for 90%+ of analytics and engineering workloads. Supports multi-cluster scaling, all warehouse sizes (XS–6XL), and both Gen1/Gen2 generations.

### Snowpark-Optimized Warehouse
Designed for workloads that need to hold large datasets in memory — ML training, complex transformations, and UDFs that process large data volumes. Has a higher credit cost per hour due to the additional memory resources.

### Interactive Warehouse
A newer warehouse type purpose-built for **serving workloads**:
- Optimized for queries that need **sub-second to low-second latency**
- Handles **thousands of concurrent requests** efficiently
- Pairs with **Interactive Tables** for best performance
- Ideal for powering dashboards (e.g., Streamlit, Tableau), REST APIs, observability/alerting systems, and AI agent tool calls
- Predictable, consistent latency even under unpredictable query spikes

```sql
-- Create an Interactive warehouse
CREATE WAREHOUSE dashboard_wh
  WAREHOUSE_TYPE = 'INTERACTIVE'
  WAREHOUSE_SIZE = 'MEDIUM'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE;
```

---

## 🆕 Gen1 vs Gen2 (Warehouse Generations)

Standard warehouses now come in **two generations**:

| Aspect | Gen1 | Gen2 |
|--------|------|------|
| **Architecture** | Original Snowflake compute | Newer hardware + software optimizations |
| **Performance** | Baseline | Faster DML, improved table scans, better overall throughput |
| **Query Acceleration (QAS)** | Must enable manually | Enabled by default |
| **Availability** | All sizes (XS–6XL) | XS through 4XL (5XL/6XL not yet supported) |
| **Applies to** | Standard warehouses only | Standard warehouses only |
| **Credit rates** | See table below | Different rates — check Service Consumption Table |
| **Default for new accounts** | Legacy accounts | Becoming the default |

### When to use Gen2:
- New workloads — start with Gen2 by default
- ETL/ELT jobs that are DML-heavy (INSERT, MERGE, COPY)
- Queries that scan large tables
- Workloads that benefit from Query Acceleration

### When to stay on Gen1:
- If your warehouse size is 5XL or 6XL
- Snowpark-optimized warehouses (Gen2 doesn't apply)
- If you need to validate cost impact before switching

### Specifying Generation

```sql
-- At creation time (recommended)
CREATE WAREHOUSE my_wh
  WAREHOUSE_TYPE = 'STANDARD'
  GENERATION = '2'
  WAREHOUSE_SIZE = 'LARGE';

-- Alternative: using RESOURCE_CONSTRAINT
CREATE WAREHOUSE my_wh
  RESOURCE_CONSTRAINT = STANDARD_GEN_2
  WAREHOUSE_SIZE = 'LARGE';

-- Convert an existing warehouse
ALTER WAREHOUSE my_wh SET GENERATION = '2';

-- Check current generation
SHOW WAREHOUSES LIKE 'MY_WH';
-- Look at the "generation" column in results
```

---

## 📏 Warehouse Sizes & Credit Consumption

### Gen1 Credits/Hour

| Size | Credits/Hr | Credits/Second |
|------|-----------|----------------|
| XS (X-Small) | 1 | 0.0003 |
| S (Small) | 2 | 0.0006 |
| M (Medium) | 4 | 0.0011 |
| L (Large) | 8 | 0.0022 |
| XL (X-Large) | 16 | 0.0044 |
| 2XL | 32 | 0.0089 |
| 3XL | 64 | 0.0178 |
| 4XL | 128 | 0.0356 |
| 5XL | 256 | 0.0711 |
| 6XL | 512 | 0.1422 |

> **Note:** Gen2 has different credit consumption rates. Refer to the [Snowflake Service Consumption Table](https://docs.snowflake.com/en/user-guide/credits) for current Gen2 pricing.

> **Note:** Snowpark-optimized warehouses cost ~1.5x more credits per hour than Standard at the same size.

**Key points:**
- Each size **doubles** the compute power AND the cost
- Billing is **per-second** with a **60-second minimum** each time the warehouse starts
- XS is the default for `CREATE WAREHOUSE`
- **Rule of thumb:** Bigger = faster individual queries, NOT more concurrent queries. For concurrency, scale OUT (multi-cluster).

---

## ⏸️ Auto-Suspend & Auto-Resume

Two properties that save you money every single day:

### AUTO_SUSPEND
- Warehouse shuts down after X seconds of inactivity
- Default: **600 seconds** (10 minutes)
- Minimum: **60 seconds** (1 minute) for Standard/Interactive; **0** to never suspend
- When suspended, you pay **zero credits**

### AUTO_RESUME
- Warehouse automatically starts when a new query arrives
- Default: **TRUE**
- If set to FALSE, you must manually resume with `ALTER WAREHOUSE ... RESUME`

### Recommendations by environment:

| Environment | AUTO_SUSPEND | Rationale |
|-------------|-------------|-----------|
| Development | 60s | Minimal idle time, fast iteration |
| Production (BI) | 300s | Avoid frequent cold starts for dashboards |
| ETL/Batch | 60s | Jobs have clear start/end, no idle needed |
| Interactive WH | 60–120s | Designed for fast resume anyway |

```sql
-- Aggressive savings for dev
ALTER WAREHOUSE dev_wh SET AUTO_SUSPEND = 60;

-- Check current settings
SHOW WAREHOUSES LIKE 'DEV_WH';
```

---

## 📈 Scaling Up vs Scaling Out (Multi-Cluster Warehouses)

### Scaling UP (Vertical)
- Increase warehouse SIZE (e.g., Small → Medium → Large)
- Makes individual queries **run faster**
- Use when queries are slow or spilling to disk
- Linear cost increase (each size = 2x credits)

### Scaling OUT (Horizontal — Multi-Cluster)
- Add more clusters of the **same size**
- Handles more **concurrent users/queries**
- Use when queries are queueing (not slow individually)
- Enterprise Edition+ feature

```sql
-- Multi-cluster warehouse with auto-scaling
CREATE WAREHOUSE bi_reporting_wh
  WAREHOUSE_TYPE = 'STANDARD'
  GENERATION = '2'
  WAREHOUSE_SIZE = 'MEDIUM'
  MIN_CLUSTER_COUNT = 1
  MAX_CLUSTER_COUNT = 5
  SCALING_POLICY = 'STANDARD'
  AUTO_SUSPEND = 300
  AUTO_RESUME = TRUE;
```

**Scaling Policies:**
| Policy | Behavior |
|--------|----------|
| `STANDARD` | Adds clusters conservatively, shuts down aggressively (cost-efficient) |
| `ECONOMY` | Waits longer before adding clusters, keeps them running longer (fewer starts/stops) |

---

## 🛠️ CREATE Warehouse — Complete Syntax Reference

```sql
CREATE [ OR REPLACE ] WAREHOUSE [ IF NOT EXISTS ] <name>
  [ WAREHOUSE_TYPE = 'STANDARD' | 'SNOWPARK-OPTIMIZED' | 'INTERACTIVE' ]
  [ GENERATION = '1' | '2' ]
  [ WAREHOUSE_SIZE = 'XSMALL' | 'SMALL' | 'MEDIUM' | 'LARGE' | ... ]
  [ AUTO_SUSPEND = <seconds> ]
  [ AUTO_RESUME = TRUE | FALSE ]
  [ MIN_CLUSTER_COUNT = <num> ]
  [ MAX_CLUSTER_COUNT = <num> ]
  [ SCALING_POLICY = 'STANDARD' | 'ECONOMY' ]
  [ INITIALLY_SUSPENDED = TRUE | FALSE ]
  [ RESOURCE_MONITOR = '<monitor_name>' ]
  [ COMMENT = '<string>' ]
  [ ENABLE_QUERY_ACCELERATION = TRUE | FALSE ]
  [ QUERY_ACCELERATION_MAX_SCALE_FACTOR = <num> ]
  [ TAG ( <tag_name> = '<tag_value>' [ , ... ] ) ];
```

### Example: Production Analytics Warehouse

```sql
CREATE WAREHOUSE prod_analytics_wh
  WAREHOUSE_TYPE = 'STANDARD'
  GENERATION = '2'
  WAREHOUSE_SIZE = 'LARGE'
  AUTO_SUSPEND = 300
  AUTO_RESUME = TRUE
  MIN_CLUSTER_COUNT = 1
  MAX_CLUSTER_COUNT = 3
  SCALING_POLICY = 'STANDARD'
  ENABLE_QUERY_ACCELERATION = TRUE
  QUERY_ACCELERATION_MAX_SCALE_FACTOR = 8
  RESOURCE_MONITOR = 'prod_monitor'
  COMMENT = 'Production BI and analytics queries'
  TAG (cost_center = 'analytics', team = 'data-platform');
```

### Example: Snowpark ML Warehouse

```sql
CREATE WAREHOUSE ml_training_wh
  WAREHOUSE_TYPE = 'SNOWPARK-OPTIMIZED'
  WAREHOUSE_SIZE = 'MEDIUM'
  AUTO_SUSPEND = 120
  AUTO_RESUME = TRUE
  COMMENT = 'ML model training and feature engineering';
```

### Example: Interactive Dashboard Warehouse

```sql
CREATE WAREHOUSE dashboard_serving_wh
  WAREHOUSE_TYPE = 'INTERACTIVE'
  WAREHOUSE_SIZE = 'MEDIUM'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  COMMENT = 'Low-latency serving for Streamlit dashboards';
```

---

## 🔑 Key Concepts Summary

| | Concept | Description |
|---|---|---|
| 📦 | **Warehouse** | Compute cluster (NOT storage) — processes queries only |
| 🏷️ | **Type** | Standard, Snowpark-Optimized, or Interactive |
| 🆕 | **Generation** | Gen1 (original) or Gen2 (faster, modern) |
| ⚡ | **Scaling UP** | Bigger size = Faster individual queries |
| 📈 | **Scaling OUT** | Multi-cluster = More concurrent users |
| ⏱️ | **Billing** | Per-second with 60-second minimum on resume |
| 🔒 | **Isolation** | Each warehouse runs independently — no resource contention |
| 🔄 | **Elasticity** | Resize on the fly without restarting or losing in-flight queries |
| ⏸️ | **Auto-Suspend** | Stops billing when idle (configurable threshold) |
| ▶️ | **Auto-Resume** | Starts transparently on next query |

---

## 💡 Best Practices

### Workload Separation
- Create **dedicated warehouses** per workload type (ETL vs BI vs Ad-hoc vs ML)
- Prevents noisy-neighbor problems and simplifies cost attribution
- Use naming conventions: `etl_wh`, `bi_reporting_wh`, `ds_training_wh`

### Sizing Strategy
- Start with **XS or S** — scale up only if queries are slow or spilling
- Monitor `BYTES_SPILLED_TO_LOCAL_STORAGE` and `BYTES_SPILLED_TO_REMOTE_STORAGE`
- If spilling is high → increase warehouse size
- If queries are queueing → add multi-cluster (scale out)

### Generation Strategy
- Use **Gen2** for all new workloads — it's faster at the same credit cost
- Test Gen2 on existing workloads before switching production
- Monitor `WAREHOUSE_METERING_HISTORY` before/after switch

### Cost Control
- Set `AUTO_SUSPEND = 60` for non-production warehouses
- Use `RESOURCE_MONITOR` to set credit quotas and alerts
- Use `INITIALLY_SUSPENDED = TRUE` for warehouses that shouldn't start on creation
- Review `WAREHOUSE_METERING_HISTORY` weekly for idle/underused warehouses

### Interactive Warehouse Tips
- Pair with **Interactive Tables** for sub-second query latency
- Ideal for Streamlit apps, REST APIs, and agentic AI tool execution
- Don't use for heavy ETL — that's what Standard warehouses are for

### Monitoring Queries

```sql
-- Check credit usage by warehouse (last 30 days)
SELECT warehouse_name, SUM(credits_used) AS total_credits
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE start_time >= DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY warehouse_name
ORDER BY total_credits DESC;

-- Check for spilling (indicates warehouse too small)
SELECT query_id, warehouse_name, warehouse_size,
       bytes_spilled_to_local_storage, bytes_spilled_to_remote_storage
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE bytes_spilled_to_remote_storage > 0
  AND start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
ORDER BY bytes_spilled_to_remote_storage DESC
LIMIT 20;

-- Check for queueing (indicates need for multi-cluster)
SELECT warehouse_name, AVG(queued_overload_time) AS avg_queue_ms
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
  AND queued_overload_time > 0
GROUP BY warehouse_name
ORDER BY avg_queue_ms DESC;
```

---

*This is Post 11 of my Snowflake LinkedIn Series — kicking off Phase 2: Virtual Warehouses & Compute.*

🔔 Follow along to master Snowflake, one concept at a time.

**Next up → Poll: What warehouse size do you use most? 📊**

---

`#Snowflake #VirtualWarehouse #DataEngineering #CloudCompute #SQL #SnowflakeLinkedInSeries`
