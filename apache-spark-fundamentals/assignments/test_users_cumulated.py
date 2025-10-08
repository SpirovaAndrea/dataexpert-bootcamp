# Import helper to compare Spark DataFrames in tests
from chispa.dataframe_comparer import *

# Import the transformation function to test
from ..jobs.users_cumulated_job import do_users_cumulated_transformation

# For test data and Spark operations
from collections import namedtuple
from pyspark.sql import functions as F

# Define namedtuple schemas for simplicity in test setup
UsersCumulated = namedtuple('Users_cumulated', "user_id dates_active date")
Users = namedtuple('Users', "user_id dates_active date")

def test_users_cumulated_generation(spark):
    # --- Step 1: Input setup ---
    # Create fake input data for an existing user who was active on Jan 30
    input_data = [
        Users("444502572952128450", ["2023-01-30"], "2023-01-30")
    ]

    # Convert mock data into a Spark DataFrame
    input_dataframe = spark.createDataFrame(input_data)

    # Create a fake `events` DataFrame representing new activity on Jan 31
    events_df = spark.createDataFrame([
        ("444502572952128450", "2023-01-31")
    ], schema=["user_id", "event_time"])

    # Register this DataFrame as a temporary SQL table (used inside the transformation)
    events_df.createOrReplaceTempView("events")

    # --- Step 2: Run transformation ---
    # Apply the transformation function (the job logic under test)
    actual_df = do_users_cumulated_transformation(spark, input_dataframe)

    # Show the results (useful for debugging test output)
    actual_df.show()

    # --- Step 3: Expected output definition ---
    # Expected behavior: add new activity date to existing list
    expected_output = [
        UsersCumulated(
            user_id="444502572952128450",
            dates_active=["2023-01-30", "2023-01-31"],
            date="2023-01-31"
        )
    ]

    # Convert expected output into a Spark DataFrame
    expected_df = spark.createDataFrame(expected_output)

    # Cast columns to correct data types
    expected_df = expected_df.withColumn("dates_active", F.col("dates_active").cast("array<date>")) \
                             .withColumn("date", F.col("date").cast("date"))

    # --- Step 4: Assertion ---
    # Compare actual and expected DataFrames
    # ignore_nullable=True makes the test robust to nullability differences
    assert_df_equality(actual_df, expected_df, ignore_nullable=True)


# -- Summary
# This unit test validates the cumulative user activity transformation
# implemented in `do_users_cumulated_transformation`.

# GOAL:
# Ensure that when a user has a new event, the job correctly appends the
# new activity date to their existing list of active dates.

# TEST LOGIC:
# 1. Create mock user data (already active on 2023-01-30).
# 2. Add a fake event for 2023-01-31.
# 3. Run the transformation to combine old + new activity.
# 4. Validate that the resulting DataFrame correctly lists both dates
#    and updates the latest date field.
# 5. Compare with expected output using Chispa's assert_df_equality.

# WHY IT MATTERS:
# - Confirms correct handling of array accumulation and date updates.
# - Prevents logic regressions when modifying user activity aggregation code.
