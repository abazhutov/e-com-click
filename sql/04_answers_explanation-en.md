## Query Optimization Notes for e-Comerce Case (go to 70× faster)

This document explains the progressive optimization of a ClickHouse query for selecting products updated today and present in remainders for yesterday.  
The purpose is to show how each modification reduces query time by limiting scanned rows and improving the query execution plan.

---

## Original Query

*Execution time:* 14 sec  

```SQL
SELECT product_id 
FROM products FINAL 
JOIN remainders FINAL USING (product_id)
WHERE updated = today() 
  AND date = today() - 1;
```
**Explanation:**
- Both tables are fully joined on product_id.
- Only after the join, the WHERE filter is applied.
- As a result, ClickHouse must materialize all combinations before filtering — expensive for large datasets.
- FINAL forces deduplication during read, adding extra CPU cost.

## First Modification — `USING` → `ON`

*Execution time:* 14 sec → 9 sec

```SQL
SELECT p.product_id 
FROM products p FINAL 
JOIN remainders r FINAL 
  ON r.date = today() - 1
 AND p.product_id = r.product_id
 AND p.updated = today();
```

**Why faster:**
- Moving filter conditions (updated, date) into ON allows ClickHouse to filter before joining,
reducing the number of rows that participate in the join.
- The optimizer can skip irrelevant partitions earlier.

## Second modifocation `JOIN`->`IN` 
*Execution time:* 9 sec → 2 sec

```SQL
SELECT p.product_id
FROM products p FINAL
WHERE p.updated = today()
  AND p.product_id IN (
    SELECT r.product_id
    FROM remainders r FINAL
    WHERE r.date = today() - 1
  );
```
**Why faster:**
- IN performs a semi-join, checking only whether a matching key exists,
without building a full joined dataset.
- The subquery result is small and can be kept in memory.
- Less data shuffling, simpler execution plan.

## Third modifocation `FINAL`->`DISTINCT`

*Execution time:* 2 sec → 0.2 sec

```SQL
SELECT distinct p.product_id
FROM products p 
WHERE p.updated = today()
  AND p.product_id IN (
    SELECT r.product_id
    FROM remainders r
    WHERE r.date = today() - 1
  );
```

**Why much faster:**
- The dataset updates twice a day, and the table engine ReplacingMergeTree
already removes duplicates during background merges.
- Therefore, FINAL (on-the-fly deduplication) is unnecessary.
- Using DISTINCT only filters duplicates in the result set, which is computationally much cheaper.
