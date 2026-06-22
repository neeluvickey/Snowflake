# 📊 Warehouse Sizing — A Complete Guide to Choosing the Right Size

Warehouse sizing is one of the most impactful decisions you'll make in Snowflake. Pick too small and queries crawl. Pick too large and you burn credits on idle compute. This guide covers everything you need to make the right call for every workload.

---

## 🔷 Why This Matters

Warehouse size directly affects two things: **query performance** and **cost**.

- Every size-up doubles your compute power AND your credit consumption
- Per-second billing (60-second minimum) means right-sizing saves real money
- Unlike traditional databases, you can resize instantly without downtime
- Poor sizing is the #1 cause of unexpectedly high Snowflake bills

---

## 🏷️ Core Concept: Warehouse Sizes

A **Virtual Warehouse** is a named compute cluster. Its **size** determines how many servers (nodes) are allocated to process queries.

### Size Spectrum (Gen1 Credits/Hour)

| Size | Credits/Hour | Nodes | Typical Use Case |
|------|-------------|-------|------------------|
| `X-Small` | 1 | 1 | Dev/test, light queries, single-user exploration |
| `Small` | 2 | 2 | BI dashboards, scheduled reports, moderate analytics |
| `Medium` | 4 | 4 | Production ETL, dbt runs, multi-table joins |
| `Large` | 8 | 8 | Heavy transforms, large aggregations, data loads |
| `X-Large` | 16 | 16 | Complex analytics, large-scale ELT pipelines |
| `2X-Large` | 32 | 32 | Massive joins, high-volume ingestion |
| `3X-Large` | 64 | 64 | Extreme workloads, full-table scans on TB+ tables |
| `4X-Large` | 128 | 128 | Rare: very large batch operations |
| `5X-Large` | 256 | 256 | Rare: exceptional scale (Gen1 only) |
| `6X-Large` | 512 | 512 | Rare: maximum single-cluster power (Gen1 only) |

> **Note:** Gen2 warehouses deliver better performance at the same size due to hardware and software optimizations. Gen2 is currently available up to 4XL.

### How Sizing Works Internally

Each size-up doubles the number of compute nodes. More nodes means:

- More parallel processing threads
- More memory for intermediate results
- More local SSD cache for micro-partition data
- Faster scanning of large datasets

But it does NOT help with:

- Queries that are already fast (< 2 seconds)
- Single-row lookups or point queries
- Queries bottlenecked by network or client-side processing

---

## 📊 Choosing the Right Size: Decision Matrix

| Workload Type | Recommended Start | Scale Trigger |
|--------------|-------------------|---------------|
| Dev/test exploration | XS | N/A (keep small) |
| BI dashboard refresh | S or M | Query SLA > 10s |
| Scheduled reporting | S | Query time > 30s |
| dbt models (< 50 models) | M | Run time > 15 min |
| dbt models (50-200 models) | L | Run time > 30 min |
| Production ETL (hourly) | M or L | Data volume growth |
| Large data loads (COPY INTO) | L or XL | Load time > SLA |
| ML feature engineering | L or XL (Snowpark-optimized) | Memory spills |
| Ad-hoc analyst queries | S or M | User complaints |
| API-serving (low latency) | S (Interactive type) | p95 > 2s |

---

## ⚙️ Configuration & Parameters

### CREATE WAREHOUSE with Sizing

```sql
-- X-Small for development
CREATE WAREHOUSE dev_wh
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

-- Medium for production ETL
CREATE WAREHOUSE etl_wh
  WAREHOUSE_SIZE = 'MEDIUM'
  WAREHOUSE_TYPE = 'STANDARD'
  AUTO_SUSPEND = 120
  AUTO_RESUME = TRUE
  MIN_CLUSTER_COUNT = 1
  MAX_CLUSTER_COUNT = 2
  SCALING_POLICY = 'STANDARD';

-- Large Snowpark-optimized for ML workloads
CREATE WAREHOUSE ml_wh
  WAREHOUSE_SIZE = 'LARGE'
  WAREHOUSE_TYPE = 'SNOWPARK-OPTIMIZED'
  AUTO_SUSPEND = 300
  AUTO_RESUME = TRUE;
```

### Resizing On-the-Fly

```sql
-- Resize without interruption (takes effect on next query)
ALTER WAREHOUSE etl_wh SET WAREHOUSE_SIZE = 'LARGE';

-- Check current size
SHOW WAREHOUSES LIKE 'ETL_WH';
```

> **Important:** Resizing up takes effect immediately for new queries. Running queries continue on the old size. Resizing down waits for running queries to complete before releasing nodes.

---

## 📈 Scaling Strategy: Up vs Out

### Scale UP (bigger size) when:

- Individual queries are slow
- You see high `BYTES_SPILLED_TO_LOCAL_STORAGE` or `BYTES_SPILLED_TO_REMOTE_STORAGE`
- Execution time is dominated by scanning/processing (not queuing)
- You have complex joins or aggregations on large tables

### Scale OUT (multi-cluster) when:

- Queries are queuing (waiting for resources)
- Many concurrent users/sessions
- Dashboard serving with unpredictable spikes
- Individual query performance is acceptable but throughput is the issue

### When Neither Helps

- **Query is already fast** (< 1s): Overhead dominates; bigger won't help
- **Bad query plan**: Fix the SQL first (add filters, reduce joins)
- **Missing clustering**: Table scans are the issue, not compute
- **Network bottleneck**: Large result sets transferring to client

---

## 💰 Cost Analysis

### Monthly Cost Estimates (assuming 8 hours/day active)

| Size | Credits/Hour | Daily (8h) | Monthly (22 days) | Annual |
|------|-------------|------------|-------------------|--------|
| XS | 1 | 8 | 176 | 2,112 |
| S | 2 | 16 | 352 | 4,224 |
| M | 4 | 32 | 704 | 8,448 |
| L | 8 | 64 | 1,408 | 16,896 |
| XL | 16 | 128 | 2,816 | 33,792 |

> *At $3/credit (Standard Edition, on-demand). Actual rates vary by edition, region, and contract.*

### Cost Optimization Strategies

1. **Right-size per workload**: Don't use one L warehouse for everything. Use XS for dev, M for ETL, S for BI
2. **Auto-suspend aggressively**: Set to 60s for interactive, 120-300s for batch
3. **Use per-second billing**: Short bursts on a large warehouse can be cheaper than long runs on a small one
4. **Monitor spilling**: If queries spill to remote storage, sizing up often reduces total credits consumed (faster completion = fewer credits)
5. **Schedule workloads**: Run heavy ETL during off-peak, suspend during idle hours

---

## 🛠️ Diagnostic Queries

### Find Your Actual Warehouse Usage Pattern

```sql
-- Average query time by warehouse and size
SELECT
  WAREHOUSE_NAME,
  WAREHOUSE_SIZE,
  COUNT(*) AS query_count,
  AVG(TOTAL_ELAPSED_TIME)/1000 AS avg_seconds,
  MEDIAN(TOTAL_ELAPSED_TIME)/1000 AS median_seconds,
  MAX(TOTAL_ELAPSED_TIME)/1000 AS max_seconds
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE START_TIME > DATEADD('day', -7, CURRENT_TIMESTAMP())
  AND WAREHOUSE_NAME IS NOT NULL
  AND EXECUTION_STATUS = 'SUCCESS'
GROUP BY WAREHOUSE_NAME, WAREHOUSE_SIZE
ORDER BY avg_seconds DESC;
```

### Detect Queries That Need a Bigger Warehouse (Spilling)

```sql
-- Queries spilling to disk (candidates for size-up)
SELECT
  QUERY_ID,
  WAREHOUSE_NAME,
  WAREHOUSE_SIZE,
  TOTAL_ELAPSED_TIME/1000 AS seconds,
  BYTES_SPILLED_TO_LOCAL_STORAGE/(1024*1024*1024) AS spill_local_gb,
  BYTES_SPILLED_TO_REMOTE_STORAGE/(1024*1024*1024) AS spill_remote_gb
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE START_TIME > DATEADD('day', -7, CURRENT_TIMESTAMP())
  AND (BYTES_SPILLED_TO_LOCAL_STORAGE > 0 OR BYTES_SPILLED_TO_REMOTE_STORAGE > 0)
ORDER BY BYTES_SPILLED_TO_REMOTE_STORAGE DESC
LIMIT 20;
```

### Identify Over-Provisioned Warehouses (idle time)

```sql
-- Warehouses with low utilization (potential to downsize)
SELECT
  WAREHOUSE_NAME,
  SUM(CREDITS_USED) AS total_credits_7d,
  COUNT(DISTINCT DATE_TRUNC('hour', START_TIME)) AS active_hours,
  SUM(CREDITS_USED) / NULLIF(COUNT(DISTINCT DATE_TRUNC('hour', START_TIME)), 0) AS credits_per_active_hour
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE START_TIME > DATEADD('day', -7, CURRENT_TIMESTAMP())
GROUP BY WAREHOUSE_NAME
ORDER BY total_credits_7d DESC;
```

### Check Queuing (Need to Scale Out)

```sql
-- Queries that spent time queuing
SELECT
  WAREHOUSE_NAME,
  COUNT(*) AS queued_queries,
  AVG(QUEUED_OVERLOAD_TIME)/1000 AS avg_queue_seconds,
  MAX(QUEUED_OVERLOAD_TIME)/1000 AS max_queue_seconds
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE START_TIME > DATEADD('day', -7, CURRENT_TIMESTAMP())
  AND QUEUED_OVERLOAD_TIME > 0
GROUP BY WAREHOUSE_NAME
ORDER BY avg_queue_seconds DESC;
```

---

## 🔑 Key Takeaways

| | Concept | Summary |
|---|---|---|
| 📦 | **Size = Nodes** | Each size-up doubles compute nodes and cost |
| ⚡ | **Per-Second Billing** | Short bursts on bigger size can be cheaper than long runs on small |
| 📈 | **Scale Up** | Bigger size for slow individual queries or spilling |
| 🔄 | **Scale Out** | Multi-cluster for queuing and concurrency |
| 💰 | **Right-Size** | Separate warehouses per workload type |
| 🔒 | **Auto-Suspend** | 60s interactive, 120-300s batch, never 0 |

---

## 💡 Best Practices

### For Development/Testing
- Use XS or S exclusively
- Set `AUTO_SUSPEND = 60` (aggressive)
- Use `INITIALLY_SUSPENDED = TRUE` on creation
- Never create dev warehouses larger than M

### For Production
- Size based on measured performance, not guesswork
- Monitor spilling weekly and resize if remote spill > 0
- Use different warehouses for ETL vs BI vs ad-hoc
- Set resource monitors to catch unexpected usage
- Review sizing quarterly as data volumes grow

### Common Mistakes to Avoid
- **One big warehouse for everything**: Leads to contention and impossible cost attribution
- **Never resizing**: Data grows, queries slow down, nobody adjusts
- **Sizing by gut feel**: Always measure with diagnostic queries first
- **Ignoring spilling**: Remote spill means the query is too big for the warehouse's memory
- **AUTO_SUSPEND = 0**: Warehouse never sleeps, credits burn 24/7

---

## 🔗 Related Topics

- **Virtual Warehouses Explained** (Post #11) — Full breakdown of warehouse types, Gen1 vs Gen2, and core concepts
- **Multi-Cluster Warehouses** (Post #13) — Deep dive into scaling out for concurrency
- **Resource Monitors** (upcoming) — Setting credit caps and alerts

---

*This is Post 12 of my Snowflake LinkedIn Series — Phase 2: Virtual Warehouses & Compute.*

🔔 Follow along to master Snowflake, one concept at a time.

**Next up → Multi-Cluster Warehouses: Scaling for Concurrency 🏗️**

---

`#Snowflake #VirtualWarehouse #DataEngineering #CloudCompute #CostOptimization #SQL #SnowflakeLinkedInSeries`
