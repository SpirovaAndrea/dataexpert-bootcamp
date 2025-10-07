# Day 1: Dimensional Data Modeling and Complex Data Types

## Complex Data Types

Complex data types allow you to store structured data within columns.

**Array** - A list in a column. All elements must be the same type.

**Struct** - A table within a table. It's a list of keys and values that are all defined. The data types of the values can be specified.

**Map** - All values need to be the same type. Keys don't need to be determined upfront and you can have a huge number of keys.

## Dimensions

Dimensions are attributes of an entity, like a user's birthday or favorite food.

Some dimensions uniquely identify an entity, like a user's ID. Others are just attributes and aren't critical for identification.

**Slowly Changing Dimensions** - Attributes that change over time, like favorite food or phone type. These are time-dependent attributes.

**Fixed Dimensions** - Facts that have one value and don't change, like date of birth.

## Knowing Your Customer

Understanding who will use your data determines how you model it.

**Data Analysts and Scientists** - Need data that's easy to query without many complex data types.

**Data Engineers** - Can work with compact data that might be harder to query. Nested types are okay for them.

**ML Models** - Requirements depend on the model and how it's trained. Generally most models want the identifier and feature decimal columns. Some models can accept complex data types.

**Customers** - Charts and data should be very easy to interpret.

## Master Data

Master data is data that other engineers and teams in the company depend on. Many pipelines read from yours and produce other datasets based on it.

## Three Types of Dimensional Data Modeling

These exist on a continuum:

**OLTP (Online Transaction Processing)** - Low-volume queries. This is how software engineers model data to make online systems run as quickly as possible. Uses minimized data duplication, primary keys, and constraints. Common databases are MySQL and PostgreSQL.

**OLAP (Online Analytical Processing)** - Large volume GROUP BY queries that minimize JOINs for fast querying.

**Master Data** - Focuses on completeness of entity definitions.

The continuum looks like this:
Production Database Snapshots → Master Data → OLAP Cubes → Metrics

## Cumulative Table Design

This design involves holding on to all the dimensions that ever existed.

**Core components:**
- Today's data table and yesterday's data table
- FULL OUTER JOIN the two data frames together
- COALESCE values to keep everything around
- Holding on to all of history

The cumulated output of today becomes yesterday's input for the next run.

**Benefits:**
- Historical analysis without shuffle. The last 30 days of data is in one row as an array, so there's no need for GROUP BY, just a SELECT.
- Easy transition analysis. You can track states like "active today, not active yesterday" for user transitions.

**Drawback:**
- Can only be backfilled sequentially, each day after the other. It relies on yesterday's data.

## Compactness vs Usability Tradeoff

**Most usable tables** - Have no complex data types and can easily be manipulated with WHERE and GROUP BY. This is the OLAP cube layer that analysts love to work with.

**Most compact tables** - Compressed to be as small as possible but can't be queried until they're decoded. These aren't human readable and are used in online systems.

**Middle-ground tables** - Use complex data types like ARRAY, MAP, and STRUCT. They're trickier to query but more compact. This is typical for the master data layer.

## Temporal Cardinality Explosions

This happens when you have a dimension that has a time component to it. For example, if you have a listing with a calendar that is its own dimension, joins can cause problems. Shuffling during these joins can mess things up.

**Run-length encoding compression** is one of the most important compression techniques in big data. When you have duplicates of the same value in a column, they can be compressed together as one value. For example, if you have a value repeated 200 times, all the duplicates can be removed from the dataset.

## Key Terms and Concepts

**Downstream table** - A table that comes later in your data pipeline or sits at a higher level in your dimensional model hierarchy. Think of data flowing like a river - upstream is where data originates, downstream is where it ends up after processing.

Examples:
- Upstream: Raw source tables, staging tables
- Downstream: Fact tables, aggregated tables, final reporting tables

**Shuffling** - Happens when data needs to be redistributed across different nodes or partitions during a join operation. This occurs when tables are partitioned differently, join keys don't align with partition keys, or data needs to move between nodes to complete the join.

Compression works best when similar data is stored together. When you shuffle data, related records get scattered across different storage locations. Compression algorithms can't find patterns as easily, storage becomes less efficient, and query performance degrades.

**Temporal Problem Context** - In dimensional modeling, this often happens with Slowly Changing Dimensions. For example, if you have a customer dimension that changes over time and you join historical fact data with the current version of the customer dimension, you might lose historical context and cause performance issues.

## SQL Functions

**COALESCE** - Returns the first non-NULL value from a list of arguments.

Why use it:
- Replace NULL values with a default
- Choose from multiple possible values (like fallback logic)
- Clean up data for reports or frontends

**UNNEST** - A PostgreSQL function that takes an array and returns each element as a row. Think of it as taking an array and exploding it vertically so you can work with each item individually.