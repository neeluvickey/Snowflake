# 📦 Post 23: Hands-on: Load & Query JSON Data in Snowflake

## 🎯 Objective

This exercise follows **Post 23** in Phase 3 of the Snowflake LinkedIn
Series: **Tables & Data Types**.

The master plan identifies Post 23 as:

> Hands-on: Load & Query JSON Data in Snowflake

The exercise demonstrates the core workflow of storing JSON in a
`VARIANT` column, navigating JSON paths, casting values, and using
`FLATTEN` to turn an array into rows.

## 1. Create a Table for JSON

``` sql
CREATE OR REPLACE TABLE json_demo (
  src VARIANT
);
```

`VARIANT` is Snowflake's semi-structured type for storing hierarchical
data such as JSON.

## 2. Convert JSON Text to VARIANT

``` sql
INSERT INTO json_demo
SELECT PARSE_JSON('{
  "customer": "Neelu",
  "orders": [
    {"id": 101, "amount": 250},
    {"id": 102, "amount": 450}
  ]
}');
```

`PARSE_JSON` parses a JSON-formatted string and returns a `VARIANT`
value.

## 3. Inspect the Stored JSON

``` sql
SELECT src
FROM json_demo;
```

At this stage, the complete nested JSON structure remains in the
`VARIANT` column.

## 4. Access JSON Object Fields

``` sql
SELECT
  src:customer::STRING AS customer,
  src:orders AS orders
FROM json_demo;
```

Snowflake supports path traversal using the colon operator.

For example:

``` text
src:customer
```

accesses the `customer` element.

The cast:

``` text
::STRING
```

converts the extracted value to a SQL string.

## 5. Flatten the Orders Array

The `orders` value is an array. To turn its elements into individual
rows:

``` sql
SELECT
  f.value:id::NUMBER AS order_id,
  f.value:amount::NUMBER AS amount
FROM json_demo,
LATERAL FLATTEN(INPUT => src:orders) f;
```

Conceptually, the JSON:

``` json
{
  "customer": "Neelu",
  "orders": [
    {"id": 101, "amount": 250},
    {"id": 102, "amount": 450}
  ]
}
```

becomes rows such as:

    ORDER_ID   AMOUNT
  ---------- --------
         101      250
         102      450

`FLATTEN` is a table function that explodes a `VARIANT`, `OBJECT`, or
`ARRAY` into multiple rows.

## 6. Understand the FLATTEN Output

`FLATTEN` can expose fields including:

-   `SEQ`: sequence associated with the input record
-   `KEY`: object key when applicable
-   `PATH`: path to the element
-   `INDEX`: array index when applicable
-   `VALUE`: flattened value
-   `THIS`: element being flattened

For nested arrays, `LATERAL FLATTEN` allows a subsequent flatten
operation to reference the result of the previous one.

## 🔍 Exercise Flow

Run the exercise in this order:

1.  Create `json_demo`.
2.  Insert JSON with `PARSE_JSON`.
3.  Select the original `VARIANT` value.
4.  Extract the customer.
5.  Inspect the orders array.
6.  Flatten the orders array.
7.  Cast extracted values to useful SQL types.

## 🧠 What You Should Notice

### VARIANT preserves the original structure

You can store nested JSON without immediately designing a large
relational schema.

### Path expressions let SQL navigate JSON

Examples:

``` sql
src:customer
src:orders
src:orders[0]
```

### FLATTEN bridges semi-structured and relational data

Arrays can be expanded into rows, making nested data easier to analyze
with SQL.

## ⚠️ Important Notes

JSON element names are case-sensitive when navigating semi-structured
data.

The result of a JSON path expression is a `VARIANT` value unless it is
explicitly cast.

`FLATTEN` is especially useful when an array needs to become one row per
element.

## 🧪 Validation Status

The SQL examples in this reference were checked against current
Snowflake SQL/documentation syntax for `PARSE_JSON`, `VARIANT` path
access, casting, and `LATERAL FLATTEN`.

They were **not executed against a live Snowflake account in this
chat**, so this should be treated as documentation-level syntax
validation rather than live execution validation.

Snowflake's documentation demonstrates the same `VARIANT` path traversal
and `LATERAL FLATTEN` patterns for querying nested JSON.

## 🔑 Key Takeaways

-   **VARIANT** is the main Snowflake type used here for JSON.
-   **PARSE_JSON** converts JSON text into a `VARIANT`.
-   JSON paths can be queried with the `:` operator.
-   `::STRING`, `::NUMBER`, and other casts turn extracted values into
    SQL types.
-   **FLATTEN** expands arrays and other compound values into rows.
-   Semi-structured data can be explored with SQL without flattening
    everything during ingestion.

## 🔗 Official Reference

Snowflake documentation: Querying Semi-structured Data

Snowflake documentation: FLATTEN function
