# 📊 Poll: Which Table Type Do You Use Most in Staging?

## 🎯 Poll Details

**Platform:** LinkedIn Poll
**Duration:** 1 week (recommended)
**Post #:** 20
**Phase:** 3 — Tables & Data Types

---

## 📋 Poll Options

| Option | Label | Description |
|--------|-------|-------------|
| A | **Permanent Tables** | Full Time Travel + Fail-safe. Maximum data protection for staging. |
| B | **Transient Tables** | No Fail-safe, Time Travel up to 1 day. Lower cost for replaceable data. |
| C | **Temporary Tables** | Session-scoped. Auto-dropped on disconnect. Zero persistence. |
| D | **External Tables** | Query files directly in S3/Azure/GCS. No data movement at all. |

---

## 🔷 Why This Poll Matters

This poll engages the audience on a real architectural decision every data engineer makes. The "right" answer depends on:

- **Pipeline design** — batch vs streaming vs ELT
- **Cost sensitivity** — Fail-safe storage can be expensive at scale
- **Recoverability requirements** — can you reload from source if staging is lost?
- **Latency tolerance** — external tables add query overhead

### Expected Response Distribution (Hypothesis)

| Option | Expected % | Reasoning |
|--------|-----------|-----------|
| Permanent | 20-30% | Default behavior; many teams don't change it |
| Transient | 40-50% | Most common best practice for staging |
| Temporary | 10-15% | Used by SP/task-driven ETL patterns |
| External | 10-15% | Growing with data lake/lakehouse adoption |

---

## 💬 Engagement Strategy

### Comment Prompt
> "Drop a comment with WHY you picked yours — curious about the reasoning behind your staging architecture."

### Follow-up Comment (Post After 24-48h)
> "Great responses so far! Here's what I'm seeing:
> - Teams with reloadable sources → Transient (save on Fail-safe costs)
> - Teams with complex staging logic → Permanent (protect the transformation work)
> - Session-based ETL → Temporary (clean auto-cleanup)
> - Data lake-first orgs → External (query in place, zero duplication)"

---

## 🔗 Connection to Series

| Reference | Connection |
|-----------|------------|
| **Post 19** (Table Types Overview) | Direct continuation — tests if audience absorbed the material |
| **Post 21** (Data Types Deep Dive) | Teased in "Next up" — keeps momentum |
| **Post 24** (External Tables) | Option D connects forward to the deep-dive |
| **Post 27** (Dynamic Tables) | Some may comment "Dynamic Tables" — acknowledge as valid 5th option |

---

## 📌 LinkedIn Poll Setup Instructions

1. Create a new post on LinkedIn
2. Click the "Poll" option (bar chart icon)
3. Enter the 4 options exactly as shown above (LinkedIn allows max 4)
4. Set duration to **1 week**
5. Paste the post text (from .txt file) above the poll
6. Publish

---

## 💡 Tips for Maximizing Engagement

- **Post timing:** Tuesday or Wednesday, 8-10 AM your audience's timezone
- **Reply to every comment** within the first 2 hours (algorithm boost)
- **Tag 2-3 connections** who you know have opinions on staging patterns
- **Share results** in a follow-up comment after 3-4 days with insights

---

This is Post 20 of my Snowflake LinkedIn Series — Phase 3: Tables & Data Types.

🔔 Follow along to master Snowflake, one concept at a time.

Next up → Snowflake Data Types Deep Dive: VARIANT, ARRAY & OBJECT 🧩

#Snowflake #DataEngineering #SQL #Poll #TableTypes #StagingLayer #SnowflakeLinkedInSeries
