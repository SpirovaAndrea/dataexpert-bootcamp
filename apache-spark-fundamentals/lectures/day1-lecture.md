# Day 1: Spark Overview

## What is Spark?

- Spark is a **distributed compute framework** that allows you to process very large amounts of data efficiently.  
- Evolution: Java MapReduce → Hive → Spark.

---

## Why Spark is Efficient

- Leverages **RAM** much more effectively than previous iterations.  
- Minimizes **disk writes**; only writes to disk when necessary (called **spilling to disk**).  
- Spark is **storage agnostic** – it can read from various sources (files, databases, lakes, APIs).  
- Goal: maximize RAM usage to avoid spilling.  

---

## When Spark May Not Be Ideal

- If you are the **only person on your team familiar with Spark**.  
- If your company already relies heavily on another system.  

---

## How Spark Works (Analogy: Basketball Team)

- **The Plan**: The program or logic (written in Python, Scala, or SQL).  
- **The Driver (Coach)**:  
  - Reads and coordinates the plan.  
  - Settings:
    - `spark.driver.memory` – memory available to the driver (default 2GB, can go up to 16GB).  
    - `spark.driver.memoryOverheadFactor` – extra memory for complex plans.  
  - Determines when jobs execute, how to join datasets, and level of parallelism.  
- **Executors (Players)**:
  - Do the actual work: get data, filter, transfer, compute.  
  - Important settings:
    - `spark.executor.memory` – memory per executor.  
    - `spark.executor.cores` – cores per executor (usually 4, max 6).  
    - `spark.executor.memoryOverheadFactor` – extra memory per executor.  

---

## Joins in Spark

- Types of joins:
  - **Shuffle sort-merge**
  - **Broadcast hash**
  - **Bucket join**  
- **Shuffle** is the least scalable part of Spark.  
- **Shuffle partitions** and **parallelism** are linked.  

---

## Bucketing

- **Definition**: Pre-partitioning data into a fixed number of “buckets” based on the hash of one or more columns.  
- Analogy: Like sorting mail into numbered mailboxes.  
- Helps with **performance** and managing **skew** in joins.  

---

## Shuffle & Skew

- Skew occurs when data is unevenly distributed across partitions.  
- Strategies to mitigate skew:
  - Salting keys
  - Repartitioning
  - Using broadcast joins when appropriate  

---

## How Spark Reads Data

- **Data lake**: Delta Lake, Apache Iceberg, Hive metastore  
- **RDBMS**: PostgreSQL, Oracle  
- **API**: Make REST calls and convert to DataFrame  
- **Flat files**: CSV, JSON  

---

## Spark on Databricks vs Regular Spark

- Consider using **notebooks** for interactive development.  
- Version control is essential for reproducibility.  
- Test jobs locally before production.  

---

## Spark Query Plans

- Understanding query plans is key for optimizing performance.  
- Check how stages are executed, where shuffles happen, and memory usage.  

---

## Output Datasets

- Should **always be partitioned on date** for efficiency in downstream processing.  
