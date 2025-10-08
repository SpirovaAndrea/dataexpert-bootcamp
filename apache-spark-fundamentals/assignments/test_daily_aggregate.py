# Import helper library for comparing Spark DataFrames in tests
from chispa.dataframe_comparer import *

# Import Spark data types for defining schemas
from pyspark.sql.types import ArrayType, FloatType, StringType, StructField, StructType, DateType

# Import equality assertion for DataFrame comparison
from chispa.dataframe_comparer import assert_df_equality

# Import the transformation function to test (from previous job file)
from ..jobs.daily_aggregate_job import do_daily_aggregate_transformation

# Utilities for handling dates and test data structures
from datetime import datetime
from collections import namedtuple

# Define namedtuple schemas for easy test data creation
EventsAgg = namedtuple('EventsAgg', "user_id month_start metric_name metric_array")
Events = namedtuple('Events', "user_id month_start metric_name metric_array")

def test_daily_aggregate_generation(spark):
    # Create mock input data — represents an already existing row in the target table
    input_data = [
        Events("444502572952128450", "2023-01-03", "site_hits", [1.0])
    ]

    # Convert mock data into Spark DataFrame
    input_dataframe = spark.createDataFrame(input_data)

    # Create fake source events data (the input table for SQL query inside transformation)
    events_df = spark.createDataFrame([
        ("444502572952128450", "2023-01-03")
    ], schema=["user_id", "event_time"])

    # Register the DataFrame as a temporary SQL table so SparkSQL can query it
    events_df.createOrReplaceTempView("events")

    # Run the transformation job on input data
    actual_df = do_daily_aggregate_transformation(spark, input_dataframe)

    # Display the output DataFrame (useful for debugging)
    actual_df.show()

    # Define expected output for this test case
    expected_output = [
        EventsAgg(
            user_id="444502572952128450",
            # The first day of the month corresponding to '2023-01-03'
            month_start=datetime.strptime("2023-01-01", "%Y-%m-%d").date(),
            metric_name="site_hits",
            # Expected array: two zeros (for 1st and 2nd), then 1.0 for the 3rd day
            metric_array=[0.0, 0.0, 1.0]
        )
    ]

    # Define schema for expected DataFrame manually
    expected_df = spark.createDataFrame(expected_output, schema=StructType([
        StructField('user_id', StringType(), True),
        StructField('month_start', DateType(), True),
        StructField('metric_name', StringType(), False),
        StructField('metric_array', ArrayType(FloatType(), True), True)
    ]))

    # Compare actual vs expected DataFrames
    # ignore_nullable=True means nullable field differences will be ignored
    assert_df_equality(actual_df, expected_df, ignore_nullable=True)

# --Summary
# This PySpark unit test verifies that the `do_daily_aggregate_transformation` function
# produces the correct aggregated output for user activity data.

# 1. TEST DATA SETUP
#    - Uses mock input data with one user and one event
#    - Registers fake "events" table for SQL transformations

# 2. TRANSFORMATION EXECUTION
#    - Calls the transformation function being tested
#    - Creates expected output with proper date and metric array

# 3. VALIDATION
#    - Compares the actual Spark DataFrame with the expected one
#    - Uses `assert_df_equality` from Chispa for clean DataFrame testing
#    - Displays the output for debugging via `.show()`

# WHY THIS MATTERS:
# - Ensures Spark jobs behave deterministically for given input
# - Enables CI/CD pipelines to catch logic regressions early
# - Demonstrates effective use of Chispa for PySpark testing

