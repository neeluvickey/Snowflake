<!-- ================================================================================ 📋 SNOWFLAKE LINKEDIN SERIES — POST 21 DETAILED REFERENCE ================================================================================ -->

## 🧬 Snowflake Data Types — VARIANT, ARRAY, OBJECT & Beyond

Snowflake supports a rich set of data types spanning traditional SQL primitives and powerful semi-structured containers. While most SQL databases force you to normalize JSON into rigid relational schemas before loading, Snowflake lets you store, query, and transform hierarchical data natively. This post covers the full type system with special depth on VARIANT, ARRAY, and OBJECT — the trio that makes Snowflake's semi-structured support best-in-class.

Understanding these types is essential for anyone working with JSON APIs, event streams, IoT data, nested Parquet/Avro, or any schema-on-read use case.

---

## 🔷 Why This Matters

Modern data pipelines rarely deliver perfectly flat, relational data. APIs return nested JSON. Event systems emit arrays of objects. ML feature stores use variable-length vectors. Parquet files contain deeply nested structs.

Without native semi-structured support, you'd need to:
- Flatten everything in ETL before loading (fragile, slow)
- Maintain a separate document store (complexity, data silos)
- Lose schema evolution flexibility (breaking changes on every API update)

Snowflake's VARIANT ecosystem eliminates all three problems. Load first, schema later.

---

## 🏷️ Core Concept

### The Type Hierarchy

Snowflake data types fall into two categories:

**Scalar Types** — hold a single value:
- `NUMBER` (including `INT`, `INTEGER`, `BIGINT`, `DECIMAL`, `NUMERIC`, `FLOAT`, `DOUBLE`)
- `VARCHAR` (including `STRING`, `TEXT`, `CHAR`)
- `BINARY` (including `VARBINARY`)
- `BOOLEAN`
- `DATE`
- `TIME`
- `TIMESTAMP_LTZ`, `TIMESTAMP_NTZ`, `TIMESTAMP_TZ`

**Semi-Structured Types** — hold complex/nested values:
- `VARIANT` — universal container, holds any single value of any type
- `OBJECT` — unordered set of key-value pairs (keys: VARCHAR, values: VARIANT)
- `ARRAY` — ordered sequence of VARIANT values

**Structured Types** (typed versions of the above):
- `OBJECT(key1 TYPE1, key2 TYPE2, ...)` — typed object with defined schema
- `ARRAY(TYPE)` — typed array where all elements share the same type
- `MAP(KEY_TYPE, VALUE_TYPE)` — typed key-value mapping

### VARIANT: The Universal Container

**VARIANT** is the foundational semi-structured type. It can hold:
- Any scalar value (number, string, boolean, date, timestamp, binary)
- An OBJECT (nested key-value structure)
- An ARRAY (ordered list)
- NULL

```sql
-- VARIANT holding different value types
SELECT 
  PARSE_JSON('42')::VARIANT AS a_number,
  PARSE_JSON('"hello"')::VARIANT AS a_string,
  PARSE_JSON('true')::VARIANT AS a_boolean,
  PARSE_JSON('{"x": 1}')::VARIANT AS an_object,
  PARSE_JSON('[1,2,3]')::VARIANT AS an_array;
```

Key characteristics:
- **Max size**: 128 MB uncompressed per value
- **Self-describing**: stores type metadata alongside the value
- **Columnar storage**: Snowflake automatically decomposes VARIANT into columnar sub-columns for performance
- **Type preservation**: numbers stay as numbers, strings as strings (use `TYPEOF()` to inspect)

### OBJECT: Key-Value Pairs

**OBJECT** represents an unordered collection of key-value pairs, equivalent to a JSON object or Python dictionary.

```sql
-- Creating objects
SELECT OBJECT_CONSTRUCT('name', 'Snowflake', 'year', 2012, 'cloud', TRUE) AS company;
-- Result: {"cloud":true,"name":"Snowflake","year":2012}
```

Rules:
- Keys are always VARCHAR
- Values are always VARIANT internally
- Keys are case-sensitive when accessed
- Duplicate keys: last one wins during construction

### ARRAY: Ordered Lists

**ARRAY** is an ordered sequence where each element is a VARIANT value.

```sql
-- Creating arrays
SELECT ARRAY_CONSTRUCT(1, 2, 3, 4, 5) AS numbers;
-- Result: [1,2,3,4,5]

-- Arrays can hold mixed types
SELECT ARRAY_CONSTRUCT('text', 42, TRUE, NULL, PARSE_JSON('{"nested": true}')) AS mixed;

-- Array size
SELECT ARRAY_SIZE(ARRAY_CONSTRUCT(1, 2, 3, 4, 5)) AS size;
-- Result: 5
```

---

## 📊 Comparison / Feature Matrix

| Feature | VARIANT | OBJECT | ARRAY | Structured OBJECT | Structured ARRAY | MAP |
|---------|---------|--------|-------|-------------------|------------------|-----|
| Schema required | No | No | No | Yes (defined keys) | Yes (element type) | Yes (key + value types) |
| Nesting | Unlimited | Unlimited | Unlimited | Unlimited | Unlimited | Unlimited |
| Max size | 128 MB | 128 MB | 128 MB | 128 MB | 128 MB | 128 MB |
| Type enforcement | Runtime cast | Runtime cast | Runtime cast | Compile-time | Compile-time | Compile-time |
| Null handling | VARIANT NULL vs SQL NULL | Same | Same | SQL NULL per field | SQL NULL per element | SQL NULL per entry |
| Construction | PARSE_JSON, TO_VARIANT | OBJECT_CONSTRUCT | ARRAY_CONSTRUCT | Literal cast | Literal cast | Literal cast |
| Best for | Raw ingestion | Known key structures | Lists, sequences | Stable schemas | Typed collections | Lookups |

> **Note**: Semi-structured types store type information per-value. Structured types validate at write time and reject mismatched types, providing stronger guarantees but less flexibility.

---

## ⚙️ Configuration & Parameters

### File Format Parameters for Semi-Structured Loading

| Parameter | Default | Options | Description |
|-----------|---------|---------|-------------|
| `TYPE` | — | JSON, AVRO, PARQUET, ORC | Source format for VARIANT loading |
| `STRIP_OUTER_ARRAY` | FALSE | TRUE/FALSE | Remove outer array brackets (load each element as a row) |
| `STRIP_NULL_VALUES` | FALSE | TRUE/FALSE | Omit keys with NULL values from OBJECT |
| `ALLOW_DUPLICATE` | FALSE | TRUE/FALSE | Allow duplicate object keys |
| `NULL_IF` | — | String list | Values to treat as SQL NULL |

### VARIANT Column Behavior

| Aspect | Behavior |
|--------|----------|
| Columnar decomposition | Automatic — Snowflake detects repeated paths and stores as sub-columns |
| Pruning | Works on detected sub-columns (similar to regular columns) |
| Statistics | Min/max maintained per sub-column for partition pruning |
| Casting cost | Minimal — type info stored alongside value |

---

## 🛠️ SQL Examples

### Basic Usage — Loading and Querying JSON

```sql
-- Create table with VARIANT column
CREATE OR REPLACE TABLE events (
  event_id NUMBER AUTOINCREMENT,
  received_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  raw VARIANT
);

-- Load from stage
COPY INTO events (raw)
  FROM @my_stage
  FILE_FORMAT = (TYPE = 'JSON' STRIP_OUTER_ARRAY = TRUE);

-- Query nested fields with dot notation
SELECT 
  raw:user.name::VARCHAR AS user_name,
  raw:user.age::NUMBER AS user_age,
  raw:user.tags[0]::VARCHAR AS first_tag,
  raw:created_at::TIMESTAMP_NTZ AS created_ts,
  raw:score::FLOAT AS score,
  TYPEOF(raw:score) AS score_type
FROM events;
```

### Intermediate Usage — FLATTEN for Arrays

```sql
-- Explode array elements into rows using LATERAL FLATTEN
SELECT 
  f.value:name::VARCHAR AS item_name, 
  f.value:qty::NUMBER AS quantity
FROM (
  SELECT PARSE_JSON('[{"name":"Widget","qty":10},{"name":"Gadget","qty":5}]') AS items
) t,
LATERAL FLATTEN(input => t.items) f;

-- Result:
-- ITEM_NAME | QUANTITY
-- Widget    | 10
-- Gadget    | 5
```

FLATTEN output columns:
- `f.seq` — unique sequence number across all input rows
- `f.key` — key (for objects) or index (for arrays)
- `f.path` — path to the element
- `f.index` — array index (NULL for objects)
- `f.value` — the flattened value (VARIANT)
- `f.this` — the input value being flattened

### Advanced Usage — Construction, Aggregation, and Structured Types

```sql
-- Build objects dynamically
SELECT OBJECT_CONSTRUCT(
  'name', 'Snowflake',
  'type', 'cloud'
) AS obj;
-- Result: {"name":"Snowflake","type":"cloud"}

-- Aggregate rows into arrays
SELECT ARRAY_AGG(column1) AS all_vals 
FROM VALUES (10),(20),(30),(40),(50);
-- Result: [10,20,30,40,50]

-- Structured (typed) OBJECT
SELECT {'city': 'London', 'zip': 12345}::OBJECT(city VARCHAR, zip NUMBER) AS typed_obj;

-- Structured (typed) ARRAY
SELECT [1, 2, 3]::ARRAY(NUMBER) AS typed_arr;

-- Typed MAP
SELECT {'a': 1, 'b': 2, 'c': 3}::MAP(VARCHAR, NUMBER) AS my_map;
```

### Management & Inspection

```sql
-- Check what type a VARIANT value actually holds
SELECT TYPEOF(PARSE_JSON('{"key": "value"}')) AS t1,  -- OBJECT
       TYPEOF(PARSE_JSON('[1,2,3]')) AS t2,            -- ARRAY
       TYPEOF(PARSE_JSON('"hello"')) AS t3;            -- VARCHAR

-- Check if key exists
SELECT raw:user.email IS NOT NULL AS has_email FROM events;

-- Get all keys from an OBJECT
SELECT OBJECT_KEYS(PARSE_JSON('{"a":1,"b":2,"c":3}'));
-- Result: ["a","b","c"]

-- Array manipulation
SELECT 
  ARRAY_APPEND(ARRAY_CONSTRUCT(1,2,3), 4) AS appended,        -- [1,2,3,4]
  ARRAY_PREPEND(ARRAY_CONSTRUCT(2,3,4), 1) AS prepended,      -- [1,2,3,4]
  ARRAY_SLICE(ARRAY_CONSTRUCT(1,2,3,4,5), 1, 3) AS sliced,    -- [2,3]
  ARRAY_CONTAINS(3::VARIANT, ARRAY_CONSTRUCT(1,2,3)) AS has_3; -- TRUE
```

---

## 📈 Scaling & Performance

### Columnar Decomposition (Automatic Optimization)

When you load data into a VARIANT column, Snowflake doesn't just store a blob. It analyzes the structure and automatically creates **columnar sub-columns** for frequently accessed paths. This means:

- `SELECT raw:user.name FROM events` can skip scanning unrelated paths
- Partition pruning works on sub-column min/max statistics
- Performance approaches that of native relational columns for common access patterns

### When Performance Degrades

- **Deeply nested access** (5+ levels) — consider flattening hot paths into regular columns
- **Highly polymorphic data** — if the same path holds different types across rows, decomposition is less effective
- **Very large VARIANT values** (approaching 128 MB) — consider splitting into multiple columns
- **Frequent full-document scans** — if you always read the entire VARIANT, consider materializing fields

### Optimization Tips

1. **Materialize hot paths**: For frequently queried nested fields, create a view or materialized column
2. **Use explicit casts**: `::VARCHAR`, `::NUMBER` help the optimizer understand data types
3. **Filter early**: Push predicates on VARIANT paths as early as possible in CTEs/subqueries
4. **FLATTEN with path**: Use `FLATTEN(input => raw, path => 'specific.path')` to avoid processing the entire document

---

## 💰 Cost Implications

Semi-structured storage in Snowflake is **compressed columnar** — no premium vs regular columns.

| Scenario | Cost Impact |
|----------|-------------|
| Storing raw JSON in VARIANT | Same per-TB rate as regular columns. Compression often 3-10x. |
| Querying nested paths | Same credit consumption as regular column access (sub-column optimization) |
| FLATTEN on large arrays | Increases row count, can increase compute time proportionally |
| Loading JSON vs structured columns | No difference in COPY INTO cost |

### Cost Optimization Strategies

1. **Don't duplicate**: Don't extract VARIANT fields into separate columns unless you have a proven query performance need — you'd pay double storage
2. **Filter before FLATTEN**: Reduce rows before exploding arrays to minimize compute
3. **Use clustering on extracted paths**: If you always filter on `raw:event_type`, consider a clustering key on that expression

---

## 🔑 Key Takeaways

| Icon | Concept | Description |
|------|---------|-------------|
| 📦 | VARIANT | Universal container — holds any single value of any type, max 128 MB |
| 🔷 | OBJECT | Unordered key-value pairs — keys are VARCHAR, values are VARIANT |
| 📈 | ARRAY | Ordered list of VARIANT values — zero-indexed, variable length |
| ⚡ | Dot notation | `raw:key.subkey[0]::TYPE` for traversal and casting |
| 🔄 | FLATTEN | Explodes arrays/objects into rows for relational-style querying |
| 🔒 | Structured types | `OBJECT(...)`, `ARRAY(TYPE)`, `MAP(K,V)` for compile-time type safety |
| 💡 | TYPEOF() | Inspect the actual type stored in any VARIANT value at runtime |

---

## 💡 Best Practices

### For Development/Testing
- Load raw JSON/Parquet into VARIANT first, explore with dot notation, then decide on schema
- Use `TYPEOF()` and `OBJECT_KEYS()` to understand incoming data shape
- Test casts explicitly — VARIANT-to-TIMESTAMP requires the value to be in ISO format

### For Production
- Materialize frequently accessed paths as virtual columns or views for discoverability
- Use structured types (`ARRAY(NUMBER)`, `OBJECT(...)`) when schema is stable — catches bugs at write time
- Set `STRIP_OUTER_ARRAY = TRUE` when loading JSON arrays so each element becomes a row
- Add explicit casts in all production queries — never leave values as raw VARIANT in final output
- Document your VARIANT schema (what paths exist, what types they hold) even though Snowflake doesn't enforce it

### Common Mistakes to Avoid
- **Forgetting `::` casts** — comparisons on raw VARIANT use VARIANT comparison rules, not the underlying type
- **Assuming date strings are dates** — VARIANT stores timestamps as strings; you must cast with `::TIMESTAMP`
- **Using FLATTEN without understanding output** — always alias `f.value`, `f.key`, `f.index` explicitly
- **Storing numbers as strings in JSON** — `"42"` and `42` are different types in VARIANT; affects sorting and aggregation
- **VARIANT NULL vs SQL NULL** — `PARSE_JSON('null')` produces a VARIANT null (not SQL NULL); use `IS NULL` vs `= 'null'::VARIANT` carefully

---

## 📊 Monitoring & Diagnostics

```sql
-- Check column data types in a table
DESCRIBE TABLE events;

-- Inspect VARIANT sub-column statistics (micro-partition metadata)
-- Useful to verify columnar decomposition is happening
SELECT 
  SYSTEM$CLUSTERING_INFORMATION('events', '(raw:event_type)')
;

-- Find tables using VARIANT columns in your schemas
SELECT table_catalog, table_schema, table_name, column_name, data_type
FROM information_schema.columns
WHERE data_type IN ('VARIANT', 'OBJECT', 'ARRAY')
ORDER BY table_catalog, table_schema, table_name;

-- Check storage impact of semi-structured columns
SELECT 
  table_name,
  active_bytes / (1024*1024*1024) AS active_gb,
  time_travel_bytes / (1024*1024*1024) AS time_travel_gb
FROM snowflake.account_usage.table_storage_metrics
WHERE table_name = 'EVENTS'
  AND active_bytes > 0
ORDER BY active_bytes DESC;
```

---

## 🔗 Related Topics

- **Working with Semi-Structured Data** (Post 22) — deep patterns for JSON/Parquet/Avro pipelines
- **Table Types & Structures** (Post 20) — permanent, transient, temporary, external, dynamic tables
- **Stages & Data Loading** (Phase 4) — COPY INTO, file formats, transformation on load
- [Snowflake Docs: Semi-structured Data Types](https://docs.snowflake.com/en/sql-reference/data-types-semistructured) — official reference
- [Snowflake Docs: Querying Semi-structured Data](https://docs.snowflake.com/en/user-guide/querying-semistructured) — dot notation, FLATTEN, path expressions

---

This is Post 21 of my Snowflake LinkedIn Series — Phase 3: Tables & Data Types.

🔔 Follow along to master Snowflake, one concept at a time.

Next up → Working with Semi-Structured Data (JSON, Parquet, Avro) 📄

#Snowflake #DataTypes #VARIANT #SemiStructuredData #DataEngineering #SQL #SnowflakeLinkedInSeries
