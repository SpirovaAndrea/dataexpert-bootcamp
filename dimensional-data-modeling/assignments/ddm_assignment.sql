-- Dimensional Data Modeling - Week 1
--This week's assignment involves working with the actor_films dataset.
--Your task is to construct a series of SQL queries and table definitions that will allow us to model the actor_films dataset in a way that facilitates efficient analysis. This involves creating new tables, 
--defining data types, and writing queries to populate these tables with data from the actor_films dataset
--The primary key for this dataset is (actor_id, film_id).

-- 1. Assignment: DDL for actors table:  Create a DDL for an actors table
-- Create a custom type to represent a single film
-- This struct will be stored in an array, allowing multiple films per actor
CREATE TYPE films_type AS (
    year INTEGER,           -- year the film was released
    filmid TEXT,           -- unique identifier for the film
    film TEXT,             -- name of the film
    votes INTEGER,         -- number of votes the film received
    rating REAL            -- film rating (decimal value)
);

-- Create an enum type for actor quality classification
-- Enums enforce data quality by limiting values to a predefined list
CREATE TYPE quality_class AS ENUM('bad', 'average', 'good', 'star');

-- Create the main actors table
-- This is a cumulative table that holds all historical film data for each actor
CREATE TABLE actors (
    actor TEXT,                      -- actor's name
    actorid TEXT,                    -- unique identifier for the actor
    films films_type[],              -- array of all films (cumulative history)
    quality_class quality_class,     -- current quality classification based on recent performance
    is_active BOOLEAN,               -- whether the actor made films this year
    current_year INTEGER,            -- the year this record represents
    PRIMARY KEY (actorid, current_year)  -- composite key: unique per actor per year
);


-- 2. Assignment: Cumulative table generation query: Write a query that populates the actors table one year at a time.
-- Populate the actors table incrementally, one year at a time
-- This follows the cumulative table design pattern using FULL OUTER JOIN
-- Each run processes one new year and merges it with yesterday's cumulated state
INSERT INTO actors
WITH yesterday AS (
    -- get the previous year's cumulated data (2020 in this example)
    -- this contains all historical film data up to and including 2020
    SELECT * FROM actors WHERE current_year = 2020
),
today AS (
    -- get only this year's new films (2021 in this example)
    -- aggregate all films for each actor in this year
    SELECT
        actor,
        actorid,
        year,
        -- use ARRAY_AGG to collect all this year's films into an array
        -- ROW() creates a struct matching our films_type definition
        ARRAY_AGG(ROW(year, filmid, film, votes, rating)::films_type) as films_this_year,
        -- calculate average rating for this year (used for quality_class)
        AVG(rating) as avg_rating
    FROM actor_films
    WHERE year = 2021
    GROUP BY actor, actorid, year
)
SELECT
    -- COALESCE ensures we keep the actor even if they only exist in one dataset
    COALESCE(t.actor, y.actor) AS actor,
    COALESCE(t.actorid, y.actorid) AS actorid,
    
    -- films array logic: accumulate historical films
    CASE 
        WHEN y.films IS NULL THEN t.films_this_year  -- new actor, only this year's films
        WHEN t.year IS NOT NULL THEN y.films || t.films_this_year  -- append this year to history
        ELSE y.films  -- actor inactive this year, keep historical films
    END as films,

    -- quality class: based on this year's average rating (if active)
    -- if not active, carry forward last year's quality class
    CASE
        WHEN t.year IS NOT NULL THEN
            CASE
                WHEN t.avg_rating > 8 THEN 'star'     -- excellent performance
                WHEN t.avg_rating > 7 THEN 'good'     -- good performance
                WHEN t.avg_rating > 6 THEN 'average'  -- average performance
                ELSE 'bad'                             -- poor performance
            END::quality_class
        ELSE y.quality_class  -- not active, maintain previous classification
    END as quality_class,

    -- os active: TRUE if actor has films this year, FALSE otherwise
    CASE
        WHEN t.year IS NOT NULL THEN TRUE
        ELSE FALSE
    END as is_active,

    -- current year: use this year if active, otherwise increment last year
    COALESCE(t.year, y.current_year + 1) as current_year

FROM today t
FULL OUTER JOIN yesterday y
    ON t.actorid = y.actorid;  -- Mmtch actors across years

-- 3. Assignment: DDL for actors_history_scd table: Create a DDL for an actors_history_scd table 
-- Create a Slowly Changing Dimension (Type 2) table
-- This tracks when actor quality_class and is_active status change over time
-- SCD Type 2 uses start_date and end_date to maintain full history
CREATE TABLE actors_history_scd (
    actor TEXT,                      -- actor's name
    actorid TEXT,                    -- unique identifier for the actor
    quality_class quality_class,     -- quality classification during this period
    is_active BOOLEAN,               -- activity status during this period
    start_date INTEGER,              -- year this state began
    end_date INTEGER,                -- year this state ended
    current_year INTEGER,            -- year when this record was created/updated
    PRIMARY KEY (actorid, start_date)  -- unique per actor per state change
);

-- 4. Assignment: Backfill query for actors_history_scd: Write a "backfill" query that can populate the entire actors_history_scd table in a single query.
-- Populate the entire SCD table in one query (for historical data)
-- This processes all years at once to identify state changes and create periods
WITH with_previous AS (
    -- Step 1: Get each year's data with the previous year's values
    -- LAG function looks back one row (previous year) for the same actor
    SELECT
        actor,
        actorid,
        current_year,
        quality_class,
        is_active,
        -- get previous year's quality_class for comparison
        LAG(quality_class, 1)
            OVER (PARTITION BY actorid ORDER BY current_year) as previous_quality_class,
        -- get previous year's is_active status for comparison
        LAG(is_active, 1)
            OVER (PARTITION BY actorid ORDER BY current_year) AS previous_is_active
    FROM actors
    WHERE current_year <= 2021
),
with_indicators AS (
    -- Step 2: Mark rows where a change occurred
    -- change_indicator = 1 means either quality_class or is_active changed
    SELECT *,
        CASE
            WHEN quality_class <> previous_quality_class THEN 1
            WHEN is_active <> previous_is_active THEN 1
            ELSE 0  -- no change
        END AS change_indicator
    FROM with_previous
),
with_streaks AS (
    -- Step 3: Create streak identifiers for consecutive years with same values
    -- SUM() OVER with ORDER BY creates cumulative sum of change indicators
    -- This groups consecutive years with same quality_class and is_active
    SELECT *,
        SUM(change_indicator)
            OVER(PARTITION BY actorid ORDER BY current_year) AS streak_identifier
    FROM with_indicators
)
-- Step 4: Collapse streaks into single records with start_date and end_date
SELECT
    actor,
    actorid,
    quality_class,
    is_active,
    MIN(current_year) AS start_date,  -- first year of this state
    MAX(current_year) AS end_date,    -- last year of this state
    2021 AS current_year              -- record created in 2021
FROM with_streaks
GROUP BY actor, actorid, streak_identifier, quality_class, is_active
ORDER BY actor, streak_identifier;


-- 5. Assignment: Incremental query for actors_history_scd: Write an "incremental" query that combines the previous year's SCD data with new incoming data from the actors table.
-- Update SCD table incrementally with new year's data
-- This is more efficient than backfilling - only processes the new year
-- Handles three scenarios: unchanged, changed, and new actors

-- create a type to hold SCD records (used for UNNEST later)
CREATE TYPE scd_type AS (
    quality_class quality_class,
    is_active BOOLEAN,
    start_date INTEGER,
    end_date INTEGER
);

INSERT INTO actors_history_scd
WITH last_year_scd AS (
    -- get records from last year that are still "open" (end_date = 2021)
    -- these are the records we might need to extend or close
    SELECT * FROM actors_history_scd
    WHERE current_year = 2021
    AND end_date = 2021
),
historical_scd AS (
    -- get all historical records that have already closed (end_date < 2021)
    -- these don't change and will be carried forward as-is
    SELECT
        actor,
        actorid,
        quality_class,
        is_active,
        start_date,
        end_date
    FROM actors_history_scd
    WHERE current_year = 2021
    AND end_date < 2021
),
this_year_data AS (
    -- get the new incoming data for 2022
    SELECT * FROM actors
    WHERE current_year = 2022
),
unchanged_records AS (
    -- scenario 1: Actor's quality_class AND is_active haven't changed
    -- extend the existing record's end_date to include this year
    SELECT
        ts.actor,
        ts.actorid,
        ts.quality_class,
        ts.is_active,
        ls.start_date,              -- keep original start_date
        ts.current_year AS end_date -- extend end_date to this year
    FROM this_year_data ts
    JOIN last_year_scd ls
        ON ls.actorid = ts.actorid
    WHERE ts.quality_class = ls.quality_class
    AND ts.is_active = ls.is_active
),
changed_records AS (
    -- Scenario 2: Actor's quality_class OR is_active has changed
    -- Need to create TWO records:
    -- 1. Close the old record (keep its original values, don't extend)
    -- 2. Open a new record with new values starting this year
    SELECT
        ts.actor,
        ts.actorid,
        -- UNNEST an array containing both the closed and new records
        UNNEST(ARRAY[
            -- Record 1: The old record (closed, not extended)
            ROW(
                ls.quality_class,
                ls.is_active,
                ls.start_date,
                ls.end_date    -- keep last year as end_date (don't extend)
            )::scd_type,
            -- Record 2: The new record (starts and ends this year)
            ROW(
                ts.quality_class,
                ts.is_active,
                ts.current_year,  -- new record starts this year
                ts.current_year   -- new record also ends this year (for now)
            )::scd_type
        ]) AS records
    FROM this_year_data ts
    LEFT JOIN last_year_scd ls
        ON ls.actorid = ts.actorid
    WHERE (ts.quality_class <> ls.quality_class
        OR ts.is_active <> ls.is_active)
),
unnested_changed_records AS (
    -- extract the fields from the scd_type struct created above
    SELECT
        actor,
        actorid,
        (records::scd_type).quality_class,
        (records::scd_type).is_active,
        (records::scd_type).start_date,
        (records::scd_type).end_date
    FROM changed_records
),
new_records AS (
    -- Scenario 3: Brand new actors who weren't in last year's SCD
    -- Create a new record starting and ending this year
    SELECT
        ts.actor,
        ts.actorid,
        ts.quality_class,
        ts.is_active,
        ts.current_year AS start_date,  -- first appearance
        ts.current_year AS end_date     -- also their current state
    FROM this_year_data ts
    LEFT JOIN last_year_scd ls
        ON ts.actorid = ls.actorid
    WHERE ls.actorid IS NULL  -- not in last year's data
)
-- Combine all four categories of records
SELECT actor, actorid, quality_class, is_active, start_date, end_date, 
       2022 as current_year FROM historical_scd        -- already closed records
UNION ALL
SELECT actor, actorid, quality_class, is_active, start_date, end_date, 
       2022 as current_year FROM unchanged_records     -- extended records
UNION ALL
SELECT actor, actorid, quality_class, is_active, start_date, end_date, 
       2022 as current_year FROM unnested_changed_records  -- closed + new records
UNION ALL
SELECT actor, actorid, quality_class, is_active, start_date, end_date, 
       2022 as current_year FROM new_records;          -- brand new actors

-- Summary
-- 1. CUMULATIVE TABLE DESIGN (Task 2)
--    - Uses FULL OUTER JOIN to merge yesterday's state with today's new data
--    - Accumulates history (films array grows over time)
--    - Idempotent: can be run multiple times for the same year without duplicates

-- 2. COMPLEX DATA TYPES (Task 1)
--    - Array of structs stores multiple films per actor in one row
--    - Reduces table scans and improves query performance
--    - Custom types (films_type, quality_class) enforce schema and data quality

-- 3. SLOWLY CHANGING DIMENSIONS - TYPE 2 (Tasks 3-5)
--    - Tracks historical changes with start_date and end_date
--    - Backfill approach: Process all history at once using window functions
--    - Incremental approach: Process only new data, handle 3 scenarios
--      * Unchanged: Extend end_date
--      * Changed: Close old record, open new record
--      * New: Create initial record

-- 4. WINDOW FUNCTIONS
--    - LAG: Look at previous row's values to detect changes
--    - SUM OVER: Create streak identifiers for grouping consecutive periods

-- 5. UNNEST TECHNIQUE
--    - Generate multiple rows from a single row
--    - Used in changed_records to create both the closing and opening records

-- WHY THESE PATTERNS MATTER:
-- - Cumulative tables reduce computation by only processing incremental data
-- - SCD Type 2 allows point-in-time analysis (what was the state on date X?)
-- - These patterns are idempotent and production-ready
-- - Complex types reduce joins and improve performance at scale
