from pyspark.sql import SparkSession
from pyspark.sql.types import ArrayType, FloatType
from pyspark.sql import functions as F

# Helper function to concatenate two arrays (used later as a UDF)
def concat_arrays(arr1, arr2):
    return (arr1 or []) + (arr2 or [])

# SQL query that aggregates daily site hits per user for a specific date (2023-01-03)
# and extracts useful date information for further transformations
query = """
WITH daily_aggregate AS
    (SELECT user_id,
            DATE(event_time) AS date,
            COUNT(1)         AS num_site_hits
     FROM events
     WHERE DATE(event_time) = DATE('2023-01-03')
       AND user_id IS NOT NULL
     GROUP BY user_id, DATE(event_time))
SELECT
    user_id,
    DATE_TRUNC('month', date) AS month_start,
    'site_hits' AS metric_name,
    num_site_hits AS num_hits,
    EXTRACT(DAY FROM date) AS day_of_month
FROM daily_aggregate;
"""

def do_daily_aggregate_transformation(spark, dataframe):
    # Register concat_arrays as a Spark UDF to use it with columns
    concat_arrays_udf = F.udf(concat_arrays, ArrayType(FloatType()))

    # Create a temporary SQL view to run SQL transformations on the input DataFrame
    dataframe.createOrReplaceTempView("daily_aggregate")
    
    # Execute the SQL query above to get the aggregated daily data
    aggregated_df = spark.sql(query)

    # Ensure month_start column has the correct date type
    aggregated_df = aggregated_df.withColumn("month_start", F.col("month_start").cast("date"))

    # Create a new column 'metric_array' which is an array representing the daily hits
    # Example: if day_of_month = 3 and num_hits = 5 -> [0.0, 0.0, 5.0]
    aggregated_df = aggregated_df.withColumn(
        "metric_array",
        concat_arrays_udf(
            F.array_repeat(F.lit(0.0), F.col("day_of_month") - 1),  # fill zeros up to the current day
            F.array(F.col("num_hits").cast(FloatType()))             # add today's hits at the end
        )
    )

    # Drop intermediate columns since they're no longer needed
    return aggregated_df.drop("num_hits", "day_of_month")


def main():
    # Initialize Spark session
    spark = SparkSession.builder \
        .master("local") \
        .appName("daily_aggregate") \
        .getOrCreate()

    # Read input table into a Spark DataFrame (assuming 'daily_aggregate' already exists in catalog)
    output_df = do_daily_aggregate_transformation(spark, spark.table("daily_aggregate"))

    # Write the transformed data back into the same table, overwriting old data
    output_df.write.mode("overwrite").insertInto("daily_aggregate")


# Optional: Uncomment to run as script
# if __name__ == "__main__":
#     main()



# --Summary
# 1. DATA AGGREGATION (SQL QUERY)
#    - Groups user events by user_id and date
#    - Filters data for a specific day (2023-01-03)
#    - Produces daily hit counts (num_site_hits)

# 2. ARRAY CONSTRUCTION (UDF)
#    - Builds an array representing daily activity across a month
#    - Example: for 3rd day with 5 hits → [0.0, 0.0, 5.0]
#    - Uses concat_arrays UDF with array_repeat() and array() functions

# 3. CLEAN DATA OUTPUT
#    - Converts month_start to DATE type
#    - Removes unnecessary columns (num_hits, day_of_month)
#    - Writes transformed data to Hive/Spark catalog table `daily_aggregate`

# WHY THIS MATTERS:
# - Shows how to combine SQL and PySpark transformations efficiently
# - Demonstrates use of UDFs and array operations for data structuring
# - Useful pattern for time-series data preparation in analytics pipelines

