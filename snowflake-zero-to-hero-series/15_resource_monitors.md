# 💰 Resource Monitors — Control Your Snowflake Spend Before It Controls You

Resource Monitors are Snowflake's built-in mechanism for tracking and controlling credit consumption by virtual warehouses. They allow you to set credit limits, define alert thresholds, and automatically suspend warehouses when spending exceeds your budget. If you're running Snowflake in production, resource monitors are one of your first lines of defense against runaway costs.

---

## 🔷 Why This Matters

- Virtual warehouses consume credits every second they're running — even if no queries are executing (until auto-suspend kicks in)
- A single misconfigured warehouse or runaway query can burn hundreds of credits overnight
- Without resource monitors, you rely on reactive cost review instead of proactive spend control
- Resource monitors provide automated guardrails that don't depend on human vigilance

---

## 🏷️ Core Concept

A **Resource Monitor** is a first-class Snowflake object that tracks the cumulative credit usage of one or more virtual warehouses. When usage reaches defined percentage thresholds of the allocated quota, the monitor triggers configurable actions.

### Credit Quota

The **credit quota** is the total number of Snowflake credits allocated to the monitor for a given frequency interval. This is the ceiling against which all trigger thresholds are evaluated.

- If you set a quota of 1000 credits with a monthly frequency, all percentage triggers reference that 1000 credit budget
- Unused credits do NOT roll over to the next period
- You can modify the quota at any time with `ALTER RESOURCE MONITOR`

### Frequency (Schedule)

The frequency determines how often the credit quota resets:

| Frequency | Behavior |
|-----------|----------|
| `DAILY` | Quota resets every day |
| `WEEKLY` | Quota resets every week |
| `MONTHLY` | Quota resets on the same day each month |
| `YEARLY` | Quota resets annually |
| `NEVER` | Quota never resets — one-time budget |

> **Note:** If `FREQUENCY = NEVER`, the monitor tracks cumulative usage from the `START_TIMESTAMP` indefinitely until manually reset or dropped.

### Triggers & Actions

Triggers fire when credit usage reaches a specified percentage of the quota. Snowflake supports three action types:

| Action | Keyword | Behavior |
|--------|---------|----------|
| **Notify** | `DO NOTIFY` | Sends alert notification only (email via Snowsight) |
| **Notify & Suspend** | `DO SUSPEND` | Sends alert + suspends warehouse after current queries complete |
| **Notify & Suspend Immediately** | `DO SUSPEND_IMMEDIATE` | Sends alert + immediately cancels running queries + suspends warehouse |

You can define multiple triggers at different thresholds on a single monitor:

```
TRIGGERS
  ON 50 PERCENT DO NOTIFY
  ON 75 PERCENT DO NOTIFY
  ON 90 PERCENT DO SUSPEND
  ON 100 PERCENT DO SUSPEND_IMMEDIATE;
```

### Assignment Levels

Resource monitors can be assigned at two levels:

| Level | Scope | SQL |
|-------|-------|-----|
| **Account** | Monitors ALL warehouses in the account | `ALTER ACCOUNT SET RESOURCE_MONITOR = monitor_name;` |
| **Warehouse** | Monitors a specific warehouse | `ALTER WAREHOUSE wh SET RESOURCE_MONITOR = monitor_name;` |

> **Important:** A warehouse with its own monitor is still subject to the account-level monitor as well. Both monitors apply in parallel — whichever threshold is reached first will trigger its action. Neither overrides the other.

---

## ⚙️ Configuration & Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `CREDIT_QUOTA` | Yes | Number of credits allocated per frequency period |
| `FREQUENCY` | No (default: `MONTHLY`) | Reset interval: DAILY, WEEKLY, MONTHLY, YEARLY, NEVER |
| `START_TIMESTAMP` | No (default: `IMMEDIATELY`) | When the monitor starts tracking |
| `END_TIMESTAMP` | No | When the monitor stops tracking (optional) |
| `TRIGGERS` | Yes | One or more trigger definitions at percentage thresholds |

### Notification Setup

For `NOTIFY` actions to work, users must be configured to receive notifications:

- Account admins receive notifications by default
- Other users must enable notification preferences in Snowsight
- Notifications appear in the Snowsight UI and are sent via email

---

## 🛠️ SQL Examples

### Basic Usage — Account-Level Monitor

```sql
-- Create a basic monthly resource monitor for the entire account
CREATE RESOURCE MONITOR account_monthly_monitor
  WITH
    CREDIT_QUOTA = 1000
    FREQUENCY = MONTHLY
    START_TIMESTAMP = IMMEDIATELY
    TRIGGERS
      ON 75 PERCENT DO NOTIFY
      ON 100 PERCENT DO SUSPEND;

-- Assign to the account
ALTER ACCOUNT SET RESOURCE_MONITOR = account_monthly_monitor;
```

### Intermediate Usage — Warehouse-Level with Escalating Triggers

```sql
-- Create a monitor with escalating actions for a specific warehouse
CREATE RESOURCE MONITOR etl_warehouse_monitor
  WITH
    CREDIT_QUOTA = 200
    FREQUENCY = WEEKLY
    START_TIMESTAMP = IMMEDIATELY
    TRIGGERS
      ON 50 PERCENT DO NOTIFY
      ON 75 PERCENT DO NOTIFY
      ON 90 PERCENT DO SUSPEND
      ON 100 PERCENT DO SUSPEND_IMMEDIATE;

-- Assign to a specific warehouse
ALTER WAREHOUSE etl_wh SET RESOURCE_MONITOR = etl_warehouse_monitor;
```

### Advanced — Time-Bounded Monitor (Project Budget)

```sql
-- One-time budget for a specific project (no reset)
CREATE RESOURCE MONITOR q3_migration_budget
  WITH
    CREDIT_QUOTA = 5000
    FREQUENCY = NEVER
    START_TIMESTAMP = '2026-07-01 00:00 UTC'
    END_TIMESTAMP = '2026-09-30 23:59 UTC'
    TRIGGERS
      ON 25 PERCENT DO NOTIFY
      ON 50 PERCENT DO NOTIFY
      ON 75 PERCENT DO SUSPEND
      ON 100 PERCENT DO SUSPEND_IMMEDIATE;

ALTER WAREHOUSE migration_wh SET RESOURCE_MONITOR = q3_migration_budget;
```

### Modification & Management

```sql
-- Modify an existing monitor's quota
ALTER RESOURCE MONITOR account_monthly_monitor
  SET CREDIT_QUOTA = 1500;

-- View all resource monitors
SHOW RESOURCE MONITORS;

-- Check a specific monitor's details
DESCRIBE RESOURCE MONITOR account_monthly_monitor;

-- Remove a monitor from a warehouse
ALTER WAREHOUSE etl_wh UNSET RESOURCE_MONITOR;

-- Drop a monitor entirely
DROP RESOURCE MONITOR q3_migration_budget;
```

---

## 📈 Scaling & Cost Implications

### Credit Consumption Reference

| Warehouse Size | Credits/Hour | Daily (8hr) | Monthly (22 days × 8hr) |
|---------------|-------------|-------------|--------------------------|
| X-Small | 1 | 8 | 176 |
| Small | 2 | 16 | 352 |
| Medium | 4 | 32 | 704 |
| Large | 8 | 64 | 1,408 |
| X-Large | 16 | 128 | 2,816 |
| 2X-Large | 32 | 256 | 5,632 |

### Setting Appropriate Quotas

- Review 2-4 weeks of historical usage before setting quotas
- Add 10-20% buffer above expected usage to avoid premature suspensions
- For new workloads, start conservative and adjust upward

---

## 💰 Limitations & Scope

> **Critical:** Resource monitors track credit consumption from **virtual warehouses only**. They do NOT cover:
> - Snowpipe (serverless)
> - Automatic Clustering
> - Materialized View maintenance
> - Search Optimization Service
> - Serverless Tasks
> - Cortex AI services
>
> For these, use **Budgets** (account-level or custom budgets) instead.

---

## 🔑 Key Takeaways

| | Concept | Description |
|---|---|---|
| 📦 | **Credit Quota** | The spending ceiling per frequency period |
| ⚡ | **Triggers** | Percentage-based thresholds that fire actions |
| 📈 | **Escalation** | Stack NOTIFY → SUSPEND → SUSPEND_IMMEDIATE |
| 🔒 | **Scope** | Warehouses only — use Budgets for serverless |
| 🔄 | **Reset** | Quota resets per frequency unless NEVER |
| 🛡️ | **Privilege** | Only ACCOUNTADMIN can CREATE (can grant to others) |

---

## 💡 Best Practices

### For Development/Testing
- Use low quotas (50-100 credits) on dev warehouses to catch mistakes early
- Set SUSPEND (not SUSPEND_IMMEDIATE) so running queries can finish
- Use `FREQUENCY = WEEKLY` for tighter dev budget cycles

### For Production
- Always have an account-level resource monitor as a catch-all
- Use warehouse-level monitors for team/workload-specific budgets
- Set multiple NOTIFY triggers before any SUSPEND trigger (50%, 75%, then suspend at 90%)
- Review and adjust quotas quarterly based on usage trends
- Document who gets notified and the escalation procedure when monitors trigger

### Common Mistakes to Avoid
- Setting only SUSPEND_IMMEDIATE with no warning triggers — causes query failures without advance notice
- Forgetting that suspended warehouses require manual intervention to resume
- Assuming resource monitors cover serverless features (they don't)
- Setting quotas too tight — causes false-alarm suspensions during legitimate usage spikes

---

## 📊 Monitoring & Diagnostics

```sql
-- View all resource monitors and their current usage
SHOW RESOURCE MONITORS;

-- Check warehouse credit usage over the last 30 days
SELECT
    WAREHOUSE_NAME,
    SUM(CREDITS_USED) AS total_credits,
    SUM(CREDITS_USED_COMPUTE) AS compute_credits,
    SUM(CREDITS_USED_CLOUD_SERVICES) AS cloud_services_credits
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE START_TIME >= DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY WAREHOUSE_NAME
ORDER BY total_credits DESC;

-- Identify warehouses without resource monitors
SELECT w.name AS warehouse_name, w.resource_monitor
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())) w
WHERE w.resource_monitor = 'null' OR w.resource_monitor IS NULL;

-- Daily credit consumption trend (helps set appropriate quotas)
SELECT
    DATE_TRUNC('day', START_TIME) AS usage_date,
    WAREHOUSE_NAME,
    SUM(CREDITS_USED) AS daily_credits
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE START_TIME >= DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY usage_date, WAREHOUSE_NAME
ORDER BY usage_date DESC, daily_credits DESC;
```

---

## 🔗 Related Topics

- **Virtual Warehouses** (Post #11) — understand what consumes the credits
- **Multi-cluster Warehouses & Auto-Scaling** (Post #14) — scaling increases credit burn
- **Poll: Surprised by your Snowflake bill?** (Post #16) — community experiences
- **Warehouse Best Practices** (Post #17) — right-sizing and suspend/resume strategies

---

*This is Post 15 of my Snowflake LinkedIn Series — Phase 2: Virtual Warehouses & Compute.*

🔔 Follow along to master Snowflake, one concept at a time.

**Next up → Poll: Have you ever been surprised by your Snowflake bill? 📊**

---

`#Snowflake #ResourceMonitors #CostOptimization #DataEngineering #SQL #CloudCompute #SnowflakeLinkedInSeries`
