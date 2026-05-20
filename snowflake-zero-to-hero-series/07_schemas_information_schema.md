# 🧊 Schemas & Information Schema — Metadata at Your Fingertips

Every Snowflake database has a hidden superpower: a built-in data dictionary that tells you EVERYTHING about your objects.

Let's explore Schemas and the INFORMATION_SCHEMA 👇

---

## 📁 What is a Schema?

A schema is a logical container within a database that groups related objects together.

Think of it like folders inside a database:

> **DATABASE → SCHEMA → Tables, Views, Stages, Pipes, Functions, etc.**

Every database can have multiple schemas, and every object lives inside one.

---

## 🔑 Key Schema Types:

| Type | Description |
|------|-------------|
| **Regular Schema** | Default, permanent storage with Time Travel |
| **Transient Schema** | No Fail-safe (saves storage costs for staging data) |
| **Managed Access Schema** | Only the schema owner or MANAGE GRANTS can grant privileges |

Creating schemas is simple:

```sql
CREATE SCHEMA analytics_schema;
CREATE TRANSIENT SCHEMA staging_schema;
CREATE SCHEMA secure_schema WITH MANAGED ACCESS;
```

---

## 📋 The INFORMATION_SCHEMA — Your Built-in Data Dictionary

Here's the game-changer: **every database in Snowflake automatically includes a read-only schema called INFORMATION_SCHEMA.**

It contains:
- Views showing metadata about ALL objects in the database
- Table functions for historical/usage data across your account

You don't create it. You don't maintain it. It's always there, always up to date.

---

## 🔍 Most Useful INFORMATION_SCHEMA Views:

| View | What It Shows |
|------|---------------|
| **TABLES** | All tables and views in the database |
| **COLUMNS** | Every column with data types and properties |
| **SCHEMATA** | All schemas in the database |
| **VIEWS** | View definitions and properties |
| **TABLE_PRIVILEGES** | Who has access to what |
| **STAGES** | Internal and external stages |
| **PIPES** | Snowpipe definitions |
| **FILE_FORMATS** | File format configurations |

---

## ⚡ Practical Examples:

### 1️⃣ List all tables in a schema:

```sql
SELECT TABLE_NAME, ROW_COUNT, BYTES
FROM MY_DB.INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'PUBLIC'
AND TABLE_TYPE = 'BASE TABLE';
```

### 2️⃣ Find all columns with VARIANT data type:

```sql
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM MY_DB.INFORMATION_SCHEMA.COLUMNS
WHERE DATA_TYPE = 'VARIANT';
```

### 3️⃣ Check schema properties:

```sql
SELECT SCHEMA_NAME, IS_TRANSIENT, IS_MANAGED_ACCESS, RETENTION_TIME
FROM MY_DB.INFORMATION_SCHEMA.SCHEMATA;
```

### 4️⃣ View recent login history (table function):

```sql
SELECT EVENT_TIMESTAMP, USER_NAME, CLIENT_IP
FROM TABLE(MY_DB.INFORMATION_SCHEMA.LOGIN_HISTORY(
    TIME_RANGE_START => DATEADD('hours', -24, CURRENT_TIMESTAMP())
));
```

---

## 📊 INFORMATION_SCHEMA Table Functions — Historical Data:

These give you operational insights:

| Table Function | Retention | Purpose |
|----------------|-----------|---------|
| `QUERY_HISTORY` | 7 days | Past queries |
| `LOGIN_HISTORY` | 7 days | User logins |
| `WAREHOUSE_METERING_HISTORY` | 6 months | Credit usage |
| `DATABASE_STORAGE_USAGE_HISTORY` | 6 months | Storage over time |
| `COPY_HISTORY` | 14 days | Data loading history |
| `TASK_HISTORY` | 7 days | Task execution details |

---

## ⚠️ Key Things to Remember:

1. **INFORMATION_SCHEMA is READ-ONLY** — you can't modify it
2. **Results depend on your current role's privileges** — you only see what you have access to
3. **Always use filters** — broad queries return an error: "query returned too much data"
4. **A running warehouse is required** to query these views
5. **It exists in EVERY database automatically**

---

## 🆚 INFORMATION_SCHEMA vs SHOW Commands:

| Aspect | SHOW Commands | INFORMATION_SCHEMA |
|--------|--------------|-------------------|
| **Case Sensitivity** | Case-insensitive | Standard SQL (case-sensitive) |
| **Warehouse Required** | No | Yes |
| **Default Scope** | Current schema | Entire database |
| **SQL Joinable** | No (requires RESULT_SCAN) | Yes |
| **Best For** | Quick exploration | Reporting & automation |

---

## 💡 Pro Tip:

Combine INFORMATION_SCHEMA with **ACCOUNT_USAGE** (in the SNOWFLAKE shared database) for even deeper insights:

| | INFORMATION_SCHEMA | ACCOUNT_USAGE |
|---|---|---|
| **Scope** | Current database | All databases |
| **Latency** | Real-time | Up to 45 min delay |
| **History** | Limited | Up to 365 days |

---

*This is Post 7 of my Snowflake LinkedIn Series — covering schemas, metadata, and the power of INFORMATION_SCHEMA.*

🔔 Follow along to master Snowflake one concept at a time.

**Next up → Poll: How do you organize your Snowflake databases? 🗂️**

---

`#Snowflake #DataEngineering #SQL #InformationSchema #Metadata #DataWarehouse #CloudData #SnowflakeLinkedInSeries`
