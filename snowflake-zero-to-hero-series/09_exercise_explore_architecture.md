# 🧊 Snowflake Hands-On Exercise — Day 9

## Create Databases, Schemas & Inspect Metadata

Time to practice! Here are exercises to test what you've learned so far. 👇

Try these on your own Snowflake account — answers at the bottom.

---

## 📝 Exercise 1: Build a Multi-Layer Database

**Task:** Create a database called `ECOMMERCE_DB` with 3 schemas: `RAW`, `TRANSFORMED`, `REPORTING`

<details>
<summary>💡 Solution</summary>

```sql
CREATE DATABASE ECOMMERCE_DB;

CREATE SCHEMA ECOMMERCE_DB.RAW;
CREATE SCHEMA ECOMMERCE_DB.TRANSFORMED;
CREATE SCHEMA ECOMMERCE_DB.REPORTING;

-- Verify
SHOW SCHEMAS IN DATABASE ECOMMERCE_DB;
```
</details>

---

## 📝 Exercise 2: Create Tables with Different Data Types

**Task:** In the `RAW` schema, create:
- A `customers` table with: id (auto-increment), name, email, created_at (default today), raw_json (semi-structured)
- An `orders` table with: order_id, customer_id, order_date, amount, status

<details>
<summary>💡 Solution</summary>

```sql
USE SCHEMA ECOMMERCE_DB.RAW;

CREATE TABLE customers (
    id          INT AUTOINCREMENT,
    name        VARCHAR(100) NOT NULL,
    email       VARCHAR(200),
    created_at  TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    raw_json    VARIANT
);

CREATE TABLE orders (
    order_id    INT AUTOINCREMENT,
    customer_id INT NOT NULL,
    order_date  DATE DEFAULT CURRENT_DATE(),
    amount      NUMBER(10,2),
    status      VARCHAR(20) DEFAULT 'pending'
);
```
</details>

---

## 📝 Exercise 3: Insert & Query Semi-Structured Data

**Task:** Insert 3 customers with JSON metadata and query a nested field from the VARIANT column.

<details>
<summary>💡 Solution</summary>

```sql
INSERT INTO ECOMMERCE_DB.RAW.customers (name, email, raw_json) VALUES
('Alice', 'alice@test.com', PARSE_JSON('{"plan": "pro", "source": "google", "tags": ["vip", "early_adopter"]}')),
('Bob', 'bob@test.com', PARSE_JSON('{"plan": "free", "source": "direct", "tags": ["trial"]}')),
('Charlie', 'charlie@test.com', PARSE_JSON('{"plan": "enterprise", "source": "sales", "tags": ["corp", "annual"]}'));

-- Query nested JSON
SELECT
    name,
    raw_json:plan::STRING AS plan,
    raw_json:source::STRING AS source,
    raw_json:tags[0]::STRING AS first_tag
FROM ECOMMERCE_DB.RAW.customers;
```
</details>

---

## 📝 Exercise 4: Create a View in the REPORTING Schema

**Task:** Create a view `ECOMMERCE_DB.REPORTING.customer_summary` that shows customer name, plan, and how many days since they signed up.

<details>
<summary>💡 Solution</summary>

```sql
CREATE VIEW ECOMMERCE_DB.REPORTING.customer_summary AS
SELECT
    name,
    email,
    raw_json:plan::STRING AS plan,
    DATEDIFF(day, created_at, CURRENT_TIMESTAMP()) AS days_since_signup
FROM ECOMMERCE_DB.RAW.customers;

-- Test it
SELECT * FROM ECOMMERCE_DB.REPORTING.customer_summary;
```
</details>

---

## 📝 Exercise 5: Inspect Metadata Using INFORMATION_SCHEMA

**Task:** Write queries to find:
1. All tables in the RAW schema with their row counts
2. All columns in the `customers` table with data types
3. All views in the REPORTING schema

<details>
<summary>💡 Solution</summary>

```sql
-- 1. Tables with row counts
SELECT table_name, row_count, bytes, created
FROM ECOMMERCE_DB.INFORMATION_SCHEMA.TABLES
WHERE table_schema = 'RAW'
  AND table_type = 'BASE TABLE';

-- 2. Columns in customers
SELECT column_name, data_type, is_nullable, column_default
FROM ECOMMERCE_DB.INFORMATION_SCHEMA.COLUMNS
WHERE table_schema = 'RAW'
  AND table_name = 'CUSTOMERS'
ORDER BY ordinal_position;

-- 3. Views in REPORTING
SELECT table_name, view_definition
FROM ECOMMERCE_DB.INFORMATION_SCHEMA.VIEWS
WHERE table_schema = 'REPORTING';
```
</details>

---

## 📝 Exercise 6: Use SHOW Commands & RESULT_SCAN

**Task:** Use `SHOW TABLES` and then filter the results to only show tables with more than 0 rows using `RESULT_SCAN`.

<details>
<summary>💡 Solution</summary>

```sql
SHOW TABLES IN SCHEMA ECOMMERCE_DB.RAW;

SELECT "name", "rows", "bytes", "created_on"
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "rows" > 0;
```
</details>

---

## 📝 Exercise 7: Database & Schema Operations

**Task:**
1. Clone the RAW schema (zero-copy)
2. Rename the clone to `RAW_BACKUP`
3. Drop the clone
4. Use Time Travel to check what existed 5 minutes ago

<details>
<summary>💡 Solution</summary>

```sql
-- 1. Clone (instant, no extra storage)
CREATE SCHEMA ECOMMERCE_DB.RAW_CLONE CLONE ECOMMERCE_DB.RAW;

-- 2. Rename
ALTER SCHEMA ECOMMERCE_DB.RAW_CLONE RENAME TO ECOMMERCE_DB.RAW_BACKUP;

-- 3. Drop
DROP SCHEMA ECOMMERCE_DB.RAW_BACKUP;

-- 4. Time Travel - see what existed 5 min ago
SELECT *
FROM ECOMMERCE_DB.RAW.CUSTOMERS
AT(OFFSET => -300);
```
</details>

---

## 📝 Bonus Challenge: Query ACCOUNT_USAGE

**Task:** Find all objects YOU created in the last hour across the entire account.

<details>
<summary>💡 Solution</summary>

```sql
SELECT
    table_catalog AS database_name,
    table_schema AS schema_name,
    table_name,
    table_type,
    table_owner,
    created
FROM SNOWFLAKE.ACCOUNT_USAGE.TABLES
WHERE table_owner = CURRENT_USER()
  AND created >= DATEADD(hour, -1, CURRENT_TIMESTAMP())
ORDER BY created DESC;
```
</details>

---

## 🧹 Cleanup

```sql
DROP DATABASE IF EXISTS ECOMMERCE_DB;
```

---

## 🧠 What You Practiced:

| Skill | Commands Used |
|-------|-------------|
| Create objects | CREATE DATABASE, SCHEMA, TABLE, VIEW |
| Semi-structured data | VARIANT, PARSE_JSON, colon notation |
| Metadata inspection | INFORMATION_SCHEMA views |
| SHOW + RESULT_SCAN | SHOW TABLES, TABLE(RESULT_SCAN()) |
| Zero-copy clone | CREATE ... CLONE |
| Time Travel | AT(OFFSET => -N) |
| Account-level metadata | SNOWFLAKE.ACCOUNT_USAGE |

---

*This is Post 9 of my Snowflake LinkedIn Series — hands-on, one concept at a time.*

🔔 Try these exercises and drop your answers in the comments!

**Next up → Post 10: Snowflake Pricing & Credit Model Explained 💰**

---

`#Snowflake #DataEngineering #SQL #HandsOn #Exercise #Database #Schema #SnowflakeLinkedInSeries`
