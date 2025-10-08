-- Week 4 Applying Analytical Patterns
-- 1. A query that does state change tracking for players
-- Goal: Track how each player's active status changes
--       between NBA seasons using window functions.
WITH player_state_changes AS (
    SELECT 
        player_name,
        current_season,
        is_active,
        -- LAG allows comparing a player's current and previous season statuses
        LAG(is_active) OVER (PARTITION BY player_name ORDER BY current_season) as previous_active_status
    FROM players_scd
    WHERE current_season IS NOT NULL
),

player_states AS (
    SELECT 
        player_name,
        current_season,
        is_active,
        previous_active_status,
        -- Define transitions between active/inactive states
        CASE 
            WHEN previous_active_status IS NULL AND is_active = true THEN 'New'
            WHEN previous_active_status = true AND is_active = false THEN 'Retired'
            WHEN previous_active_status = true AND is_active = true THEN 'Continued Playing'
            WHEN previous_active_status = false AND is_active = true THEN 'Returned from Retirement'
            WHEN previous_active_status = false AND is_active = false THEN 'Stayed Retired'
            ELSE 'Unknown'
        END as player_status
    FROM player_state_changes
)
SELECT 
    player_name,
    current_season,
    player_status,
    -- Count how many players fall into each status category
    COUNT(*) OVER (PARTITION BY player_status) as status_count
FROM player_states
ORDER BY current_season, player_name;


-- 2. A query that uses GROUPING SETS to do efficient aggregations of game_details data
-- Goal: Aggregate game_details data at multiple levels
--       (player-team, player-season, team) in one query.
SELECT 
    -- Label the level of aggregation dynamically using GROUPING()
    CASE 
        WHEN GROUPING(player_name) = 0 AND GROUPING(team_abbreviation) = 0 AND GROUPING(season) = 1 THEN 'Player-Team'
        WHEN GROUPING(player_name) = 0 AND GROUPING(team_abbreviation) = 1 AND GROUPING(season) = 0 THEN 'Player-Season'
        WHEN GROUPING(player_name) = 1 AND GROUPING(team_abbreviation) = 0 AND GROUPING(season) = 1 THEN 'Team'
        ELSE 'Other'
    END as aggregation_level,
    
    -- Display only the appropriate level name, replace others with ALL
    CASE WHEN GROUPING(player_name) = 0 THEN player_name ELSE 'ALL PLAYERS' END as player_name,
    CASE WHEN GROUPING(team_abbreviation) = 0 THEN team_abbreviation ELSE 'ALL TEAMS' END as team_abbreviation,
    CASE WHEN GROUPING(season) = 0 THEN season ELSE 'ALL SEASONS' END as season,
    
    -- Aggregate metrics
    SUM(pts) as total_points,
    COUNT(game_id) as games_played,
    ROUND(AVG(pts), 2) as avg_points_per_game,
    MAX(pts) as max_points_single_game,
    SUM(CASE WHEN team_id = game_id THEN 1 ELSE 0 END) as wins -- Simplified proxy for wins
FROM game_details gd
WHERE season >= 2020
GROUP BY GROUPING SETS (
    (player_name, team_abbreviation),
    (player_name, season),
    (team_abbreviation)
)
ORDER BY aggregation_level, total_points DESC;


-- ADDITIONAL AGGREGATION INSIGHTS
-- Answering specific analytical questions
-- Who scored the most points playing for one team?
SELECT 
    player_name,
    team_abbreviation,
    SUM(pts) as total_points,
    COUNT(game_id) as games_played
FROM game_details
GROUP BY player_name, team_abbreviation
ORDER BY total_points DESC
LIMIT 10;

-- Who scored the most points in one season?
SELECT 
    player_name,
    season,
    SUM(pts) as total_points,
    COUNT(game_id) as games_played,
    ROUND(AVG(pts), 1) as avg_ppg
FROM game_details
GROUP BY player_name, season
ORDER BY total_points DESC
LIMIT 10;

-- Which team has the most total points scored?
SELECT 
    team_abbreviation,
    COUNT(DISTINCT season) as seasons_active,
    SUM(pts) as total_points_scored,
    COUNT(game_id) as total_games,
    ROUND(AVG(pts), 1) as avg_team_ppg
FROM game_details
GROUP BY team_abbreviation
ORDER BY total_points_scored DESC
LIMIT 10;



-- 3. A query that uses window functions on game_details to find out the following things:
-- Goal: Apply advanced window logic to measure trends
-- What is the most games a team has won in a 90 game stretch?
WITH team_games_chronological AS (
    SELECT 
        team_abbreviation,
        game_date_est,
        game_id,
        -- Proxy for wins (team scored above their season average)
        CASE WHEN pts > AVG(pts) OVER (PARTITION BY team_abbreviation, season) THEN 1 ELSE 0 END as proxy_win,
        ROW_NUMBER() OVER (PARTITION BY team_abbreviation ORDER BY game_date_est) as game_sequence
    FROM game_details
    WHERE game_date_est IS NOT NULL
),

rolling_wins AS (
    SELECT 
        team_abbreviation,
        game_date_est,
        game_sequence,
        proxy_win,
        -- Rolling total wins in the last 90 games
        SUM(proxy_win) OVER (
            PARTITION BY team_abbreviation 
            ORDER BY game_sequence 
            ROWS BETWEEN 89 PRECEDING AND CURRENT ROW
        ) as wins_in_90_games,
        CASE WHEN game_sequence >= 90 THEN 
            SUM(proxy_win) OVER (
                PARTITION BY team_abbreviation 
                ORDER BY game_sequence 
                ROWS BETWEEN 89 PRECEDING AND CURRENT ROW
            ) 
        END as valid_90_game_wins
    FROM team_games_chronological
)
SELECT 
    team_abbreviation,
    MAX(valid_90_game_wins) as max_wins_in_90_games,
    COUNT(CASE WHEN valid_90_game_wins = MAX(valid_90_game_wins) OVER (PARTITION BY team_abbreviation) THEN 1 END) as times_achieved
FROM rolling_wins
WHERE valid_90_game_wins IS NOT NULL
GROUP BY team_abbreviation
ORDER BY max_wins_in_90_games DESC;


-- How many games in a row did LeBron James score over 10 points a game?
WITH lebron_games AS (
    SELECT 
        player_name,
        game_date_est,
        pts,
        CASE WHEN pts > 10 THEN 1 ELSE 0 END as scored_over_10,
        ROW_NUMBER() OVER (ORDER BY game_date_est) as game_sequence
    FROM game_details
    WHERE player_name = 'LeBron James'
        AND game_date_est IS NOT NULL
        AND pts IS NOT NULL
    ORDER BY game_date_est
),

streak_groups AS (
    SELECT 
        player_name,
        game_date_est,
        pts,
        scored_over_10,
        game_sequence,
        -- Group consecutive games together by adjusting row number difference
        game_sequence - ROW_NUMBER() OVER (PARTITION BY scored_over_10 ORDER BY game_sequence) as streak_group
    FROM lebron_games
),

streak_lengths AS (
    SELECT 
        streak_group,
        scored_over_10,
        COUNT(*) as streak_length,
        MIN(game_date_est) as streak_start,
        MAX(game_date_est) as streak_end,
        MIN(pts) as min_points_in_streak,
        MAX(pts) as max_points_in_streak,
        ROUND(AVG(pts), 1) as avg_points_in_streak
    FROM streak_groups
    GROUP BY streak_group, scored_over_10
)
SELECT 
    'LeBron James Scoring Streaks (>10 points)' as analysis_type,
    streak_length as consecutive_games,
    streak_start,
    streak_end,
    min_points_in_streak,
    max_points_in_streak,
    avg_points_in_streak
FROM streak_lengths
WHERE scored_over_10 = 1
ORDER BY streak_length DESC
LIMIT 10;


-- SUMMARY QUERIES FOR INSIGHTS
-- Goal: Summarize player transitions by season
SELECT 
    current_season,
    SUM(CASE WHEN player_status = 'New' THEN 1 ELSE 0 END) as new_players,
    SUM(CASE WHEN player_status = 'Retired' THEN 1 ELSE 0 END) as retired_players,
    SUM(CASE WHEN player_status = 'Continued Playing' THEN 1 ELSE 0 END) as continuing_players,
    SUM(CASE WHEN player_status = 'Returned from Retirement' THEN 1 ELSE 0 END) as comeback_players,
    SUM(CASE WHEN player_status = 'Stayed Retired' THEN 1 ELSE 0 END) as stayed_retired
FROM (
    WITH player_state_changes AS (
        SELECT 
            player_name,
            current_season,
            is_active,
            LAG(is_active) OVER (PARTITION BY player_name ORDER BY current_season) as previous_active_status
        FROM players_scd
        WHERE current_season IS NOT NULL
    )
    SELECT 
        player_name,
        current_season,
        CASE 
            WHEN previous_active_status IS NULL AND is_active = true THEN 'New'
            WHEN previous_active_status = true AND is_active = false THEN 'Retired'
            WHEN previous_active_status = true AND is_active = true THEN 'Continued Playing'
            WHEN previous_active_status = false AND is_active = true THEN 'Returned from Retirement'
            WHEN previous_active_status = false AND is_active = false THEN 'Stayed Retired'
            ELSE 'Unknown'
        END as player_status
    FROM player_state_changes
) player_status_summary
GROUP BY current_season
ORDER BY current_season;


-- Summary
-- This assignment demonstrates advanced analytical SQL patterns:

-- 1. STATE CHANGE TRACKING (Task 1)
--    - Uses LAG() window function to compare player activity across seasons
--    - Categorizes players as New, Retired, Continued, Returned, or Stayed Retired
--    - Enables historical lifecycle analysis of players

-- 2. GROUPING SETS (Task 2)
--    - Performs multiple aggregation levels (player-team, player-season, team) efficiently
--    - Uses GROUPING() to dynamically label aggregation levels
--    - Answers key analytical questions: top scorers by team or season, top-performing teams

-- 3. WINDOW FUNCTIONS ANALYSIS (Task 3)
--    - Applies ROW_NUMBER() and SUM() OVER windows for rolling and streak calculations
--    - Detects best 90-game team performance periods
--    - Identifies LeBron James’ longest streak scoring over 10 points

-- WHY THESE PATTERNS MATTER:
-- - Enable time-based and hierarchical insights without repetitive queries
-- - Optimize query performance via window functions and grouping sets
-- - Provide reusable frameworks for sports analytics, finance, or user behavior tracking
