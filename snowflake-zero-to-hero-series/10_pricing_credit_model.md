# 💰 Snowflake Pricing & Credit Model Explained

You've heard "pay only for what you use." But HOW does Snowflake actually charge you?

Let's demystify the credit model 👇

---

Snowflake does NOT charge a flat subscription fee.

Instead, it uses a **consumption-based pricing model** with two main cost components:

1. **Compute (Credits)**
2. **Storage ($/TB/month)**

That's it. No upfront licenses. No node reservations. No idle capacity costs.

---

## 🔷 COMPUTE — The Credit System

Everything compute-related is measured in **Snowflake Credits**.

A credit is a unit of compute consumption. Think of it like a token — you spend credits when virtual warehouses are running.

Credit consumption depends on:
- Warehouse size (XS, S, M, L, XL, 2XL, 3XL, 4XL, 5XL, 6XL)
- How long the warehouse runs
- Number of clusters (for multi-cluster warehouses)

### Credit-per-Hour Breakdown

| Warehouse Size | Credits/Hour |
|----------------|-------------|
| X-Small        | 1           |
| Small          | 2           |
| Medium         | 4           |
| Large          | 8           |
| X-Large        | 16          |
| 2X-Large       | 32          |
| 3X-Large       | 64          |
| 4X-Large       | 128         |
| 5X-Large       | 256         |
| 6X-Large       | 512         |

Each size **DOUBLES** the previous. More nodes = more parallelism = faster queries.

**Key detail:** Credits are billed per-second (minimum 60 seconds) once the warehouse starts.

---

## 🔷 STORAGE — Simple & Cheap

Storage is billed monthly based on the average compressed data stored.

**Includes:**
- Table data (compressed, columnar micro-partitions)
- Time Travel data (historical data retained for recovery)
- Fail-safe data (7-day disaster recovery, non-queryable)
- Staged files (internal stages)

**Approximate pricing:**
- On-Demand: ~$40/TB/month (varies by region & cloud)
- Capacity: ~$23/TB/month (pre-purchased)

Snowflake compresses data significantly (often 3-5x), so your effective cost per raw TB is even lower.

---

## 🔷 CLOUD SERVICES LAYER — The "Free" Tier (Mostly)

The Cloud Services layer handles:
- Authentication & access control
- Metadata management
- Query parsing & optimization
- Infrastructure management

You are **NOT charged** for Cloud Services UNLESS it exceeds **10% of your daily compute credit usage**.

**Example:**
- You consume 100 compute credits today
- Cloud Services used 8 credits
- 10% threshold = 10 credits
- 8 < 10, so Cloud Services is **FREE** today

In practice, most customers never pay for Cloud Services.

---

## 🔷 SERVERLESS FEATURES — Credits Without Warehouses

Some features consume credits WITHOUT a user-managed warehouse:

- Snowpipe (continuous data loading)
- Automatic Clustering (background re-clustering)
- Materialized View Maintenance
- Search Optimization Service
- Replication
- Serverless Tasks

These are billed at a Snowflake-managed compute rate and scale automatically.

---

## 🔷 PRICING MODELS — On-Demand vs Capacity

Snowflake offers two purchasing models:

### 1. On-Demand
- Pay per credit consumed
- No commitment
- Higher per-credit price
- **Best for:** testing, POCs, unpredictable workloads

### 2. Capacity (Pre-Purchased)
- Buy credits upfront (1-year or multi-year contracts)
- Lower per-credit price (significant discounts)
- Credits expire at end of contract term
- **Best for:** production workloads, predictable usage

---

## 🔷 EDITION PRICING — Feature-Based Tiers

The per-credit price also depends on your Snowflake edition:

| Edition | Target Use Case | Key Additions |
|---------|----------------|---------------|
| Standard | General analytics | Core features, 1-day Time Travel |
| Enterprise | Production workloads | Multi-cluster WH, 90-day Time Travel, Masking |
| Business Critical | Sensitive data | HIPAA/PCI compliance, Tri-Secret Secure, Failover |
| Virtual Private | Highest security | Fully isolated environment, dedicated metadata |

Higher edition = higher per-credit cost, but more features included.

---

## 💡 Cost Optimization Tips

1. **Auto-Suspend warehouses** (set to 1-5 minutes for ad-hoc, 0 for batch)
2. **Right-size warehouses** — bigger isn't always faster
3. **Use Resource Monitors** to set credit quotas and alerts
4. **Leverage result caching** — repeated queries don't consume credits
5. **Monitor with** `ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY`
6. **Use Capacity pricing** for production (20-30% savings)
7. **Separate workloads** into purpose-built warehouses (reporting, ETL, dev)

---

## 📊 Quick Formula

```
Monthly Cost ≈ (Credits Used × $/Credit) + (Avg TB Stored × $/TB) + Data Transfer
```

Where:
- **Credits Used** = Σ (Warehouse Size × Hours Running × Clusters)
- **Data Transfer** = charges for moving data between regions/clouds (egress)

---

## 🔥 Real-World Example

A team with:
- 1 Medium warehouse running 8 hours/day, 22 days/month
- 5 TB compressed storage (Enterprise, On-Demand, US East)

| Component | Calculation | Cost |
|-----------|-------------|------|
| Compute | 4 credits/hr × 8 hrs × 22 days = 704 credits | 704 × $3.50 = **$2,464** |
| Storage | 5 TB × $40/TB | **$200** |
| **Total** | | **~$2,664/month** |

With Capacity pricing at ~$2.50/credit: ≈ **$1,960/month** (26% savings)

---

## ⚠️ Common Mistakes

- ❌ Leaving warehouses running 24/7 with auto-suspend disabled
- ❌ Using XL warehouses for simple SELECT queries
- ❌ Ignoring Snowpipe & serverless credit usage
- ❌ Not monitoring Automatic Clustering credits on frequently-updated tables
- ❌ Overlooking Time Travel storage (especially with 90-day retention)

---

*This is Post 10 of my Snowflake LinkedIn Series — wrapping up Phase 1: Snowflake Foundations!*

🔔 Follow along if you want to master Snowflake, one concept at a time.

**Next up → Virtual Warehouses - What, Why & How They Work (entering Phase 2: Compute) ⚡**

---

`#Snowflake #DataEngineering #CloudData #CostOptimization #SnowflakeCredits #DataWarehouse #SnowflakeLinkedInSeries`
