## ClickHouse Query Optimization Case Study e-Comerce (go to 70× faster)

A performance-focused SQL case demonstrating **progressive query optimization in ClickHouse** using real-world e-commerce–style data.

This project analyzes how different query structures (`JOIN`, `ON`, `IN`, `FINAL`, `DISTINCT`) affect execution speed, data consistency, and engine workload in `ReplacingMergeTree` tables.

---

### Database Schema

Two main tables emulate a simplified e-commerce dataset:

`products` — product catalog with last update date

`remainders` — stock, pricing, and product metrics by date

![diagram products-remainders][diagram]

```sql
CREATE TABLE products (
  product_id Int32,
  product_name String,
  brand_id Int32,
  seller_id Int32,
  updated Date
) ENGINE = ReplacingMergeTree
ORDER BY product_id;

CREATE TABLE remainders (
  date Date,
  product_id Int32,
  remainder Int32,
  price Int32,
  discount Int32,
  pics Int32,
  rating Int32,
  reviews Int32,
  new Bool
) ENGINE = ReplacingMergeTree
ORDER BY (date, product_id);
```

### Change steps

| Step | Change                          | Execution Time | Improvement Reason            |
| ---- | ------------------------------- | -------------- | ----------------------------- |
| 1    | `JOIN` + `WHERE`                | 14 sec         | Join before filtering    |
| 2    | Move filters into `ON`          | 9 sec          | Filtering before join         |
| 3    | Replace `JOIN` with `IN`        | 2 sec          | Semi-join, no materialization |
| 4    | Replace `FINAL` with `DISTINCT` | 0.2 sec        | Skips heavy deduplication     |

Each step progressively reduced processing overhead, moving from 14 s to 0.2 s — a **70× performance gain.**

**Key Findings**
- `USING` joins are slower than ON when filters are applied after joining.
- `IN` is faster than JOIN when only key existence is needed.
- `FINAL` is expensive — avoid it when data freshness is guaranteed by ReplacingMergeTree.
- `DISTINCT` can safely replace `FINAL` in read-only analytical queries.
- Filtering as early as possible drastically reduces scanned data volume.

### Project structure
| Path                            | Description                                  |
| ------------------------------- | -------------------------------------------- |
| `sql/01_schema.sql`             | Table definitions (`products`, `remainders`) |
| `sql/02_test_data.sql`          | Test dataset generation (consistent IDs)     |
| `sql/03_solution.sql`           | Optimized query implementations              |
| `sql/04_answers_explanation.md` | Step-by-step analysis and reasoning          |
| `img/diagram.png`               | Diagram image                                |
| `docker/docker-compose.yml`     | Local ClickHouse setup                       |
| `README.md`                     | Project overview and performance summary     |

### How to Run Locally
**1. Clone the repository**
```bash
git clone https://github.com/abazhutov/e-com-click.git
cd e-com-click
```
**2. Start ClickHouse**
```bash
docker build -t e-com-click-img -f "docker/dockerfile" .
docker run -d --name e-com-click-cnt --ulimit nofile=262144:262144 e-com-click-img
```
**3. Run optimized query**
```bash
docker exec -i e-com-click-cnt clickhouse-client < sql/03_solution.sql
```
**4. Get query stats**
```bash
docker exec -it e-com-click-cnt clickhouse-client --query="SELECT result_rows ||' row in set. Duration: '||(query_duration_ms/1000)||' sec' as duration FROM system.query_log order by transaction_id desc limit 1;"
```
### Result

**Final query execution time:** ~0.2 s

**Performance gain:** ~70× faster than baseline

[diagram]: img/diagram.png