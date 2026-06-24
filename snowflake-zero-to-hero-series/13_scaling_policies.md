
# ⚖️ Warehouse Scaling Policies — Standard vs Economy

Multi-cluster warehouses in Snowflake can automatically scale out (add clusters) and scale in (remove clusters) based on workload demand. The **Scaling Policy** controls how aggressively Snowflake starts and stops these additional clusters. Choosing the right policy directly impacts both query performance and credit consumption.

This feature requires **Snowflake Enterprise Edition** or higher.

---

## 🔷 Why This Matters

When you run a multi-cluster warehouse in **Auto-scale mode** (MIN_CLUSTER_COUNT < MAX_CLUSTER_COUNT), Snowflake must make decisions:

- **When to start** a new cluster (scale out)
- **When to shut down** an idle cluster (scale in)

The scaling policy is the ruleset that governs these decisions. Get it wrong and you either:

- **Overspend**: Clusters start too eagerly, running for seconds before shutting down
- **Under-perform**: Queries queue unnecessarily because clusters start too late

---

## 🏷️ Core Concept

### What is a Scaling Policy?

A scaling policy is a warehouse-level property (`SCALING_POLICY`) that tells Snowflake's auto-scaler how to balance **performance vs cost** when deciding to add or remove clusters.

It only applies when the warehouse is in **Auto-scale mode** — meaning `MAX_CLUSTER_COUNT` > `MIN_CLUSTER_COUNT`.

In **Maximized mode** (max = min), all clusters run simultaneously, so the scaling policy has no effect.

### The Two Policies

Snowflake provides two scaling policies:

1. **Standard** (default) — Favors performance
2. **Economy** — Favors cost savings

> **Note:** A third policy called `LEGACY` was previously available for backward compatibility but has been removed. All warehouses that used Legacy now use Standard.

---

## 📊 Comparison: Standard vs Economy

| Aspect | Standard (Default) | Economy |
|--------|-------------------|---------|
| **Priority** | Performance & responsiveness | Cost savings |
| **New cluster starts when...** | A query is queued OR Snowflake estimates current clusters can't handle additional queries | System estimates enough load to keep the cluster busy for **at least 6 minutes** |
| **Cluster shuts down when...** | After a sustained period of low load, once running queries finish | When estimated remaining work is **less than 6 minutes** |
| **Queuing behavior** | Minimizes queuing | Tolerates some queuing to save credits |
| **Scale-out speed** | Immediate (proactive) | Delayed (reactive, waits for sustained demand) |
| **Best for** | User-facing, SLA-driven workloads | Batch processing, background jobs |
| **Credit usage** | Higher (more cluster-hours) | Lower (fewer cluster-hours) |
| **MAX_CLUSTER_COUNT > 10** | May start multiple clusters at once | Same 6-minute rule applies per cluster |

> **Important:** Interactive warehouses support **Standard scaling policy only**. Their scaling is even more proactive than standard warehouses to maintain low-latency responsiveness.

---

## ⚙️ Configuration & Parameters

| Parameter | Default | Values | Description |
|-----------|---------|--------|-------------|
| `SCALING_POLICY` | `'STANDARD'` | `'STANDARD'`, `'ECONOMY'` | Controls cluster start/stop behavior in Auto-scale mode |
| `MIN_CLUSTER_COUNT` | `1` | `1` to `MAX_CLUSTER_COUNT` | Minimum clusters always running |
| `MAX_CLUSTER_COUNT` | `1` | `1` to size-dependent max | Maximum clusters available for scale-out |

### Maximum Cluster Counts by Warehouse Size

| Size | Max Clusters Allowed |
|------|---------------------|
| XS, S, M | 300 |
| L | 160 |
| XL | 80 |
| 2XL | 40 |
| 3XL | 20 |
| 4XL, 5XL, 6XL | 10 |

### The 6-Minute Rule (Economy Policy)

Economy policy uses a simple heuristic:

- **Start**: Only if estimated workload will keep the cluster busy for ≥ 6 minutes
- **Stop**: When estimated remaining work drops below 6 minutes

This means:
- Short bursts of concurrency (e.g., 20 queries arriving at once but finishing in 3 minutes) may NOT trigger a new cluster
- Queries will queue instead, waiting for existing clusters to free up
- This is intentional — Economy assumes you'd rather wait than pay

---

## 🛠️ SQL Examples

### Basic: Create with Standard Policy (Default)

```sql
-- Standard policy is the default, but explicit is better
CREATE WAREHOUSE bi_dashboard_wh
  WAREHOUSE_SIZE = 'MEDIUM'
  MIN_CLUSTER_COUNT = 1
  MAX_CLUSTER_COUNT = 5
  SCALING_POLICY = 'STANDARD'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE;
```

Best for: BI dashboards, Streamlit apps, interactive analytics where users expect fast responses.

### Basic: Create with Economy Policy

```sql
-- Economy policy for cost-sensitive background workloads
CREATE WAREHOUSE nightly_etl_wh
  WAREHOUSE_SIZE = 'LARGE'
  MIN_CLUSTER_COUNT = 1
  MAX_CLUSTER_COUNT = 3
  SCALING_POLICY = 'ECONOMY'
  AUTO_SUSPEND = 120
  AUTO_RESUME = TRUE;
```

Best for: Scheduled ETL, dbt runs, data loading, and batch transforms where some queuing is acceptable.

### Intermediate: Change Policy on Existing Warehouse

```sql
-- Switch from Standard to Economy (takes effect immediately)
ALTER WAREHOUSE analytics_wh
  SET SCALING_POLICY = 'ECONOMY';

-- Switch back to Standard
ALTER WAREHOUSE analytics_wh
  SET SCALING_POLICY = 'STANDARD';
```

No need to suspend the warehouse — the change applies immediately to future scaling decisions.

### Advanced: Time-Based Policy Switching with Tasks

```sql
-- Switch to Economy during off-hours (save credits overnight)
CREATE TASK switch_to_economy
  WAREHOUSE = 'ADMIN_WH'
  SCHEDULE = 'USING CRON 0 20 * * * America/New_York'
AS
  ALTER WAREHOUSE analytics_wh SET SCALING_POLICY = 'ECONOMY';

-- Switch back to Standard during business hours
CREATE TASK switch_to_standard
  WAREHOUSE = 'ADMIN_WH'
  SCHEDULE = 'USING CRON 0 7 * * MON-FRI America/New_York'
AS
  ALTER WAREHOUSE analytics_wh SET SCALING_POLICY = 'STANDARD';

-- Resume tasks
ALTER TASK switch_to_economy RESUME;
ALTER TASK switch_to_standard RESUME;
```

This pattern gives you Standard performance during work hours and Economy savings overnight/weekends.

### View Current Scaling Policy

```sql
-- Check scaling policy for all warehouses
SHOW WAREHOUSES;

-- Filtered view of multi-cluster warehouses
SHOW WAREHOUSES
  ->> SELECT "name", "size", "min_cluster_count", "max_cluster_count", 
             "scaling_policy", "started_clusters", "state"
      FROM $1
      WHERE "max_cluster_count" > 1
      ORDER BY "name";
```

---

## 📈 Scaling Behavior Deep Dive

### Standard Policy — How It Scales Out

1. Query arrives at warehouse
2. Snowflake checks: Can current clusters handle this query without queuing?
3. If NO → immediately starts a new cluster (up to MAX_CLUSTER_COUNT)
4. For warehouses with MAX > 10: may start **multiple clusters at once** for rapid load increases
5. New cluster begins accepting queries as soon as it's provisioned (~1-2 seconds)

### Standard Policy — How It Scales In

1. After a sustained period of low load (no exact timer published)
2. Snowflake identifies the least-loaded cluster
3. Waits for running queries on that cluster to finish
4. Shuts down the cluster
5. For cluster count > 10: may shut down multiple clusters simultaneously
6. For cluster count ≤ 10: shuts down one at a time

### Economy Policy — How It Scales Out

1. Query arrives and gets queued (existing clusters are busy)
2. Snowflake estimates: Will there be enough work to keep a new cluster busy for 6+ minutes?
3. If YES → starts a new cluster
4. If NO → query stays in queue until existing clusters free up
5. This estimation is based on current queue depth, query patterns, and cluster utilization

### Economy Policy — How It Scales In

1. Snowflake continuously monitors each cluster's workload
2. When a cluster's estimated remaining work drops below 6 minutes → marked for shutdown
3. Waits for current queries to finish
4. Shuts down the cluster
5. For cluster count > 10: may shut down multiple clusters at once

---

## 💰 Cost Implications

### Credit Usage Comparison (Medium Warehouse, Max 3 Clusters, 8-Hour Day)

| Scenario | Standard (est.) | Economy (est.) |
|----------|----------------|----------------|
| Steady moderate load | 2 clusters × 8h × 4cr = 64 credits | 1-2 clusters × 8h × 4cr = 32-64 credits |
| Burst load (peaks every hour) | 3 clusters × 8h × 4cr = 96 credits | 1-2 clusters × 8h × 4cr = 32-64 credits |
| Light load with occasional spikes | 1-2 clusters × 8h × 4cr = 32-64 credits | 1 cluster × 8h × 4cr = 32 credits |

> *Actual credits depend on per-second billing and actual cluster runtime. These are illustrative maximums.*

### When Economy Saves Money

- Workloads that come in waves with gaps > 6 minutes between peaks
- Background batch jobs where a few seconds of queuing doesn't matter
- Off-hours when query volume drops significantly

### When Economy Costs You (Indirectly)

- Queued queries mean slower dashboards → unhappy users
- SLA breaches if response time is contractual
- Cascading delays in dependent downstream pipelines

---

## 🔑 Key Takeaways

| | Concept | One-line Description |
|---|---|---|
| ⚡ | **Standard** | Starts clusters proactively, minimizes queuing, uses more credits |
| 💰 | **Economy** | Starts clusters only for sustained load (6-min rule), saves credits, allows queuing |
| 🎯 | **Auto-scale only** | Scaling policy has no effect in Maximized mode |
| 🔄 | **Change anytime** | ALTER WAREHOUSE SET SCALING_POLICY works instantly, no suspend needed |
| 📊 | **Monitor** | Use WAREHOUSE_LOAD_HISTORY to validate your policy choice |

---

## 💡 Best Practices

### For User-Facing Workloads (Dashboards, APIs, Interactive)
- Use **Standard** policy — always
- Users notice latency; queuing is unacceptable
- Interactive warehouses enforce Standard automatically

### For Batch/Background Workloads (ETL, dbt, Scheduled Jobs)
- Start with **Standard**, observe, then try **Economy**
- If your jobs have predictable timing, Economy usually works well
- Monitor queue times — if they grow beyond acceptable limits, switch back

### For Mixed Workloads
- Separate into different warehouses (Standard for interactive, Economy for batch)
- Use time-based policy switching with Tasks if workload patterns change by time of day

### Common Mistakes to Avoid
- Using Economy for user-facing dashboards (users will complain about slow queries)
- Setting MAX_CLUSTER_COUNT = 1 and expecting the scaling policy to matter (it doesn't — you need max > min)
- Ignoring WAREHOUSE_LOAD_HISTORY data — let metrics drive your policy choice, not guesswork

---

## 📊 Monitoring & Diagnostics

### Check Cluster Scaling Activity

```sql
-- See how clusters scaled over the past 24 hours
SELECT 
  start_time,
  end_time,
  warehouse_name,
  cluster_number,
  DATEDIFF('minute', start_time, end_time) AS runtime_minutes
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_EVENTS_HISTORY
WHERE event_name IN ('CLUSTER_START', 'CLUSTER_STOP')
  AND start_time >= DATEADD('day', -1, CURRENT_TIMESTAMP())
ORDER BY start_time DESC;
```

### Monitor Query Queuing (Sign You Need Standard)

```sql
-- Find queries that were queued (waited for resources)
SELECT 
  query_id,
  warehouse_name,
  start_time,
  queued_overload_time / 1000 AS queued_seconds,
  total_elapsed_time / 1000 AS total_seconds,
  ROUND(queued_overload_time / NULLIF(total_elapsed_time, 0) * 100, 1) AS pct_time_queued
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE warehouse_name = 'YOUR_WAREHOUSE_NAME'
  AND queued_overload_time > 0
  AND start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
ORDER BY queued_overload_time DESC
LIMIT 20;
```

### Warehouse Load History (Cluster Utilization)

```sql
-- See load patterns to decide Standard vs Economy
SELECT 
  start_time,
  warehouse_name,
  avg_running,
  avg_queued_load,
  avg_blocked
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
WHERE warehouse_name = 'YOUR_WAREHOUSE_NAME'
  AND start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
ORDER BY start_time;
```

If `avg_queued_load` is consistently > 0 with Economy policy, consider switching to Standard.

---

## 🔗 Related Topics

- **Virtual Warehouses** (Post #11) — Warehouse fundamentals, sizes, and types
- **Poll: Warehouse Size** (Post #12) — Community sizing preferences
- **Multi-Cluster Warehouses** (Post #14) — Deep dive into auto-scaling mechanics
- **Resource Monitors** (Post #15) — Credit controls and alerts
- [Snowflake Docs: Multi-cluster Warehouses](https://docs.snowflake.com/en/user-guide/warehouses-multicluster) — Official reference

---

*This is Post 13 of my Snowflake LinkedIn Series — Phase 2: Virtual Warehouses & Compute.*

🔔 Follow along to master Snowflake, one concept at a time.

**Next up → Multi-Cluster Warehouses: Auto-Scaling in Action 🏗️**

---

`#Snowflake #ScalingPolicy #MultiCluster #DataEngineering #CostOptimization #VirtualWarehouse #SnowflakeLinkedInSeries`
