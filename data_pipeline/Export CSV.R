library(DBI)
library(RPostgres)
library(readr)

con <- dbConnect(RPostgres::Postgres(), dbname = "nhl", host = "localhost")

# 1. team-season summary → CSV
team_seasons <- dbGetQuery(con, "SELECT * FROM team_seasons_summary")
write_csv(team_seasons, "data/team_seasons.csv")

# 2. team-game level → CSV (optional, only for the line chart on Page 3)
team_games_full <- dbGetQuery(con, "
  SELECT tg.team, tg.season, tg.game_date, tg.points, tg.is_home,
         tg.goals_for, tg.goals_against,
         ts.cum_points, ts.games_played,
         te.elimination_date, tc.clinch_date, ss.trade_deadline
  FROM team_games tg
  JOIN team_standings ts
    ON ts.team = tg.team AND ts.season = tg.season AND ts.game_date = tg.game_date
  JOIN team_elimination te
    ON te.team = tg.team AND te.season = tg.season
  LEFT JOIN team_clinch tc
    ON tc.team = tg.team AND tc.season = tg.season
  JOIN season_structure ss
    ON ss.season = tg.season
")
write_csv(team_games_full, "data/team_games_full.csv")

# 3. sanity check
str(team_games_full)

# 4. close connection
dbDisconnect(con)

