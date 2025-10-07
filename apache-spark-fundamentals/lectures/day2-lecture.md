# Day 2: Spark Optimizations and Best Practices

## Spark Server vs Notebooks

- **Spark Server (e.g., Airbnb)**:
  - Runs jobs in production directly on the cluster.  
- **Spark Notebooks (e.g., Netflix)**:
  - Interactive development and exploration.  
  - Easier for experimentation, collaboration, and testing.

---

## Databricks Considerations

- Connect Databricks with **GitHub** for version control.  
- Any code in the notebook can run in production immediately.  
- Follow a **PR review process** for every change.  
- Use **CI/CD checks** to validate jobs before deployment.  

---

## Caching and Temporary Views

- **Temporary Views**:
  - Always get recomputed unless explicitly cached.  
- **Caching**:
  - Storage levels: `MEMORY_ONLY`, `DISK_ONLY`, etc.  
  - Only beneficial if the dataset fits in memory.  
  - In notebooks, call `.unpersist()` when done, or cached data will linger.  
- **Difference from Broadcast**:
  - Caching: Stores **precomputed, partitioned values** for reuse.  
  - Broadcast: Small datasets sent entirely to each executor to prevent shuffle.  

---

## Broadcast Join Optimization

- **Broadcast joins** prevent shuffle and improve performance.  
- Thresholds exist for automatic broadcasting.  
- Can explicitly wrap a dataset with `broadcast()` if needed.  

---

## UDFs (User Defined Functions)

- PySpark quirks vs Scala: Apache Arrow optimizations have improved PySpark UDF performance, bringing it closer to Scala.  
- Dataset API often removes the need for UDFs; you can use pure Scala functions instead.  

---

## DataFrame vs Dataset vs SparkSQL

- **DataFrame**: Suited for hardened pipelines, less prone to change.  
- **SparkSQL**: Best for collaborative pipelines with data scientists.  
- **Dataset**: Ideal for pipelines requiring **unit and integration tests**.  

---

## Parquet File Format

- Excellent compression using **run-length encoding**.  
- Avoid **global `.sort()`** – very slow.  
- Prefer `.sortWithinPartitions()` for efficiency.  

---

## Spark Tuning Tips

- **Executor Memory**: Don’t just set to max (e.g., 16GB); could waste resources.  
- **Driver Memory**: Adjust based on plan complexity.  
- **Shuffle Partitions**:
  - Default is 200.  
  - Aim for ~100MB per partition for properly sized output datasets.  
- **AQE (Adaptive Query Execution)**:
  - Helps with skewed datasets.  
  - Less useful if datasets are uniform.  
