# 🧊 Snowflake Poll — Day 8

## You loaded a file. Then you modified it. Then you tried to load it again. What happens? 🤔

Here's the EXACT scenario:

- **Step 1:** You upload `sales_data.csv` (100 rows) to `@my_stage`
- **Step 2:** You run `COPY INTO my_table FROM @my_stage/sales_data.csv` → ✅ 100 rows loaded
- **Step 3:** You modify `sales_data.csv` (add 50 new rows, now 150 rows) and re-upload to `@my_stage`
- **Step 4:** You run the EXACT same `COPY INTO` command again

**What happens at Step 4?**

---

## 🗳️ POLL:

- **A)** Loads all 150, duplicates too
- **B)** Loads only the 50 new rows
- **C)** Loads 0 rows — skips it
- **D)** Loads 150, no duplicates

---

## 💡 The Answer:

**D — It loads all 150 rows!** 🎯

Wait... doesn't Snowflake skip already loaded files?

**YES** — but only if the file is IDENTICAL. When you modified the file:
- → The file SIZE changed (100 rows → 150 rows)
- → The ETag/checksum changed

Snowflake sees this as a **COMPLETELY NEW file**. It loads all 150 rows.

### ⚠️ But here's the catch — you now have DUPLICATES:
- → The original 100 rows from Step 2 are still in the table
- → Plus all 150 rows from Step 4
- → **Total: 250 rows (with 100 rows duplicated!)**

COPY INTO does **NOT** do upserts or deduplication on the data itself. It only deduplicates at the **FILE level**.

---

## 🧠 Now the REAL tricky part:

What if you modify the file but the file size stays the same?
(e.g., you change "John" to "Jane" — same number of bytes)

- → Snowflake checks the ETag/content hash
- → If the hash changed → it loads the file again
- → If by some miracle the hash is identical → it skips

---

## ⚙️ The 3 things Snowflake checks before loading:

| Check | Description |
|-------|-------------|
| ✅ File name | Same name? |
| ✅ File size | Same size? |
| ✅ ETag / content hash | Same content? |

**ALL THREE must match** a previous load → **SKIP**
**ANY ONE differs** → Snowflake treats it as a new file and **LOADS it**

---

## 🔑 What about these override options?

### 1️⃣ FORCE = TRUE
→ Ignores ALL load history — reloads everything
→ Even identical, unchanged files get reloaded

### 2️⃣ LOAD_UNCERTAIN_FILES = TRUE
→ Loads files where Snowflake isn't sure if they changed
→ Useful when metadata tracking is inconclusive

---

## ⚠️ The Gotcha Matrix:

| Scenario | Result |
|----------|--------|
| TRUNCATE the table, then COPY INTO same file | 0 rows loaded! Load history survives TRUNCATE |
| DROP and CREATE the table, then COPY INTO same file | All rows loaded! Load history is gone |
| Same file, 64+ days later | All rows loaded! Load history expires after 64 days |
| Rename the file (`sales_data.csv` → `sales_data_v2.csv`) | All rows loaded! Different name = new file |

---

## 🎯 Pro Tip for Production Pipelines:

If you're updating files and reloading:
- → Use a **MERGE** pattern instead of raw COPY INTO to avoid duplicates
- → Or load into a staging table first, then MERGE into your target
- → Or use **Snowpipe + Streams** for CDC-style continuous ingestion

**Never rely on COPY INTO alone when source files can be modified!**

---

*This is Post 8 of my Snowflake LinkedIn Series — mastering one concept at a time.*

🔔 Follow for daily Snowflake knowledge drops!

**Next up → Post 9: Hands-on Exercise — Explore Snowflake Architecture**

---

`#Snowflake #DataEngineering #COPYINTO #DataLoading #ETL #DataPipeline #SQL #SnowflakeLinkedInSeries`
