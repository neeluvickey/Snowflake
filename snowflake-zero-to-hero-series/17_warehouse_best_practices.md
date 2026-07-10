# ⚙️ Warehouse Best Practices — Right-sizing & Suspend/Resume Strategies

Warehouse configuration is the single biggest lever for controlling both **performance** and **cost** in Snowflake. A warehouse that's too large bleeds credits; one that's too small spills to disk and creates bottlenecks. This guide covers how to find the right balance, configure auto-suspend/resume correctly, and adopt production-grade warehouse management patterns.

---

## 🔷 Why This Matters

- **Cost control**: Warehouses are the primary credit consumer in most Snowflake accounts
- **Performance**: Wrong-sized warehouses cause disk spilling, queuing, and slow queries
- **Operational excellence**: Good warehouse hygiene prevents surprise bills and outages
- Snowflake bills per-second (60s minimum) — every idle second above AUTO_SUSPEND burns credits

---

## 🏷️ Core Concept: Right-sizing

**Right-sizing** means choosing the smallest warehouse size that completes your workload within acceptable time, without excessive spilling or queuing.

### The Scaling Rules

| Action | When | What It Does |
|--------|------|--------------|
| Scale UP (bigger size) | Queries spill to disk or run too slow | More compute power per query |
| Scale DOWN (smaller size) | Queries finish fast, no spilling | Save credits |
| Scale OUT (multi-cluster) | High concurrency, queries queue | More parallel capacity |

### Why Not Just Use XL for Everything?

- Each size doubles cost: XS = 1 credit/hr, XL = 16, 4XL = 128
- Simple queries don't benefit from bigger warehouses
- A SELECT COUNT(*) on a small table finishes in the same time on XS vs XL
- You pay for compute whether it's utilized or not

---

## 📊 How to Identify Right Size

### Key Metrics to Monitor

| Metric | Source | What It Tells You |
|--------|--------|-------------------|
| `BYTES_SPILLED_TO_LOCAL_STORAGE` | QUERY_HISTORY | Query needed more memory than available |
| `BYTES_SPILLED_TO_REMOTE_STORAGE` | QUERY_HISTORY | Severe memory pressure (bad) |
| `QUEUED_OVERLOAD_TIME` | QUERY_HISTORY | Warehouse was fully busy, queries waited |
| `TOTAL_ELAPSED_TIME` | QUERY_HISTORY | Overall query duration |
| `CREDITS_USED` | WAREHOUSE_METERING_HISTORY | Actual credit consumption |

### Diagnostic Query: Find Spilling Warehouses

```sql
SELECT 
    warehouse_name,
    warehouse_size,
    COUNT(*) AS total_queries,
    SUM(CASE WHEN bytes_spilled_to_local_storage > 0 THEN 1 ELSE 0 END) AS spill_count,
    ROUND(AVG(bytes_spilled_to_local_storage) / (1024*1024*1024), 2) AS avg_spill_gb,
    ROUND(AVG(total_elapsed_time) / 1000, 1) AS avg_duration_sec
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE start_time > DATEADD('day', -7, CURRENT_TIMESTAMP())
  AND warehouse_name IS NOT NULL
  AND execution_status = 'SUCCESS'
GROUP BY 1, 2
HAVING spill_count > 0
ORDER BY avg_spill_gb DESC;
```

> **Rule of thumb**: If more than 10% of queries spill, consider sizing up. If spilling is to *remote* storage, size up immediately.

### Diagnostic Query: Find Queuing Issues

```sql
SELECT 
    warehouse_name,
    COUNT(*) AS total_queries,
    SUM(CASE WHEN queued_overload_time > 0 THEN 1 ELSE 0 END) AS queued_count,
    ROUND(AVG(queued_overload_time) / 1000, 1) AS avg_queue_sec
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE start_time > DATEADD('day', -7, CURRENT_TIMESTAMP())
  AND warehouse_name IS NOT NULL
GROUP BY 1
HAVING queued_count > 0
ORDER BY avg_queue_sec DESC;
```

> **Rule of thumb**: If queries frequently queue, scale OUT with multi-cluster (not UP).

---

## ⚙️ Auto-Suspend & Auto-Resume

### How They Work

| Parameter | What It Does | Default |
|-----------|--------------|---------|
| `AUTO_SUSPEND` | Seconds of inactivity before warehouse suspends | 600 (10 min) |
| `AUTO_RESUME` | Automatically start warehouse when a query arrives | TRUE |

### Recommended Settings by Workload

| Workload Type | AUTO_SUSPEND | Reasoning |
|---------------|-------------|-----------|
| **ETL/Batch** | 0 (immediate) | Jobs are scheduled, no need to keep alive between runs |
| **BI/Dashboards** | 60 seconds | Users send rapid successive queries; avoid constant resume |
| **Ad-hoc Analytics** | 300 seconds | Analysts think between queries; 5 min avoids churn |
| **Dev/Test** | 60 seconds | Keep responsive but don't burn overnight |
| **Data Science/ML** | 300-600 seconds | Long think time between iterations |

### Important Billing Notes

- **Minimum billing**: 60 seconds per resume event (even if query takes 2 seconds)
- **Resume latency**: 1-2 seconds for provisioning (users may notice a brief pause)
- **Suspend-resume churn**: If queries arrive every 45 seconds with AUTO_SUSPEND=0, you pay the 60-second minimum each time — worse than keeping it alive

```sql
-- Optimal ETL warehouse: suspend immediately after batch completes
ALTER WAREHOUSE etl_wh SET
  AUTO_SUSPEND = 0
  AUTO_RESUME = TRUE;

-- Optimal BI warehouse: stay alive briefly for user interactions
ALTER WAREHOUSE bi_wh SET
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE;

-- Optimal ad-hoc warehouse: balance responsiveness and cost
ALTER WAREHOUSE adhoc_wh SET
  AUTO_SUSPEND = 300
  AUTO_RESUME = TRUE;
```

---

## 🛠️ Production Warehouse Strategy

### The Multi-Warehouse Pattern

```sql
-- ETL: Large, immediate suspend, runs on schedule
CREATE WAREHOUSE IF NOT EXISTS etl_wh
  WAREHOUSE_SIZE = 'LARGE'
  AUTO_SUSPEND = 0
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'Batch ETL workloads';

-- BI Dashboards: Small, multi-cluster, stays warm
CREATE WAREHOUSE IF NOT EXISTS bi_wh
  WAREHOUSE_SIZE = 'SMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  MIN_CLUSTER_COUNT = 1
  MAX_CLUSTER_COUNT = 4
  SCALING_POLICY = 'STANDARD'
  COMMENT = 'Dashboard and reporting queries';

-- Ad-hoc Analytics: Medium, single cluster
CREATE WAREHOUSE IF NOT EXISTS adhoc_wh
  WAREHOUSE_SIZE = 'MEDIUM'
  AUTO_SUSPEND = 300
  AUTO_RESUME = TRUE
  COMMENT = 'Analyst ad-hoc queries';

-- Dev/Test: XS, minimal cost
CREATE WAREHOUSE IF NOT EXISTS dev_wh
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  COMMENT = 'Development and testing';
```

### Add Safety Guards

```sql
-- Kill queries that run longer than 30 minutes
ALTER WAREHOUSE etl_wh SET STATEMENT_TIMEOUT_IN_SECONDS = 1800;
ALTER WAREHOUSE adhoc_wh SET STATEMENT_TIMEOUT_IN_SECONDS = 1800;

-- Kill queries queued longer than 5 minutes
ALTER WAREHOUSE bi_wh SET STATEMENT_QUEUED_TIMEOUT_IN_SECONDS = 300;
```

---

## 📈 Monitoring & Optimization

### Credit Usage by Warehouse (Last 30 Days)

```sql
SELECT 
    warehouse_name,
    ROUND(SUM(credits_used), 2) AS total_credits,
    ROUND(SUM(credits_used) / 30, 2) AS daily_avg,
    COUNT(DISTINCT DATE_TRUNC('day', start_time)) AS active_days
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE start_time > DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY 1
ORDER BY total_credits DESC;
```

### Find Idle Warehouses (Running but Not Used)

```sql
SELECT 
    m.warehouse_name,
    ROUND(SUM(m.credits_used), 2) AS credits_used,
    COUNT(q.query_id) AS queries_run
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY m
LEFT JOIN SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY q
  ON m.warehouse_name = q.warehouse_name
  AND q.start_time BETWEEN m.start_time AND m.end_time
WHERE m.start_time > DATEADD('day', -7, CURRENT_TIMESTAMP())
GROUP BY 1
HAVING queries_run < 10
ORDER BY credits_used DESC;
```

### Resize Recommendation Based on Data

```sql
-- Find warehouses that NEVER spill (potentially oversized)
SELECT 
    warehouse_name,
    warehouse_size,
    COUNT(*) AS query_count,
    MAX(bytes_spilled_to_local_storage) AS max_spill,
    ROUND(AVG(total_elapsed_time) / 1000, 1) AS avg_duration_sec
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE start_time > DATEADD('day', -14, CURRENT_TIMESTAMP())
  AND warehouse_size IN ('MEDIUM', 'LARGE', 'XLARGE', '2XLARGE')
  AND execution_status = 'SUCCESS'
GROUP BY 1, 2
HAVING max_spill = 0 AND avg_duration_sec < 5
ORDER BY query_count DESC;
```

> If a LARGE warehouse never spills and averages under 5 seconds, it's almost certainly oversized.

---

## 💰 Cost Implications

| Warehouse Size | Credits/Hour | Monthly (8hr/day, 22 days)* |
|----------------|-------------|----------------------------|
| X-Small | 1 | 176 credits |
| Small | 2 | 352 credits |
| Medium | 4 | 704 credits |
| Large | 8 | 1,408 credits |
| X-Large | 16 | 2,816 credits |
| 2X-Large | 32 | 5,632 credits |

> *Assumes continuous use during business hours. AUTO_SUSPEND dramatically reduces actual cost.

### Quick Cost Math

- Moving from L → M saves 4 credits/hour = ~704 credits/month
- Setting AUTO_SUSPEND from 600 → 60 on a warehouse used 2 hours/day but running 8 hours saves ~6 credits/hour of idle time

---

## 🔑 Key Takeaways

| | Concept | One-line Description |
|---|---|---|
| 📦 | **Right-sizing** | Match warehouse size to workload using spill/queue metrics |
| ⚡ | **AUTO_SUSPEND** | Set per workload type: 0 for batch, 60 for BI, 300 for ad-hoc |
| 📈 | **Scale UP vs OUT** | UP for complex queries, OUT for concurrency |
| 🔒 | **Isolation** | Separate warehouses per workload prevents resource contention |
| 🔄 | **Monitor & Adjust** | Review metrics weekly; right-sizing is iterative |

---

## 💡 Best Practices

### For Development/Testing
- Use X-Small warehouses (sufficient for most dev work)
- Set AUTO_SUSPEND = 60 to avoid overnight credit burn
- Use STATEMENT_TIMEOUT to catch accidental infinite loops

### For Production
- Maintain separate warehouses per workload category
- Start one size smaller than you think you need
- Set up RESOURCE_MONITOR with SUSPEND action at budget threshold
- Review WAREHOUSE_METERING_HISTORY monthly
- Use INITIALLY_SUSPENDED = TRUE for scheduled batch warehouses

### Common Mistakes to Avoid
- Using one mega-warehouse for all workloads (no isolation, no optimization)
- Setting AUTO_SUSPEND = 0 on warehouses with frequent short queries (resume churn)
- Never checking spill metrics (silent performance degradation)
- Sizing up without checking if the query itself is the problem (bad JOINs, missing filters)
- Forgetting STATEMENT_TIMEOUT (one bad query can burn credits for hours)

---

## 🔗 Related Topics

- **Virtual Warehouses Overview** (Post #11) — what warehouses are and how they work
- **Scaling Policies** (Post #13) — Standard vs Economy scaling
- **Multi-cluster Warehouses** (Post #14) — auto-scaling for concurrency
- **Resource Monitors** (Post #15) — budget controls and alerts

---

*This is Post 17 of my Snowflake LinkedIn Series — Phase 2: Virtual Warehouses & Compute.*

🔔 Follow along to master Snowflake, one concept at a time.

**Next up → Hands-on: Create, Resize & Monitor Warehouses 🛠️**

---

`#Snowflake #VirtualWarehouse #DataEngineering #CostOptimization #SQL #SnowflakeLinkedInSeries`
