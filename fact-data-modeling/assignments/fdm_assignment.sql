-- Fact Data Modeling - Week 2
-- The homework this week will be using the devices and events dataset


-- 1. A query to deduplicate game_details from Day 1 so there's no duplicates
-- Remove duplicates based on game_id, team_id, player_id
WITH deduped AS (
    SELECT
        *, -- select all columns from game_details
        ROW_NUMBER() OVER (
            PARTITION BY game_id, team_id, player_id -- create partitions for duplicates
            ORDER BY game_id -- choose one row per partition
        ) AS row_num -- assign a row number within each partition
    FROM game_details
)
SELECT
    game_id,
    team_id,
    player_id,
    player_name,
    start_position,
    comment,
    min,
    fgm,
    fga,
    fg3m,
    fg3a,
    ftm,
    fta,
    oreb,
    dreb,
    reb,
    ast,
    stl,
    blk,
    "TO" AS turnovers,
    pf,
    pts,
    plus_minus
FROM deduped
WHERE row_num = 1 -- keep only the first row per duplicate group
ORDER BY game_id, team_id, player_id;


-- 2. A DDL for an user_devices_cumulated table that has:
-- a device_activity_datelist which tracks a users active days by browser_type
-- data type here should look similar to MAP<STRING, ARRAY[DATE]>
-- or you could have browser_type as a column with multiple rows for each user (either way works, just be consistent!)
-- Stores active days per user per browser
CREATE TABLE user_devices_cumulated (
    user_id TEXT, -- unique user identifier
    browser_type TEXT, -- type of browser/device
    dates_active DATE[], -- array of all active dates
    date DATE, -- the last date the table was updated
    PRIMARY KEY (user_id, browser_type, date) -- combination must be unique
);

-- 3. A cumulative query to generate device_activity_datelist from events
-- Merge yesterday's state with today's events
INSERT INTO user_devices_cumulated
WITH yesterday AS (
    SELECT * -- get previous day's state
    FROM user_devices_cumulated
    WHERE date = DATE('2023-01-30')
),
today AS (
    SELECT
        CAST(user_id AS TEXT) AS user_id, -- make sure user_id is TEXT
        CAST(device_id AS TEXT) AS browser_type, -- device/browser
        DATE(event_time) AS date_active -- event date
    FROM events
    WHERE DATE(event_time) = DATE('2023-01-31') -- filter today's events
      AND user_id IS NOT NULL -- ignore null users
    GROUP BY user_id, device_id, DATE(event_time) -- remove duplicates
)
SELECT
    COALESCE(t.user_id, y.user_id) AS user_id, -- prefer today if exists
    COALESCE(t.browser_type, y.browser_type) AS browser_type,
    CASE
        WHEN y.dates_active IS NULL THEN ARRAY[t.date_active] -- no yesterday? start array with today
        WHEN t.date_active IS NULL THEN y.dates_active -- no today? keep yesterday's array
        ELSE ARRAY[t.date_active] || y.dates_active -- merge today's date into array
    END AS dates_active,
    COALESCE(t.date_active, y.date + INTERVAL '1 day') AS date -- update last active date
FROM today t
FULL OUTER JOIN yesterday y
    ON t.user_id = y.user_id
   AND t.browser_type = y.browser_type; -- match on user+browser


-- 4. A datelist_int generation query. Convert the device_activity_datelist column into a datelist_int column
-- Convert array of dates to integer/bit representation
WITH users_devices AS (
    SELECT * -- get latest user_devices_cumulated
    FROM user_devices_cumulated
    WHERE date = DATE('2023-01-31')
),
series AS (
    SELECT *
    FROM generate_series(DATE('2023-01-01'), DATE('2023-01-31'), INTERVAL '1 day') AS series_date -- all days in month
),
placeholder_ints AS (
    SELECT
        user_id,
        browser_type,
        CASE WHEN dates_active @> ARRAY[DATE(series_date)] -- if user active on that date
            THEN CAST(POW(2, 32 - (DATE('2023-01-31') - DATE(series_date))) AS BIGINT) -- calculate placeholder int
            ELSE 0
        END AS placeholder_int_value,
        dates_active,
        date
    FROM users_devices
    CROSS JOIN series -- combine each user with all dates
)
SELECT
    user_id,
    browser_type,
    CAST(SUM(placeholder_int_value) AS BIGINT) AS datelist_int, -- final integer representing active days
    CAST(CAST(SUM(placeholder_int_value) AS BIGINT) AS BIT(32)) AS datelist_binary, -- optional binary representation
    dates_active,
    date
FROM placeholder_ints
GROUP BY user_id, browser_type, dates_active, date
ORDER BY user_id, browser_type;

-- 5. A DDL for hosts_cumulated table:
-- a host_activity_datelist which logs to see which dates each host is experiencing any activity
-- Tracks which dates each host has activity
CREATE TABLE hosts_cumulated (
    host TEXT, -- host/domain
    host_activity_datelist DATE[], -- array of active dates
    date DATE, -- last update date
    PRIMARY KEY (host, date)
);


-- 6. The incremental query to generate host_activity_datelist
-- Merge yesterday's state with today's events
INSERT INTO hosts_cumulated
WITH yesterday AS (
    SELECT *
    FROM hosts_cumulated
    WHERE date = DATE('2023-01-30')
),
today AS (
    SELECT
        CAST(host AS TEXT) AS host,
        DATE(event_time) AS date_active
    FROM events
    WHERE DATE(event_time) = DATE('2023-01-31')
      AND host IS NOT NULL
    GROUP BY host, DATE(event_time)
)
SELECT
    COALESCE(t.host, y.host) AS host,
    CASE
        WHEN y.host_activity_datelist IS NULL THEN ARRAY[t.date_active] -- start array if no history
        WHEN t.date_active IS NULL THEN y.host_activity_datelist -- keep old array
        ELSE ARRAY[t.date_active] || y.host_activity_datelist -- merge today's date
    END AS host_activity_datelist,
    COALESCE(t.date_active, y.date + INTERVAL '1 day') AS date
FROM today t
FULL OUTER JOIN yesterday y
    ON t.host = y.host;

-- 7. A monthly, reduced fact table DDL host_activity_reduced
-- month
-- host
-- hit_array - think COUNT(1)
-- unique_visitors array - think COUNT(DISTINCT user_id)
-- Arrays store daily hits and unique visitors per host
CREATE TABLE host_activity_reduced (
    month DATE, -- month of aggregation
    host TEXT, -- host/domain
    hit_array INTEGER[], -- daily hits
    unique_visitors INTEGER[], -- daily unique users
    PRIMARY KEY (month, host)
);

-- 8. An incremental query that loads host_activity_reduced
-- day-by-day
-- Merge today's daily aggregates with previous month data
INSERT INTO host_activity_reduced
WITH yesterday AS (
    SELECT *
    FROM host_activity_reduced
    WHERE month = DATE_TRUNC('month', DATE('2023-01-31'))
), today AS (
    SELECT
        host,
        DATE_TRUNC('month', DATE(CAST(event_time AS TIMESTAMP))) AS month, -- start of month
        DATE(CAST(event_time AS TIMESTAMP)) AS event_date,
        COUNT(1) AS daily_hits,
        COUNT(DISTINCT user_id) AS daily_unique_visitors
    FROM events
    WHERE DATE(CAST(event_time AS TIMESTAMP)) = DATE('2023-01-31')
      AND host IS NOT NULL
    GROUP BY host,
             DATE_TRUNC('month', DATE(CAST(event_time AS TIMESTAMP))),
             DATE(CAST(event_time AS TIMESTAMP))
)
SELECT
    COALESCE(t.month, y.month) AS month, -- prefer today's month if exists
    COALESCE(t.host, y.host) AS host,   -- prefer today's host if exists
    CASE
        WHEN y.hit_array IS NULL THEN
            ARRAY_FILL(0, ARRAY[EXTRACT(DAY FROM DATE_TRUNC('month', COALESCE(t.month, y.month)) + INTERVAL '1 month' - INTERVAL '1 day')::INTEGER])
            || ARRAY[t.daily_hits] -- insert today's hits
            || ARRAY_FILL(0, ARRAY[EXTRACT(DAY FROM COALESCE(t.event_date, y.month + INTERVAL '1 day'))::INTEGER - 1])
        WHEN t.daily_hits IS NULL THEN
            y.hit_array -- keep yesterday if no data today
        ELSE
            y.hit_array[1:EXTRACT(DAY FROM t.event_date)::INTEGER - 1] -- slice before today
            || ARRAY[t.daily_hits] -- insert today's value
            || y.hit_array[EXTRACT(DAY FROM t.event_date)::INTEGER + 1:] -- slice after today
    END AS hit_array,
    CASE
        WHEN y.unique_visitors IS NULL THEN
            ARRAY_FILL(0, ARRAY[EXTRACT(DAY FROM DATE_TRUNC('month', COALESCE(t.month, y.month)) + INTERVAL '1 month' - INTERVAL '1 day')::INTEGER])
            || ARRAY[t.daily_unique_visitors]
            || ARRAY_FILL(0, ARRAY[EXTRACT(DAY FROM COALESCE(t.event_date, y.month + INTERVAL '1 day'))::INTEGER - 1])
        WHEN t.daily_unique_visitors IS NULL THEN
            y.unique_visitors
        ELSE
            y.unique_visitors[1:EXTRACT(DAY FROM t.event_date)::INTEGER - 1]
            || ARRAY[t.daily_unique_visitors]
            || y.unique_visitors[EXTRACT(DAY FROM t.event_date)::INTEGER + 1:]
    END AS unique_visitors
FROM today t
FULL OUTER JOIN yesterday y
    ON t.host = y.host
   AND t.month = y.month;


-- Summary
-- 1. DEDUPLICATION (Task 1)
--    - Uses ROW_NUMBER() to identify and remove duplicate records.
--    - Ensures each (game_id, team_id, player_id) combination appears only once.
--    - Improves data accuracy and prevents inflated metrics in downstream analysis.

-- 2. CUMULATIVE TABLE DESIGN (Tasks 2 & 4)
--    - Uses FULL OUTER JOIN to merge yesterday’s cumulative state with today’s data.
--    - Tracks user and host activity over time, storing results in arrays.
--    - Enables time-based trend analysis while minimizing recomputation.
--    - Idempotent design: can be safely re-run for the same period without duplicating data.

-- 3. ARRAY AND BITWISE REPRESENTATION (Task 3)
--    - Converts arrays of dates into integer representations for efficient storage.
--    - Supports fast filtering and comparisons using bitwise operations.
--    - Useful for activity streaks, retention tracking, or engagement scoring.

-- 4. REDUCED FACT TABLES (Task 5)
--    - Aggregates detailed daily activity into compact monthly arrays.
--    - Reduces query load by precomputing key aggregates (hits, unique visitors).
--    - Improves dashboard and analytical performance by minimizing table scans.

-- 5. KEY TECHNIQUES USED
--    - Window Functions (ROW_NUMBER): for deduplication.
--    - FULL OUTER JOIN Pattern: for incremental cumulative updates.
--    - Arrays: compactly store multiple daily values per entity.
--    - Bitwise Encoding: represents activity presence efficiently.
--    - Aggregation Patterns: support trend and performance analysis.

-- WHY THESE PATTERNS MATTER:
-- - Deduplication ensures clean, trustworthy data sources.
-- - Cumulative design supports historical trend tracking without full reloads.
-- - Array and bitwise storage optimize performance and memory efficiency.
-- - Reduced fact tables speed up dashboards and downstream analytics.
-- - Together, they create scalable, production-grade data models.
