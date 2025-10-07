# Day 3: Reduced Fact Data Modeling & Shuffle Minimization

## Why Shuffle Should Be Minimized

- **Shuffle is the bottleneck of parallelism.**  
- **Parallelism**: Executing multiple tasks simultaneously instead of sequentially. Breaking work into pieces that can run at the same time dramatically improves performance and efficiency.
- **Pipeline Parallelism**: Breaking a process into stages where different stages run simultaneously on different data.

---

## Parallelizable Queries

### Highly parallelizable
- `SELECT ... FROM ... WHERE ...`

### Moderately parallel
- `GROUP BY`
- `JOIN`
- `HAVING`

### Painfully non-parallel
- `ORDER BY`

---

## Making `GROUP BY` More Efficient

- Give `GROUP BY` some buckets and guarantees.  
- Reduce data volume as much as possible before aggregation.  

---

## How Reduced Fact Data Modeling Gives You “Superpowers”

### Raw fact data
- Schema: `user_id`, `event_time`, …  
- Very high volume: 1 row per event  

### Daily aggregate
- Schema: `user_id`, `action_cnt`, `date_partition`  
- Medium volume: 1 row per user per day  

### Reduced fact
- Schema: `user_id`, `action_cnt` (as Array), `month_start_partition`  
- Low volume: 1 row per user per month/year  
- Daily dates are stored as an **offset** of `month_start` or `year_start`  
  - First index: `month_start + 0 days`  
  - Last index: `month_start + array_length - 1`  

---

## Dimensional Joins & Performance

- Dimensional joins get tricky if you want things to stay performant.  
- SCD (Slowly Changing Dimension) accuracy becomes limited to `month_start` or `year_start`.  
- You trade **100% SCD tracking accuracy** for **massively increased performance**.  
- Pick snapshots in time (month start, month end, or both) and treat dimensions as fixed.  

---

## Impact of Reduced Fact Data Modeling

- Multi-year analysis went from **weeks → hours**.  
- Enabled **decades-long slow burn analysis** at Facebook.  
- Allowed fast correlation analysis between user-level metrics and dimensions.  

---

## Lecturer Anecdote

- The lecturer shared a real-world story:  
  - Built a framework for **50 core metrics and 15 core dimensions**.  
  - Enabled **10+ year analysis** to happen in hours instead of weeks.  
  - Despite the impact, they were told this wasn’t considered “senior engineer caliber.”
