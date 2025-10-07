# Apache Spark: Managing Spark Jobs and Notebooks Day 2 Lecture

## Funnel Analysis
- Focus on understanding user behavior across multiple steps or stages.
- Good funnel analysis helps track conversion rates and identify drop-offs.

## SQL in Data Engineering
The SQL you use in interviews may differ from SQL on the job. Key points:  
- Rewrite queries without relying solely on window functions.  
- Use **recursive common table expressions (CTEs)** when needed.  
- **Correlated subqueries** can be powerful but should be used carefully.  
- `COUNT(CASE WHEN …)` is a versatile tool for aggregations and conditional counting.  
- **Cumulative table design** minimizes table scans and improves performance.  
- Always aim to write **clean, readable SQL code**.

### Advanced SQL Techniques
- **Grouping sets, CUBE, ROLLUP** for multi-level aggregations.  
- **Self-joins** for comparing rows within the same table.  
- **Window functions**: `LAG`, `LEAD`, `ROWS BETWEEN …` for ranking and running totals.  
- **Cross joins** for combinatorial analysis.  
- **UNNEST / LATERAL VIEW / EXPLODE** to flatten nested data structures.

## Symptoms of Bad Data Modeling
- Slow dashboards or queries.  
- Queries with many nested CTEs.  
- Analytic queries with excessive `CASE WHEN` statements.  
- Poorly designed tables causing repeated scans or inefficient joins.

