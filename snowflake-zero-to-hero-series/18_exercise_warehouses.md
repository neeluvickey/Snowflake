<!-- 
================================================================================
📋 POST 18 — HANDS-ON: CREATE, RESIZE & MONITOR WAREHOUSES
================================================================================
Phase 2: Virtual Warehouses & Compute | Type: EXERCISE
================================================================================
-->

# 🛠️ Hands-on: Create, Resize & Monitor Warehouses

This is the practical capstone for Phase 2. Everything you learned about virtual warehouses (Posts 11-17) comes together here. You'll create warehouses with different configurations, resize them dynamically, monitor credit consumption, and learn the diagnostic queries every Snowflake admin should know.

---

## 🔷 Why This Matters

- Warehouses are where your money goes. Misconfigured warehouses = wasted credits.
- Knowing how to create, resize, and monitor gives you direct control over performance AND cost.
- These are day-one skills for any Snowflake administrator or data engineer.

---

## 🏷️ Core Concept

This exercise walks through the full warehouse lifecycle:
1. **Create** warehouses with proper settings
2. **Resize** dynamically based on workload
3. **Monitor** credit usage and query load
4. **Suspend/Resume** for manual control
5. **Clean up** to avoid idle spend

---

## 🛠️ SQL Examples

### Exercise 1: Create a Standard ETL Warehouse

```sql
-- Gen2 warehouse for ETL workloads
-- INITIALLY_SUSPENDED prevents immediate credit burn
CREATE WAREHOUSE etl_wh
  WAREHOUSE_TYPE = 'STANDARD'
  WAREHOUSE_SIZE = 'SMALL'
  AUTO_SUSPEND = 120
  AUTO_RESUME = TRUE
  MIN_CLUSTER_COUNT = 1
  MAX_CLUSTER_COUNT = 1
  INITIALLY_SUSPENDED = TRUE;
```

**Why these settings:**
- `SMALL` size is a safe starting point for ETL (2 credits/hour)
- `AUTO_SUSPEND = 120` gives 2 minutes before suspending (avoids thrashing for bursty ETL)
- `INITIALLY_SUSPENDED = TRUE` means zero cost until the first query arrives
- Single cluster (no multi-cluster) because ETL is typically sequential, not concurrent

### Exercise 2: Create a Multi-Cluster BI Warehouse

```sql
-- Multi-cluster warehouse for concurrent dashboard users
CREATE WAREHOUSE bi_wh
  WAREHOUSE_TYPE = 'STANDARD'
  WAREHOUSE_SIZE = 'MEDIUM'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  MIN_CLUSTER_COUNT = 1
  MAX_CLUSTER_COUNT = 4
  SCALING_POLICY = 'STANDARD';
```

**Why these settings:**
- `MEDIUM` provides good single-query performance for dashboards
- `MAX_CLUSTER_COUNT = 4` allows scaling out to handle up to 4x concurrent load
- `SCALING_POLICY = 'STANDARD'` adds clusters as soon as queuing is detected (low latency priority)
- `AUTO_SUSPEND = 60` is aggressive because BI queries are short and bursty

### Exercise 3: Create a Snowpark-Optimized Warehouse

```sql
-- Extra memory for ML workloads, UDFs, and DataFrames
CREATE WAREHOUSE ml_wh
  WAREHOUSE_TYPE = 'SNOWPARK-OPTIMIZED'
  WAREHOUSE_SIZE = 'MEDIUM'
  AUTO_SUSPEND = 300
  AUTO_RESUME = TRUE
  MIN_CLUSTER_COUNT = 1
  MAX_CLUSTER_COUNT = 1
  INITIALLY_SUSPENDED = TRUE;
```

**Why these settings:**
- `SNOWPARK-OPTIMIZED` provides 16x more local cache/memory per node
- `AUTO_SUSPEND = 300` (5 min) because ML jobs often have gaps between iterations
- Single cluster because ML workloads are typically resource-heavy, not concurrency-heavy

### Exercise 4: Verify Your Warehouses

```sql
-- See all warehouses and their configurations
SHOW WAREHOUSES;
```

```sql
-- Detailed description of a specific warehouse
DESCRIBE WAREHOUSE etl_wh;
```

---

## ⚡ Dynamic Resizing

### Scale Up for Heavy Workloads

```sql
-- Double the compute power instantly
ALTER WAREHOUSE etl_wh SET WAREHOUSE_SIZE = 'LARGE';
```

> **Note:** Resizing is instant and doesn't affect currently running queries. Only NEW queries use the new size.

### Scale Back Down After

```sql
-- Return to original size to save credits
ALTER WAREHOUSE etl_wh SET WAREHOUSE_SIZE = 'SMALL';
```

### Modify Multi-Cluster Settings

```sql
-- Increase max clusters during peak hours
ALTER WAREHOUSE bi_wh SET MAX_CLUSTER_COUNT = 6;

-- Reduce during off-hours
ALTER WAREHOUSE bi_wh SET MAX_CLUSTER_COUNT = 2;
```

### Change Auto-Suspend Timing

```sql
-- More aggressive suspend for cost savings
ALTER WAREHOUSE etl_wh SET AUTO_SUSPEND = 60;

-- Less aggressive for frequently used warehouses
ALTER WAREHOUSE bi_wh SET AUTO_SUSPEND = 300;
```

---

## 📊 Monitoring Credit Consumption

### Query 1: Credits Used Per Warehouse (Last 7 Days)

```sql
SELECT
  WAREHOUSE_NAME,
  SUM(CREDITS_USED) AS TOTAL_CREDITS,
  SUM(CREDITS_USED_COMPUTE) AS COMPUTE_CREDITS,
  SUM(CREDITS_USED_CLOUD_SERVICES) AS CS_CREDITS
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE START_TIME >= DATEADD('day', -7, CURRENT_TIMESTAMP())
GROUP BY WAREHOUSE_NAME
ORDER BY TOTAL_CREDITS DESC;
```

**What to look for:**
- Which warehouse consumes the most credits?
- Is cloud services cost significant (>10% of total)? If so, you may have too many small queries.

### Query 2: Daily Credit Trend

```sql
SELECT
  DATE_TRUNC('day', START_TIME) AS USAGE_DATE,
  WAREHOUSE_NAME,
  SUM(CREDITS_USED) AS DAILY_CREDITS
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE START_TIME >= DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY USAGE_DATE, WAREHOUSE_NAME
ORDER BY USAGE_DATE DESC, DAILY_CREDITS DESC;
```

**What to look for:**
- Unexpected spikes on specific days
- Weekday vs weekend patterns (should drop on weekends if no scheduled jobs)

### Query 3: Warehouse Load Analysis

```sql
SELECT
  WAREHOUSE_NAME,
  AVG(AVG_RUNNING) AS AVG_RUNNING_QUERIES,
  AVG(AVG_QUEUED_LOAD) AS AVG_QUEUED,
  AVG(AVG_BLOCKED) AS AVG_BLOCKED
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
WHERE START_TIME >= DATEADD('day', -7, CURRENT_TIMESTAMP())
GROUP BY WAREHOUSE_NAME
ORDER BY AVG_RUNNING_QUERIES DESC;
```

**Decision matrix:**

| Metric | Value | Action |
|--------|-------|--------|
| `AVG_QUEUED` > 0 consistently | Queries waiting | Scale up size OR increase max clusters |
| `AVG_BLOCKED` > 0 | Lock contention | Investigate concurrent DML on same tables |
| `AVG_RUNNING` very low | Underutilized | Consider smaller warehouse size |
| `AVG_RUNNING` near cluster capacity | Saturated | Add clusters or increase size |

### Query 4: Longest Running Queries Per Warehouse

```sql
SELECT
  WAREHOUSE_NAME,
  QUERY_ID,
  QUERY_TEXT,
  TOTAL_ELAPSED_TIME / 1000 AS ELAPSED_SECONDS,
  BYTES_SCANNED / (1024*1024*1024) AS GB_SCANNED,
  PARTITIONS_SCANNED,
  PARTITIONS_TOTAL
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE START_TIME >= DATEADD('day', -7, CURRENT_TIMESTAMP())
  AND WAREHOUSE_NAME IS NOT NULL
  AND EXECUTION_STATUS = 'SUCCESS'
ORDER BY TOTAL_ELAPSED_TIME DESC
LIMIT 10;
```

**What to look for:**
- Queries scanning all partitions (PARTITIONS_SCANNED = PARTITIONS_TOTAL) need clustering keys
- High GB_SCANNED relative to result size = missing filters or bad joins

---

## 🔒 Suspend & Resume

### Manual Suspend

```sql
-- Immediately stop all credit consumption
ALTER WAREHOUSE etl_wh SUSPEND;
```

> **Note:** Running queries will complete, but new queries will queue until resumed.

### Manual Resume

```sql
-- Start the warehouse back up
ALTER WAREHOUSE etl_wh RESUME;
```

### Check Current State

```sql
-- Quick status check
SELECT CURRENT_WAREHOUSE();

SHOW WAREHOUSES LIKE 'ETL%';
```

---

## 📈 Scaling & Performance

### When to Scale Up (Bigger Size)
- Single complex query taking too long
- Large table scans or sorts
- ETL jobs with tight SLA windows

### When to Scale Out (More Clusters)
- Many concurrent users hitting dashboards
- Queue time increasing during business hours
- Consistent AVG_QUEUED > 0 in load history

### Performance Tips
- Start small, monitor, then right-size based on actual load data
- Use separate warehouses per workload type (ETL vs BI vs Ad-hoc)
- Aggressive AUTO_SUSPEND for dev/test warehouses (60 seconds)
- Longer AUTO_SUSPEND for production ETL (120-300 seconds) to avoid thrashing

---

## 💰 Cost Implications

| Warehouse Size | Credits/Hour (Gen1) | Credits/Hour (Gen2) | Monthly @ 8hr/day* |
|---------------|--------------------|--------------------|-------------------|
| X-Small | 1 | 1 | ~$80 |
| Small | 2 | 2 | ~$160 |
| Medium | 4 | 4 | ~$320 |
| Large | 8 | 8 | ~$640 |
| X-Large | 16 | 16 | ~$1,280 |

> *Estimates assume $4/credit, 20 working days, 8 hours/day. Gen2 costs the same but runs queries faster.

### Cost Optimization Strategies
- INITIALLY_SUSPENDED on creation (zero cost until first use)
- Aggressive AUTO_SUSPEND for infrequent workloads
- Right-size based on WAREHOUSE_LOAD_HISTORY data, not guesses
- Use Resource Monitors (Post 15) to cap spend

---

## 🧹 Clean Up

```sql
-- Always drop exercise warehouses when done
DROP WAREHOUSE IF EXISTS etl_wh;
DROP WAREHOUSE IF EXISTS bi_wh;
DROP WAREHOUSE IF EXISTS ml_wh;
```

> **Important:** Never leave test warehouses running. Even suspended warehouses don't cost anything, but they clutter your account and someone might accidentally resume them.

---

## 🔑 Key Takeaways

| | Concept | One-line Description |
|---|---|---|
| 📦 | **INITIALLY_SUSPENDED** | Create without burning credits immediately |
| ⚡ | **ALTER SIZE** | Instant resize with zero downtime |
| 📈 | **WAREHOUSE_METERING_HISTORY** | Your credit consumption dashboard |
| 🔒 | **WAREHOUSE_LOAD_HISTORY** | Spot queuing and blocking problems |
| 🔄 | **Suspend/Resume** | Manual spend control when AUTO_SUSPEND isn't enough |

---

## 💡 Best Practices

### For Development/Testing
- Use X-Small or Small warehouses
- Set AUTO_SUSPEND = 60 (aggressive)
- Always use INITIALLY_SUSPENDED = TRUE
- Drop when done

### For Production
- Separate warehouses per workload type
- Monitor WAREHOUSE_LOAD_HISTORY weekly
- Set Resource Monitors with alerts at 75% and actions at 100%
- Use multi-cluster for user-facing workloads
- Document warehouse purpose in COMMENT field

### Common Mistakes to Avoid
- Running all workloads on one warehouse (no isolation, no visibility)
- Never checking load history (flying blind on right-sizing)
- Setting AUTO_SUSPEND too high for dev warehouses (wasting credits on idle compute)
- Forgetting INITIALLY_SUSPENDED on new warehouses (immediate credit burn)

---

## 🔗 Related Topics

- **Virtual Warehouses** (Post 11) — foundational concepts
- **Scaling Policies** (Post 13) — Standard vs Economy deep dive
- **Multi-cluster Warehouses** (Post 14) — auto-scaling mechanics
- **Resource Monitors** (Post 15) — credit budget enforcement
- **Warehouse Best Practices** (Post 17) — right-sizing strategies

---

*This is Post 18 of my Snowflake LinkedIn Series — Phase 2: Virtual Warehouses & Compute (Capstone Exercise).*

🔔 Follow along to master Snowflake, one concept at a time.

**Next up → Snowflake Table Types: Permanent, Transient & Temporary 📋**

---

`#Snowflake #VirtualWarehouse #DataEngineering #CloudCompute #SQL #HandsOn #SnowflakeLinkedInSeries`
