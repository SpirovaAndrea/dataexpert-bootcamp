from pyspark.sql import SparkSession

# SQL query defining the cumulative transformation logic
query = """
WITH yesterday AS (
    SELECT
        user_id,
        -- If user already has an array of active dates, cast it to ARRAY<DATE>
        -- Otherwise initialize an empty array
        CASE 
            WHEN dates_active IS NOT NULL THEN CAST(dates_active AS ARRAY<DATE>)
            ELSE ARRAY() 
        END AS dates_active,
        date
    FROM users_cumulated
    WHERE date = DATE('2023-01-30')  -- Previous snapshot (yesterday)
),
today AS (
    SELECT
        -- Cast user_id to string and extract date portion from timestamp
        CAST(user_id AS STRING) AS user_id,
        DATE(CAST(event_time AS TIMESTAMP)) AS date_active
    FROM events
    WHERE
        DATE(CAST(event_time AS TIMESTAMP)) = DATE('2023-01-31')  -- Today's snapshot
        AND user_id IS NOT NULL
)
SELECT
    -- Merge users from both tables
    COALESCE(t.user_id, y.user_id) AS user_id,
    CASE
        -- If user was not present yesterday, initialize new array with today's date
        WHEN ISNULL(y.dates_active) THEN ARRAY(CAST(t.date_active AS DATE))  
        -- If user is not active today, just keep yesterday's array
        WHEN ISNULL(t.date_active) THEN y.dates_active 
        -- Otherwise merge both date arrays (accumulate unique active days)
        ELSE ARRAY_UNION(y.dates_active, ARRAY(CAST(t.date_active AS DATE)))   
    END AS dates_active,
    -- Determine which date to assign: today's date or incremented yesterday
    COALESCE(t.date_active, DATE_ADD(y.date, 1)) AS date
FROM today t
    FULL OUTER JOIN yesterday y
    ON t.user_id = y.user_id;
"""

# --- Transformation function ---
def do_users_cumulated_transformation(spark, dataframe):
    # Register input DataFrame as a temporary view for SQL access
    dataframe.createOrReplaceTempView("users_cumulated")
    
    # Execute the cumulative user aggregation query
    return spark.sql(query)


# --- Entry point for standalone execution ---
def main():
    spark = SparkSession.builder \
        .master("local") \
        .appName("users_cumulated") \
        .getOrCreate()
    
    # Run the transformation using the current users_cumulated table
    output_df = do_users_cumulated_transformation(spark, spark.table("users_cumulated"))
    
    # Write results back to the same table (overwrite mode)
    output_df.write.mode("overwrite").insertInto("users_cumulated")


# -- Summary
# This PySpark job implements a cumulative user activity pipeline
# that tracks all unique days a user was active.

# 1. INPUTS
#    - `users_cumulated`: snapshot of user activity up to yesterday
#    - `events`: today’s user activity events

# 2. TRANSFORMATION LOGIC
#    - Read both "yesterday" and "today" data using SQL CTEs
#    - Merge users by user_id with FULL OUTER JOIN
#    - Use ARRAY_UNION to append today’s active date to the existing array
#    - Handle three cases:
#        * New user today → create a new array with today’s date
#        * Returning user → append today’s date to array
#        * Inactive user → retain existing array

# 3. OUTPUT
#    - Produces an updated `users_cumulated` dataset with:
#        * user_id
#        * dates_active (ARRAY<DATE>)
#        * date (latest snapshot date)

# WHY IT MATTERS:
# - This cumulative design enables tracking of user engagement over time.
# - Uses idempotent logic suitable for daily incremental ETL updates.
# - Demonstrates best practice in combining SQL + PySpark for daily rollups.

