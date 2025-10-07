# Day 2: Data Pipelines, Idempotency, and Slowly Changing Dimensions

## What is a Data Pipeline?

A data pipeline is a set of processes that moves data from one system to another, while possibly transforming, cleaning, or enriching it along the way.

For example, if you're building a pipeline to track app user activity, it might look like this:

**Ingest** - Collect logs from mobile apps
**Stream** - Send events via Kafka in real-time
**Process** - Clean and transform data using Apache Spark
**Store** - Save it to a data warehouse like Snowflake or PostgreSQL
**Analyze** - Query it via BI tools like Tableau or Metabase

This whole process from raw logs to dashboards is your data pipeline.

## Backfilling

Backfilling means filling in missing historical data that wasn't captured, processed, or stored properly at the time it originally occurred.

For example, suppose your data pipeline for user signups started running on January 1st, but you have signup data from December in another system. You would backfill the pipeline by loading that December data into your target database so you have a complete timeline.

## Slowly Changing Dimensions

Slowly changing dimensions are attributes that drift over time, like favorite food. These are dimensions that change over time and we need to track the changes.

Other dimensions like your birthday don't change. These are fixed dimensions.

We need to model slowly changing dimensions the right way or they impact idempotency - the ability for your data pipelines to produce the same results whether running in production or during backfill. This is an important property for enforcing data quality.

## Idempotency

Idempotent means "denoting an element of a set which is unchanged in value when multiplied or otherwise operated on by itself."

For data pipelines, this means they should produce the same results regardless of:
- The day you run it
- How many times you run it
- The hour that you run it

If you have all of your inputs available and all of your signals ready to go, it shouldn't matter if you run the pipeline today or in a year.

If you have a pipeline that isn't idempotent, you can run it today, wait a week, and backfill it and you'll get different data and results even if you don't change the code. It produces data that is non-reproducible. This shows up when a data analyst looks at the data and things don't add up, don't match, or look weird.

If you have downstream engineers depending on your pipeline and your pipeline is not idempotent, theirs will also be non-idempotent. It follows the transitive property. This can cause data discrepancy issues.

Troubleshooting non-idempotent pipelines is hard.

## What Can Make a Pipeline Not Idempotent

**INSERT INTO without TRUNCATE** - If you're running the data for a day and you run it once, then run it twice, there's twice as much data. If you don't have truncate that clears out data before you insert, you will just keep duplicating the data over and over again. It's not idempotent because it doesn't produce the same data no matter how many times it's run.

Instead of INSERT INTO, use MERGE or INSERT OVERWRITE.

**MERGE** takes your new data and merges it into the existing data, but if you run it again you don't get duplicates. It notices that everything matches and nothing happens. The second time you run the pipeline it gives the same dataset.

**INSERT OVERWRITE** instead of matching all the records, you just overwrite that partition. Whatever data was in there, you overwrite it with the new data.

**Using start_date > without corresponding end_date <** - If we're using a WHERE clause where day is greater than yesterday, and we run it today we get one day of data. If we run it tomorrow, we get two days of data. That's a problem because your pipeline is not producing the same results regardless of when it is run. We need a window or chunk of days that are set.

**Not using a full set of partition sensors** - Your pipeline is going to run and maybe it's going to run with an incomplete set of inputs, where you're not checking for the full set of all the inputs that you need. It runs too early before all the inputs are ready and causes a problem. When you backfill it, the data is there, but in production it fires too early and it's missing one of the input datasets. You don't get the same results in both situations.

**Depends on past** - In Airflow, this is for sequential processing. If you have a cumulative pipeline that depends on yesterday's data, the pipeline can't run in parallel. It has to run yesterday, then today, then tomorrow.

Most pipelines are not like that. If you don't put sequential processing in cumulative pipelines, one of the things that can happen is you end up reading yesterday's data and it hasn't been created yet. Since you're processing things in parallel, you're going to start over on your cumulation and only have today's data.

**Relying on the latest partition of a not properly modeled Slowly Changing Dimension table** - You can only rely on this if you are backfilling an SCD table itself.

## Consequences of Non-Idempotent Pipelines

The production behavior and the backfill behavior of the pipeline are different. This is what you want to avoid. The beauty of idempotent pipelines is that they behave the same way.

Non-idempotent pipelines are:
- Very hard to troubleshoot bugs
- Unit testing cannot replicate the production behavior
- Can cause silent failures

## Rapidly vs Slowly Changing Dimensions

**Rapidly Changing Dimensions** - Things like heart rate that change very frequently.

**Slowly Changing Dimensions** - Things that change over time like age, phone type, or country.

If we model something as a slowly changing dimension, the slower it changes, the better.

SCDs are inherently non-idempotent.

One way to avoid using SCD is to not use the latest snapshot, but to use a daily snapshot instead.

SCD is a way of collapsing those daily snapshots based on whether or not the data changed day by day. For example, instead of having 365 rows where it says I'm 18 years old, we have one row that says I'm 18 from January 30th of one year to January 30th of another. This is where compression happens.

## How to Model Dimensions That Change

There are three ways:

**Singular snapshots** - If you backfill the data and only have the latest value, all the dimensional values of your old data will pull in that latest value, which might not be correct for the older data. You might need the old version of that dimension, not the new one. Never do this! Don't backfill with only the latest snapshot of dimensions.

**Daily partitioned snapshots** - A powerful way. Every day you have a value for your dimension and you just use that data.

**SCD Types 1, 2, 3** - Different approaches to tracking changes.

## SCD Types

**SCD Type 0** - These aren't actually slowly changing. They're fixed in stone, like birth date. The table just has the identifier of the entity and the dimension value. There's no temporal component because the value never changes.

**SCD Type 1** - The value changes but we only care about the latest value. Don't use this! For OLTP data modeling and online apps, using the latest value is fine because you never really need to look at the past. But data analytics teams who care about past values should not do this because it makes your pipeline non-idempotent.

**SCD Type 2** - The gold standard of SCD. Instead of modeling your data as just the latest value, you have a start date and an end date. For example, favorite food from 2001 to 2003. You don't lose clarity in the dimension. They are idempotent because you can go back in the past and say, for example, 2002 is between 2001 and 2003, which means it's this dimensional value. The start date is whenever it changed and the end date is far in the future. You have to filter on that start date and end date and pick a value depending on what date you have in mind.

**SCD Type 3** - Instead of holding on to all of history with a start date and end date, you hold on to two values: the original and the current value. If your dimension changes more than once, you're done. This usually doesn't store when the dimensions change. It fails the idempotent test because if something changes more than once you lose that history, and backfilling produces incorrect results.

## SCD Type 2 Loading

There are two ways to load these tables:

**One giant query** - Crunches the whole data and processes all of history at once.

**Cumulative way** - You have the data from the previous date and you bring in new data from the current date, and you only process one new day at a time.

You want to have your production run be the latter where you do it incrementally, so you don't have to process all of history all the time.