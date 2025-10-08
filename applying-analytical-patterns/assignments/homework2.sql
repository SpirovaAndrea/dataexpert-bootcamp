-- -------------------- CREATE TABLE & INDEX --------------------

-- Creating the sink table to store sessionized web events
CREATE TABLE sessionized_events (
    ip VARCHAR,
    host VARCHAR,
    session_start TIMESTAMP(3),
    session_end TIMESTAMP(3),
    url_list TEXT
);

-- Creating an index on host for faster filtering and grouping performance
CREATE INDEX idx_host ON sessionized_events (host);

-- Check inserted data
SELECT * FROM sessionized_events;

-- -------------------- QUERY 1 --------------------
-- Calculate the average number of web events per session
-- for users browsing any Tech Creator website.
-- Each session’s URLs are stored as a comma-separated string,
-- which is split into an array to count the total number of events.

SELECT
    host,
    AVG(array_length(string_to_array(url_list, ','), 1)) AS avg_events_per_session
FROM sessionized_events
WHERE host LIKE '%techcreator.io'  -- Only Tech Creator domains
GROUP BY host;

-- -------------------- QUERY 2 --------------------
-- Compare the same metric (average events per session)
-- between specific Tech Creator hosts.
-- Results are sorted by engagement level (descending).

SELECT
    host,
    AVG(array_length(string_to_array(url_list, ','), 1)) AS avg_events_per_session
FROM sessionized_events
WHERE host IN ('zachwilson.techcreator.io', 'zachwilson.tech', 'lulu.techcreator.io')
GROUP BY host
ORDER BY avg_events_per_session DESC;



-- --Summary

-- 1. PURPOSE:
-- This SQL script analyzes the sessionized web traffic data produced by the Flink job.

-- 2. PROCESS:
-- Creates a PostgreSQL table and index for optimized queries.
-- Calculates the average number of web events per session for users visiting Tech Creator sites.
-- Compares session activity across specific hosts.

-- 3. OUTCOME:
-- Helps identify which host has the most active users and how engaged visitors are during each session — providing valuable insights for product or marketing teams.