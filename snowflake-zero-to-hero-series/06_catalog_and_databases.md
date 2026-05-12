# 🗂️ Snowflake Catalog & Databases — Organization of Objects

Every well-architected Snowflake environment starts with a clean object hierarchy. If your databases are a mess, everything downstream suffers.

Let's understand how Snowflake organizes data 👇

---

Snowflake uses a 3-level hierarchy to organize all objects:

1. **Account** (top level)
2. **Database**
3. **Schema**

Every table, view, stage, pipe, stream, task, and function lives inside a Schema, which lives inside a Database.

---

## 🆔 Everything is an Object — Named + Internally ID-Tracked

Here's a key concept: **every entity in Snowflake is a first-class object** with two forms of identification:

**1. A name (identifier)** — what you use in SQL (up to 255 characters)
**2. An internal numeric ID** — what Snowflake uses under the hood to track everything

### Object Names (Identifiers)

Object names must be **unique within their parent scope**:

- **Account-level objects** (users, roles, warehouses, databases) → unique across the entire account
- **Schemas** → unique within their database
- **Schema objects** (tables, views, stages, pipes, etc.) → unique within their schema
- **Columns** → unique within their table

Every object is referenced using its **fully qualified name**:

```
DATABASE_NAME.SCHEMA_NAME.OBJECT_NAME
```

💡 Snowflake treats identifiers as case-insensitive by default (stored as UPPERCASE). Use double quotes to preserve case: `"myTable"` ≠ `MYTABLE`.

### Internal Object IDs (The Hidden Backbone)

Behind every name, Snowflake assigns a **unique numeric ID** that persists across renames, drops, and time travel. You can see these in `SNOWFLAKE.ACCOUNT_USAGE`:

| Object | ID Column | View |
|--------|-----------|------|
| Database | `DATABASE_ID` | ACCOUNT_USAGE.DATABASES |
| Schema | `SCHEMA_ID` | ACCOUNT_USAGE.SCHEMATA |
| Table | `TABLE_ID` | ACCOUNT_USAGE.TABLES |
| View | `TABLE_ID` | ACCOUNT_USAGE.VIEWS |
| Stage | `STAGE_ID` | ACCOUNT_USAGE.STAGES |
| Pipe | `PIPE_ID` | ACCOUNT_USAGE.PIPES |
| Function | `FUNCTION_ID` | ACCOUNT_USAGE.FUNCTIONS |
| Role | `ROLE_ID` | ACCOUNT_USAGE.ROLES |
| User | `USER_ID` | ACCOUNT_USAGE.USERS |
| Warehouse | `WAREHOUSE_ID` | ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY |

```sql
-- See the internal ID chain: Table → Schema → Database
SELECT TABLE_ID, TABLE_NAME, TABLE_SCHEMA_ID, TABLE_CATALOG_ID
FROM SNOWFLAKE.ACCOUNT_USAGE.TABLES
WHERE DELETED IS NULL
LIMIT 5;
```

These internal IDs are what enable:

- ✅ **Time Travel** — Snowflake references the exact object state at any point by ID
- ✅ **Cloning** — a clone gets its own ID but shares underlying micro-partitions
- ✅ **UNDROP** — the object ID persists even after DROP, so Snowflake can restore it
- ✅ **Access History & Lineage** — every access is tracked by object ID, not name
- ✅ **Object chain mapping** — you can trace TABLE_ID → TABLE_SCHEMA_ID → TABLE_CATALOG_ID

💡 Even if you RENAME an object, the internal ID stays the same. That's how Snowflake maintains continuity for lineage and audit trails.

---

## 🏗️ The Object Hierarchy

```
Account
 └── Database
      └── Schema
           ├── Tables
           ├── Views
           ├── Stages
           ├── Pipes
           ├── Streams
           ├── Tasks
           ├── Functions / Procedures
           ├── Sequences
           └── File Formats
```

Think of it like folders on your computer:
- **Database** = Drive
- **Schema** = Folder
- **Objects** = Files

---

## 📦 Databases — The Top-Level Container

A database is the highest-level container for data objects. You can have hundreds of databases in one account.

Key facts:
- ✅ Each database is independent and isolated
- ✅ Databases can be permanent, transient, or cloned
- ✅ Cross-database queries are fully supported (no linked servers needed!)
- ✅ Databases can be shared across accounts via Secure Data Sharing
- ✅ Time Travel & Fail-safe apply at the database level

Creating a database:
```sql
CREATE DATABASE analytics_prod;
CREATE DATABASE analytics_dev;
CREATE TRANSIENT DATABASE staging_temp;
```

---

## 📁 Schemas — Organizing Within a Database

Schemas group related objects within a database. Every database comes with two default schemas:

- **PUBLIC** — default schema (where objects go if you don't specify)
- **INFORMATION_SCHEMA** — read-only metadata views (Snowflake system)

**Best practice:** NEVER put production objects in PUBLIC. Create purpose-built schemas.

```sql
CREATE SCHEMA analytics_prod.raw;
CREATE SCHEMA analytics_prod.staging;
CREATE SCHEMA analytics_prod.curated;
CREATE SCHEMA analytics_prod.reporting;
```

---

## 🔍 Fully Qualified Names

In Snowflake, every object has a fully qualified name:

**`DATABASE.SCHEMA.OBJECT`**

Examples:
- `analytics_prod.raw.orders`
- `analytics_prod.curated.dim_customers`
- `marketing_db.public.campaigns`

You can set context to avoid typing the full path every time:
```sql
USE DATABASE analytics_prod;
USE SCHEMA curated;

-- Now you can just write:
SELECT * FROM dim_customers;
```

---

## 📊 Common Database Organization Patterns

**1️⃣ Per Environment:**
- `PROD_DB` / `DEV_DB` / `TEST_DB`

**2️⃣ Per Domain:**
- `SALES_DB` / `MARKETING_DB` / `FINANCE_DB` / `HR_DB`

**3️⃣ Per Layer (Medallion):**
- `RAW_DB` / `STAGING_DB` / `CURATED_DB` / `ANALYTICS_DB`

**4️⃣ Hybrid (most common):**
- `PROD_RAW` / `PROD_CURATED` / `PROD_ANALYTICS`
- `DEV_RAW` / `DEV_CURATED` / `DEV_ANALYTICS`

💡 The hybrid approach gives you both environment isolation AND logical separation.

---

## 🗄️ INFORMATION_SCHEMA — Your Metadata Goldmine

Every database has a built-in INFORMATION_SCHEMA with metadata views:

```sql
-- List all tables in a database
SELECT table_name, table_schema, row_count, bytes
FROM analytics_prod.INFORMATION_SCHEMA.TABLES
WHERE table_schema != 'INFORMATION_SCHEMA';

-- List all columns for a table
SELECT column_name, data_type, is_nullable
FROM analytics_prod.INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'ORDERS';

-- List all schemas
SELECT schema_name, created
FROM analytics_prod.INFORMATION_SCHEMA.SCHEMATA;
```

---

## 🌐 SNOWFLAKE Database — Account-Level Metadata

Snowflake provides a special shared database called **SNOWFLAKE** with account-wide views:

- **SNOWFLAKE.ACCOUNT_USAGE** — query history, login history, storage, credits
- **SNOWFLAKE.ORGANIZATION_USAGE** — org-level billing & accounts
- **SNOWFLAKE.READER_ACCOUNT_USAGE** — reader account activity
- **SNOWFLAKE.DATA_SHARING_USAGE** — sharing metrics

```sql
-- Who ran the most queries this week?
SELECT user_name, COUNT(*) as query_count
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
GROUP BY user_name
ORDER BY query_count DESC
LIMIT 10;
```

---

## ⚡ Key Tips & Best Practices

- ✅ Use meaningful database names (not DB1, DB2, DB3)
- ✅ Create separate schemas for raw, staging, and curated data
- ✅ Use transient databases/schemas for temporary workloads (no fail-safe cost)
- ✅ Leverage INFORMATION_SCHEMA for automated documentation
- ✅ Use cross-database queries instead of duplicating data
- ✅ Set default warehouse, database, and schema on roles for user convenience
- ✅ Don't forget: DROP DATABASE is recoverable via UNDROP (within Time Travel period)

---

*This is Post 6 of my Snowflake LinkedIn Series — a 130-post deep dive covering everything from architecture to Cortex AI.*

🔔 Follow along if you want to master Snowflake, one concept at a time.

**Next up → Post 7: Schemas & Information Schema - Metadata at Your Fingertips 🔎**

---

`#Snowflake #DataEngineering #CloudData #Databases #DataArchitecture #SnowflakeCatalog #DataPlatform #SnowflakeLinkedInSeries`
