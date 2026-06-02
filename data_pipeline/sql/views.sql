DROP VIEW IF EXISTS team_seasons_summary CASCADE;
DROP VIEW IF EXISTS team_clinch          CASCADE;
DROP VIEW IF EXISTS team_elimination     CASCADE;
DROP VIEW IF EXISTS team_standings       CASCADE;
DROP VIEW IF EXISTS team_games           CASCADE;


CREATE VIEW team_games AS
SELECT
    g.game_id,
    g.season,
    g.game_date,
    g.home_team   AS team,
    g.away_team   AS opponent,
    TRUE          AS is_home,
    g.home_score  AS goals_for,
    g.away_score  AS goals_against,
    g.last_period,
    CASE
        WHEN g.home_score > g.away_score        THEN 2   -- win
        WHEN g.last_period IN ('OT','SO')       THEN 1   -- OT/SO loss
        ELSE                                          0   -- regulation loss
    END AS points
FROM games g

UNION ALL

SELECT
    g.game_id,
    g.season,
    g.game_date,
    g.away_team   AS team,
    g.home_team   AS opponent,
    FALSE         AS is_home,
    g.away_score  AS goals_for,
    g.home_score  AS goals_against,
    g.last_period,
    CASE
        WHEN g.away_score > g.home_score        THEN 2
        WHEN g.last_period IN ('OT','SO')       THEN 1
        ELSE                                          0
    END AS points
FROM games g;



CREATE VIEW team_standings AS
SELECT
    tg.team,
    tg.season,
    tg.game_date,
    tg.points,
    SUM(tg.points) OVER w                                 AS cum_points,
    COUNT(*)       OVER w                                 AS games_played,
    82 - COUNT(*)  OVER w                                 AS games_remaining,
    SUM(tg.points) OVER w + 2 * (82 - COUNT(*) OVER w)    AS max_possible_points
FROM team_games tg
WINDOW w AS (PARTITION BY tg.team, tg.season ORDER BY tg.game_date);

DROP VIEW IF EXISTS team_elimination;

CREATE VIEW team_elimination AS
WITH final_pts AS (
    SELECT
        team,
        season,
        MAX(cum_points) AS final_points
    FROM team_standings
    GROUP BY team, season
),
ranked AS (
    SELECT
        team,
        season,
        final_points,
        ROW_NUMBER() OVER (PARTITION BY season ORDER BY final_points DESC) AS seed
    FROM final_pts
),
season_cutoffs AS (
    SELECT season, final_points AS playoff_cutoff
    FROM ranked
    WHERE seed = 16
)
SELECT
    r.team,
    r.season,
    r.final_points,
    r.seed,
    (r.seed > 16)            AS missed_playoffs,
    sc.playoff_cutoff,
    (
        SELECT MIN(ts.game_date)
        FROM team_standings ts
        WHERE ts.team    = r.team
          AND ts.season  = r.season
          AND ts.max_possible_points < sc.playoff_cutoff
    ) AS elimination_date
FROM ranked r
JOIN season_cutoffs sc ON sc.season = r.season;




CREATE VIEW team_clinch AS
WITH final_pts AS (
    SELECT
        team,
        season,
        MAX(cum_points) AS final_points
    FROM team_standings
    GROUP BY team, season
),
ranked AS (
    SELECT
        team,
        season,
        final_points,
        ROW_NUMBER() OVER (PARTITION BY season ORDER BY final_points DESC) AS seed
    FROM final_pts
),
season_cutoffs AS (
    SELECT season, final_points AS clinch_cutoff
    FROM ranked
    WHERE seed = 17
)
SELECT
    r.team,
    r.season,
    r.final_points,
    r.seed,
    (r.seed <= 16)           AS made_playoffs,
    sc.clinch_cutoff,
    (
        SELECT MIN(ts.game_date)
        FROM team_standings ts
        WHERE ts.team   = r.team
          AND ts.season = r.season
          AND ts.cum_points > sc.clinch_cutoff
    ) AS clinch_date
FROM ranked r
JOIN season_cutoffs sc ON sc.season = r.season;



CREATE VIEW team_seasons_summary AS
WITH
  deadline_agg AS (
    SELECT
      tg.team,
      tg.season,
      SUM(CASE WHEN tg.game_date <= ss.trade_deadline THEN tg.points END)::float
        / NULLIF(SUM(CASE WHEN tg.game_date <= ss.trade_deadline THEN 2 END), 0)  AS pre_deadline_pct,
      SUM(CASE WHEN tg.game_date >  ss.trade_deadline THEN tg.points END)::float
        / NULLIF(SUM(CASE WHEN tg.game_date >  ss.trade_deadline THEN 2 END), 0)  AS post_deadline_pct,
      COUNT(*) FILTER (WHERE tg.game_date <= ss.trade_deadline) AS games_pre_deadline,
      COUNT(*) FILTER (WHERE tg.game_date >  ss.trade_deadline) AS games_post_deadline
    FROM team_games tg
    JOIN season_structure ss ON ss.season = tg.season
    GROUP BY tg.team, tg.season
  ),
  elim_agg AS (
    SELECT
      tg.team,
      tg.season,
      SUM(CASE WHEN tg.game_date <= te.elimination_date THEN tg.points END)::float
        / NULLIF(SUM(CASE WHEN tg.game_date <= te.elimination_date THEN 2 END), 0) AS pre_elim_pct,
      SUM(CASE WHEN tg.game_date >  te.elimination_date THEN tg.points END)::float
        / NULLIF(SUM(CASE WHEN tg.game_date >  te.elimination_date THEN 2 END), 0) AS post_elim_pct,
      COUNT(*) FILTER (WHERE tg.game_date <= te.elimination_date) AS games_pre_elim,
      COUNT(*) FILTER (WHERE tg.game_date >  te.elimination_date) AS games_post_elim
    FROM team_games tg
    JOIN team_elimination te ON te.team = tg.team AND te.season = tg.season
    WHERE te.missed_playoffs
    GROUP BY tg.team, tg.season
  ),
  clinch_agg AS (
    SELECT
      tg.team,
      tg.season,
      SUM(CASE WHEN tg.game_date <= tc.clinch_date THEN tg.points END)::float
        / NULLIF(SUM(CASE WHEN tg.game_date <= tc.clinch_date THEN 2 END), 0) AS pre_clinch_pct,
      SUM(CASE WHEN tg.game_date >  tc.clinch_date THEN tg.points END)::float
        / NULLIF(SUM(CASE WHEN tg.game_date >  tc.clinch_date THEN 2 END), 0) AS post_clinch_pct,
      COUNT(*) FILTER (WHERE tg.game_date <= tc.clinch_date) AS games_pre_clinch,
      COUNT(*) FILTER (WHERE tg.game_date >  tc.clinch_date) AS games_post_clinch
    FROM team_games tg
    JOIN team_clinch tc ON tc.team = tg.team AND tc.season = tg.season
    WHERE tc.made_playoffs
    GROUP BY tg.team, tg.season
  )
SELECT
  te.team,
  te.season,
  ss.season_label,
  te.seed,
  te.final_points,
  te.missed_playoffs,
  NOT te.missed_playoffs               AS made_playoffs,
  te.elimination_date,
  tc.clinch_date,
  -- Deadline-based (headline split)
  da.pre_deadline_pct,
  da.post_deadline_pct,
  da.post_deadline_pct - da.pre_deadline_pct AS drop_deadline,
  da.games_pre_deadline,
  da.games_post_deadline,
  -- Elimination-based (non-playoff teams only)
  ea.pre_elim_pct,
  ea.post_elim_pct,
  ea.post_elim_pct - ea.pre_elim_pct   AS drop_elim,
  ea.games_pre_elim,
  ea.games_post_elim,
  -- Clinch-based (playoff teams only)
  ca.pre_clinch_pct,
  ca.post_clinch_pct,
  ca.post_clinch_pct - ca.pre_clinch_pct AS drop_clinch,
  ca.games_pre_clinch,
  ca.games_post_clinch
FROM team_elimination te
JOIN season_structure ss ON ss.season = te.season
LEFT JOIN team_clinch  tc ON tc.team = te.team AND tc.season = te.season
LEFT JOIN deadline_agg da ON da.team = te.team AND da.season = te.season
LEFT JOIN elim_agg     ea ON ea.team = te.team AND ea.season = te.season
LEFT JOIN clinch_agg   ca ON ca.team = te.team AND ca.season = te.season;