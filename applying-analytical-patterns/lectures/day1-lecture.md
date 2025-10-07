# Apache Spark: Architecture, Optimization, and Best Practices Day 1 Lecture

Not all data engineering pipelines are built the same way, but there are a few common patterns you can learn.

Repeatable analysis is your best friend. By thinking in terms of higher-level abstractions, you can reduce cognitive load on SQL and streamline your impact.

## Common Patterns

### 1. Aggregation-based Patterns
- Used for trend analysis, root cause analysis, and general grouping.
- `GROUP BY` is your friend; think carefully about which combinations matter the most.
- Be cautious when analyzing many combinations or long timeframes—can be resource-intensive.

### 2. Cumulation-based Patterns
- Focus on relationships between today and yesterday.
- Full outer joins are your friend.
- Useful for:
  - State change tracking
  - Survival analysis
  - Growth accounting

### 3. Window-based Patterns
- Useful for day-over-day (DoD), week-over-week (WoW), month-over-month (MoM), year-over-year (YoY) analysis.
- Rolling sums, averages, and rankings are key.
- Implemented using SQL window functions:
  ```sql
  FUNCTION() OVER (PARTITION BY keys ORDER BY sort_rows BETWEEN n PRECEDING AND CURRENT ROW)
