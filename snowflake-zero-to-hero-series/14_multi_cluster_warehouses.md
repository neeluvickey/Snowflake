# 📈 Multi-Cluster Warehouses — Auto-Scaling Compute for Concurrency

Multi-cluster warehouses (MCW) are Snowflake's answer to the concurrency challenge. When a single cluster can't keep up with the number of simultaneous queries, MCWs dynamically scale out by adding more clusters, ensuring users don't wait in queue. This is an **Enterprise Edition** feature that separates reactive workload management from proactive, automated scaling.

If you've ever seen queries stack up in a queue during peak hours while your warehouse is already running at full capacity, MCW is the solution. It's not about making individual queries faster (that's scaling UP); it's about serving more users and queries at the same time (scaling OUT).

---

## 🔷 Why This Matters

- **User experience degrades** when queries queue. Dashboards feel slow, analysts get frustrated, and SLAs get missed.
- **Manual intervention** (resizing warehouses, spinning up new ones, redirecting users) is operationally expensive and reactive.
- **Cost control** is critical: you want enough compute for peak loads without paying for idle clusters during off-hours.
- **Auto-scale mode** solves all three: it dynamically adjusts cluster count based on real-time demand, with policy-driven cost control.

---

## 🏷️ Core Concept

A **multi-cluster warehouse** is a virtual warehouse configured with more than one cluster of compute resources. Instead of a single cluster handling all queries, Snowflake can allocate multiple clusters under the same warehouse identity.

### How It Works

- All clusters in an MCW share the same **warehouse size** (XS through 6XL).
- Queries are automatically routed to available clusters; no user intervention needed.
- Each cluster operates independently: it has its own local cache, executes its own queries, and consumes credits separately.
- The warehouse still behaves as a single entity for **auto-suspend** and **auto-resume** (these apply to the entire MCW, not individual clusters).

### Scale UP vs Scale OUT

| Strategy | What Changes | Solves | Example |
|----------|-------------|--------|---------|
| **Scale UP** | Warehouse size (XS → M → XL) | Slow individual queries | A complex JOIN taking too long |
| **Scale OUT** | Number of clusters (1 → 3 → 5) | Too many concurrent queries | 50 dashboard users at 9 AM |

> **Key insight:** MCWs don't make a single query faster. If a query is slow on a Medium warehouse, adding more Medium clusters won't help that query. You need to resize UP. MCWs help when you have *many* queries competing for the same resources.

---

## 📊 Operating Modes: Maximized vs Auto-scale

| Feature | Maximized | Auto-scale |
|---------|-----------|------------|
| **Configuration** | MIN = MAX (both > 1) | MIN < MAX |
| **Cluster startup** | All clusters start immediately when warehouse resumes | Clusters start/stop based on demand |
| **Best for** | Predictable, consistently high concurrency | Fluctuating workloads (peak vs off-hours) |
| **Cost behavior** | Fixed (all clusters always running) | Variable (pay only for active clusters) |
| **Scaling policy** | Not applicable (all clusters always on) | Standard or Economy |
| **Use case** | Large BI team with constant load | Mixed workloads with time-of-day patterns |

### Maximized Mode

When you set `MIN_CLUSTER_COUNT = MAX_CLUSTER_COUNT` (both greater than 1), all clusters start when the warehouse resumes and stay running until the warehouse suspends.

```sql
-- Maximized: always 4 clusters running
CREATE WAREHOUSE bi_team_wh
  WAREHOUSE_SIZE = 'LARGE'
  MIN_CLUSTER_COUNT = 4
  MAX_CLUSTER_COUNT = 4
  AUTO_SUSPEND = 300
  AUTO_RESUME = TRUE;
```

### Auto-scale Mode

When `MIN_CLUSTER_COUNT < MAX_CLUSTER_COUNT`, Snowflake dynamically starts and stops clusters based on workload. This is the most common configuration.

```sql
-- Auto-scale: 1 to 6 clusters based on demand
CREATE WAREHOUSE analytics_wh
  WAREHOUSE_SIZE = 'MEDIUM'
  MIN_CLUSTER_COUNT = 1
  MAX_CLUSTER_COUNT = 6
  SCALING_POLICY = 'STANDARD'
  AUTO_SUSPEND = 120
  AUTO_RESUME = TRUE;
```

---

## ⚙️ Scaling Policies (Auto-scale Mode Only)

The **scaling policy** controls how aggressively Snowflake starts and stops clusters. This is the primary lever for balancing performance vs cost.

| Aspect | Standard (Default) | Economy |
|--------|-------------------|---------|
| **Philosophy** | Don't let queries queue | Don't waste credits |
| **New cluster starts when** | A query queues OR Snowflake estimates current clusters can't handle incoming load | Estimated load will keep cluster busy for 6+ minutes |
| **Cluster shuts down when** | Sustained low load detected; queries finish on that cluster | Estimated remaining work < 6 minutes |
| **Multi-shutdown (>10 clusters)** | May shut down multiple clusters at once | May shut down multiple clusters at once |
| **Best for** | User-facing dashboards, interactive queries, SLA-driven workloads | Background ETL, batch processing, cost-sensitive workloads |
| **Trade-off** | May over-provision briefly (extra cost) | May under-provision briefly (queries queue) |

> **Note:** Interactive warehouses support **Standard scaling policy only**. Their auto-scaling is more proactive than standard warehouses to maintain low-latency performance.

### Standard Policy Deep-Dive

- For MCWs with MAX_CLUSTER_COUNT of 10 or less: starts **one** additional cluster at a time.
- For MCWs with MAX_CLUSTER_COUNT greater than 10: may start **multiple** clusters simultaneously to handle rapid load increases.
- The algorithm is heuristic: it doesn't just react to queuing, it **predicts** whether the next incoming query would cause queuing and pre-emptively starts a cluster.

### Economy Policy Deep-Dive

- The "6-minute rule": a new cluster only starts if Snowflake estimates enough work to keep it busy for at least 6 minutes.
- An idle cluster is marked for shutdown if estimated remaining work is less than 6 minutes.
- Queries may wait in queue until this threshold is met.
- Best suited for workloads where brief queuing is acceptable in exchange for significant credit savings.

---

## 📐 Upper Limits on Cluster Count

The maximum number of clusters depends on warehouse size. Larger sizes have lower limits:

| Warehouse Size | Max Clusters Allowed |
|---------------|---------------------|
| `XSMALL` | 300 |
| `SMALL` | 300 |
| `MEDIUM` | 300 |
| `LARGE` | 160 |
| `XLARGE` | 80 |
| `2XLARGE` | 40 |
| `3XLARGE` | 20 |
| `4XLARGE` | 10 |
| `5XLARGE` | 10 |
| `6XLARGE` | 10 |

> **Note:** Snowsight UI supports setting up to 10 clusters. To go beyond 10, use `CREATE WAREHOUSE` or `ALTER WAREHOUSE` SQL commands.

---

## 🛠️ SQL Examples

### Basic: Create an Auto-scaling MCW

```sql
CREATE WAREHOUSE reporting_wh
  WAREHOUSE_SIZE = 'MEDIUM'
  MIN_CLUSTER_COUNT = 1
  MAX_CLUSTER_COUNT = 3
  SCALING_POLICY = 'STANDARD'
  AUTO_SUSPEND = 120
  AUTO_RESUME = TRUE;
```

### Intermediate: Create a Maximized MCW with Economy Fallback

```sql
-- Start with Maximized for peak hours, switch to Economy after
CREATE WAREHOUSE peak_hours_wh
  WAREHOUSE_SIZE = 'LARGE'
  MIN_CLUSTER_COUNT = 3
  MAX_CLUSTER_COUNT = 3
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE;

-- After peak hours, switch to auto-scale with Economy
ALTER WAREHOUSE peak_hours_wh SET
  MIN_CLUSTER_COUNT = 1
  MAX_CLUSTER_COUNT = 5
  SCALING_POLICY = 'ECONOMY';
```

### Advanced: Convert Single-Cluster to Multi-Cluster

```sql
-- Check current state
SHOW WAREHOUSES LIKE 'ANALYTICS_WH';

-- Convert to multi-cluster
ALTER WAREHOUSE analytics_wh SET
  MAX_CLUSTER_COUNT = 4
  MIN_CLUSTER_COUNT = 1
  SCALING_POLICY = 'STANDARD';
```

### Management: View MCW Details

```sql
-- Show all warehouses with cluster info
SHOW WAREHOUSES
  ->> SELECT "name", "state", "size", "min_cluster_count", "max_cluster_count", "started_clusters", "scaling_policy"
        FROM $1
        WHERE "max_cluster_count" > 1
        ORDER BY "max_cluster_count" DESC;
```

### Dynamically Adjust Clusters

```sql
-- Increase max clusters during expected peak
ALTER WAREHOUSE analytics_wh SET MAX_CLUSTER_COUNT = 8;

-- Reduce after peak
ALTER WAREHOUSE analytics_wh SET MAX_CLUSTER_COUNT = 3;

-- Switch scaling policy
ALTER WAREHOUSE analytics_wh SET SCALING_POLICY = 'ECONOMY';
```

---

## 📈 Scaling & Performance

### When to Scale OUT (Add Clusters)

- Dashboard users complaining of slowness during peak hours
- Query history shows frequent queuing (`QUEUED` status)
- Multiple teams sharing the same warehouse
- Concurrency spikes at predictable times (morning logins, report generation)

### When to Scale UP (Increase Size) Instead

- A single complex query is slow (large JOINs, heavy aggregations)
- Data loading jobs taking too long
- Spilling to remote storage detected
- Query Acceleration Service (QAS) maxed out

### Performance Tips

- Start with `MAX_CLUSTER_COUNT = 2 or 3` and monitor queuing patterns before increasing.
- Combine MCW with **Query Acceleration Service (QAS)** for best results. QAS is auto-enabled for new MCWs.
- Each cluster has its own **local data cache**; frequently-accessed data gets cached across all active clusters over time.
- Resizing an MCW applies the new size to ALL clusters (running and future).

---

## 💰 Cost Implications

Credits are consumed per-cluster, per-second (60-second minimum per cluster startup):

| Size | Credits/Hour/Cluster | 3 Clusters/Hour | 5 Clusters/Hour |
|------|---------------------|-----------------|-----------------|
| `XSMALL` | 1 | 3 | 5 |
| `SMALL` | 2 | 6 | 10 |
| `MEDIUM` | 4 | 12 | 20 |
| `LARGE` | 8 | 24 | 40 |
| `XLARGE` | 16 | 48 | 80 |

### Credit Usage Example (Auto-scale, Medium, MAX = 3)

| Hour | Cluster 1 | Cluster 2 | Cluster 3 | Total Credits |
|------|-----------|-----------|-----------|---------------|
| 1st | 4 | 0 | 0 | 4 |
| 2nd | 4 | 4 | 2 | 10 |
| 3rd | 4 | 2 | 0 | 6 |
| **Total** | **12** | **6** | **2** | **20** |

### Cost Optimization Strategies

- Use **Economy** policy for non-urgent workloads (ETL, batch, internal reports).
- Set **AUTO_SUSPEND** aggressively (60-120s) to avoid idle cluster costs.
- Pair with **Resource Monitors** to set hard credit caps.
- Monitor `WAREHOUSE_METERING_HISTORY` to track actual multi-cluster credit burn.
- Consider separate MCWs per workload type rather than one massive MCW for everything.

---

## 🔑 Key Takeaways

| | Concept | Description |
|---|---|---|
| 📦 | **Multi-Cluster** | Multiple compute clusters under one warehouse identity |
| ⚡ | **Auto-scale** | Snowflake dynamically adds/removes clusters based on load |
| 📈 | **Maximized** | All clusters always running; fixed cost, max throughput |
| 🔒 | **Standard Policy** | Prioritizes zero queuing; starts clusters proactively |
| 🔄 | **Economy Policy** | Prioritizes cost; only starts clusters for sustained load (6-min rule) |
| 💰 | **Credit Math** | Credits = warehouse_size_credits x active_clusters x time |

---

## 💡 Best Practices

### For Development/Testing

- Use single-cluster warehouses; MCW adds unnecessary cost for dev workloads.
- Test with `MAX_CLUSTER_COUNT = 2` to validate MCW behavior before production rollout.

### For Production

- **Dashboard/BI warehouses:** Standard policy, MAX = 3-5, MIN = 1.
- **ETL/Batch warehouses:** Economy policy, MAX = 2-3, MIN = 1.
- **Shared analytics:** Standard policy with Resource Monitor caps.
- Start conservative and increase MAX based on observed queuing in `QUERY_HISTORY`.
- Combine with QAS (auto-enabled on new MCWs) for both concurrency AND acceleration.

### Common Mistakes to Avoid

- **Using MCW to fix slow queries:** MCW helps concurrency, not single-query performance. Resize UP instead.
- **Setting MAX too high without monitoring:** You might burn credits on clusters that spin up for brief spikes and aren't needed.
- **Forgetting Resource Monitors:** MCW can consume credits rapidly during unexpected load spikes.
- **Using Maximized mode for variable workloads:** You pay for all clusters even during quiet periods. Use Auto-scale instead.
- **Not checking edition:** MCW requires Enterprise Edition or higher.

---

## 📊 Monitoring & Diagnostics

```sql
-- Check current cluster status for all MCWs
SHOW WAREHOUSES
  ->> SELECT "name", "size", "min_cluster_count", "max_cluster_count", "started_clusters", "scaling_policy"
        FROM $1
        WHERE "max_cluster_count" > 1;

-- Query queuing history (indicates need for more clusters)
SELECT
  WAREHOUSE_NAME,
  COUNT(*) AS total_queries,
  COUNT_IF(QUEUED_OVERLOAD_TIME > 0) AS queued_queries,
  ROUND(AVG(QUEUED_OVERLOAD_TIME) / 1000, 2) AS avg_queue_seconds,
  MAX(QUEUED_OVERLOAD_TIME) / 1000 AS max_queue_seconds
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE START_TIME >= DATEADD('day', -7, CURRENT_TIMESTAMP())
  AND WAREHOUSE_NAME IS NOT NULL
GROUP BY WAREHOUSE_NAME
HAVING queued_queries > 0
ORDER BY queued_queries DESC;

-- Multi-cluster credit consumption over time
SELECT
  WAREHOUSE_NAME,
  START_TIME::DATE AS usage_date,
  SUM(CREDITS_USED) AS total_credits
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE START_TIME >= DATEADD('day', -30, CURRENT_TIMESTAMP())
  AND WAREHOUSE_NAME IN (
    SELECT "name" FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
    WHERE "max_cluster_count" > 1
  )
GROUP BY WAREHOUSE_NAME, usage_date
ORDER BY WAREHOUSE_NAME, usage_date;

-- Cluster event history (scaling events)
SELECT
  WAREHOUSE_NAME,
  CLUSTER_NUMBER,
  EVENT_NAME,
  EVENT_STATE,
  TIMESTAMP
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_EVENTS_HISTORY
WHERE TIMESTAMP >= DATEADD('day', -7, CURRENT_TIMESTAMP())
  AND EVENT_NAME IN ('MULTI_CLUSTER_SCALE_OUT', 'MULTI_CLUSTER_SCALE_IN')
ORDER BY TIMESTAMP DESC
LIMIT 50;
```

---

## 🔗 Related Topics

- **Virtual Warehouses Overview** (Post #11) — Warehouse types, sizes, and generations
- **Warehouse Sizing & Scaling** (Post #13) — Scale UP strategies and credit-per-hour rates
- **Resource Monitors** (Post #15) — Setting credit caps to control MCW spend
- **Query Acceleration Service** — Auto-enabled for new MCWs, complements scale-out
- [Snowflake Docs: Multi-cluster Warehouses](https://docs.snowflake.com/en/user-guide/warehouses-multicluster) — Official reference

---

*This is Post 14 of my Snowflake LinkedIn Series — Phase 2: Virtual Warehouses & Compute.*

🔔 Follow along to master Snowflake, one concept at a time.

**Next up → Resource Monitors: Capping Credit Usage Before It Hurts 💰**

---

`#Snowflake #MultiCluster #AutoScaling #DataEngineering #CloudCompute #SQL #SnowflakeLinkedInSeries`
