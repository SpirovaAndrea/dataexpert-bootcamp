# Applying Analytical Patterns - Day 2: Recursive CTEs and Window Functions

## How to Do Good Funnel Analysis

Funnel analysis tracks users through a series of steps to understand where they drop off. Good funnel analysis requires clean data modeling and efficient SQL techniques.

## The DE SQL Interview vs SQL on the Job

There are some techniques that are more commonly tested in interviews versus what you'll actually use day-to-day.

**Interview focus:**
- Rewrite queries without window functions
- Write queries that leverage recursive common table expressions
- Use correlated subqueries in any capacity
- COUNT(CASE WHEN) is a very powerful combo for interviews and on the job

**On the job:**
Many of the interview techniques are less common in production code, but understanding them shows SQL depth.

## COUNT(CASE WHEN) Pattern

This is one of the most powerful and practical SQL patterns you'll use both in interviews and real work.

**Example:**
```sql
SELECT
  COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_count,
  COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_count,
  COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_count
FROM orders
```

This lets you create multiple aggregations in a single query without multiple scans of the table.

## Cumulative Table Design

Cumulative table design minimizes table scans.

Instead of scanning large historical tables repeatedly, you build up state incrementally. Each day you only process new data and merge it with yesterday's cumulated state. This is much more efficient than recalculating everything from scratch.

## Write Clean SQL Code

Clean SQL is maintainable SQL. Use:
- Clear aliases
- Consistent indentation
- Descriptive names
- Comments for complex logic
- CTEs to break down complex queries into logical steps

## Advanced SQL Techniques to Try

These are techniques that can make your queries more powerful:

**GROUPING SETS / GROUP BY CUBE / GROUP BY ROLLUP**
- Generate multiple grouping combinations in a single query
- CUBE generates all possible combinations
- ROLLUP generates hierarchical combinations
- GROUPING SETS lets you specify exactly which combinations you want

**Self Joins**
- Join a table to itself
- Useful for comparing rows within the same table
- Common for finding relationships between records

**Window Functions**
- LAG: Access previous row's value
- LEAD: Access next row's value
- ROWS: Define window frame (e.g., ROWS BETWEEN 3 PRECEDING AND CURRENT ROW)

**CROSS JOIN / UNNEST / LATERAL VIEW EXPLODE**
- CROSS JOIN: Cartesian product of two tables
- UNNEST: Expand arrays into rows (PostgreSQL)
- LATERAL VIEW EXPLODE: Expand arrays into rows (Hive/Spark)

## Recursive CTEs

Recursive common table expressions are powerful for hierarchical or iterative data processing.

A recursive CTE has two parts:
1. Base case: The starting point
2. Recursive case: References itself to build on the previous iteration

**Example use cases:**
- Organizational hierarchies (manager-employee relationships)
- Bill of materials (product components)
- Graph traversal
- Generating sequences

**Basic structure:**
```sql
WITH RECURSIVE cte_name AS (
  -- Base case
  SELECT ... 
  UNION ALL
  -- Recursive case
  SELECT ... FROM cte_name WHERE ...
)
SELECT * FROM cte_name
```

## Correlated Subqueries

A correlated subquery references columns from the outer query. It runs once for each row in the outer query.

**Example:**
```sql
SELECT 
  user_id,
  (SELECT COUNT(*) 
   FROM orders o 
   WHERE o.user_id = u.user_id) as order_count
FROM users u
```

While powerful, correlated subqueries can be slow on large datasets. Often you can rewrite them as joins or window functions for better performance.

## Symptoms of Bad Data Modeling

Watch out for these signs that your data model needs improvement:

**Slow dashboard queries with a weird number of CTEs**
- If you need 5+ CTEs to answer a simple question, your base tables might be poorly designed
- Consider whether your data model matches your query patterns

**Lots of CASE WHEN statements in analytic queries**
- Heavy use of CASE WHEN often means dimensions should be modeled differently
- Consider using proper dimension tables or enums instead

**General warning signs:**
- Queries that take minutes to run for simple aggregations
- Repeatedly joining the same tables in every query
- Complex logic to derive basic facts
- Constant need to clean or transform data in queries

These symptoms often indicate that you need to revisit your dimensional model, create better aggregation tables, or implement cumulative tables to pre-compute common patterns.