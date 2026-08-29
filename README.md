# Draft & Tank: NHL Late-Season Behavior Analysis

> Across three NHL seasons, I tested whether non-playoff teams systematically tank for draft-lottery position. I unfortunately did not find a pattern. However, along the journey I did find and quantify the opposite-direction pattern in playoff teams: a clear, statistically significant load-management effect that scales with team quality.

## TL;DR

- **Hypothesis tested**: NHL non-playoff teams with strong draft-lottery incentives underperform their pre-deadline pace late in the season.
- **Result**: Pattern does not exist. Two event-study designs (trade-deadline split, mathematical-elimination event) both produced slopes statistically indistinguishable from zero. n = 48 non-playoff team-seasons. (I guess no betting loophole)
- **Unexpected finding**: playoff teams systematically ease off after the deadline, scaled by pre-deadline strength (β = −0.89, p = 0.0004, n = 48 playoff team-seasons).

## How I began

Like a normal hockey fan, (WPG jets best nhl team and its not even close), I assumed "tanking" was obvious; bad teams lose on purpose in March to boost draft lottery odds. So I built a database (NHL public API, 3 seasons, 3,900 regular-season games), tested it with two hypothesis, and braced for a juicy finding so I can bet some cash at the end of each season to win some guaranteed money. hehe

The finding wasn't juicy. It was null. Non-playoff teams showed no statistically detectable tank signal across either specification. Surprising and disappointing...

But splitting the data by playoff outcome revealed a different pattern: playoff teams that finish stronger drop more sharply after the trade deadline. The 2022-23 Hurricanes (2nd overall) played at a 0.75 points% pace pre-deadline, then dropped to 0.50 over their last 19 games. Across 48 playoff team-seasons, the relationship was significant at β = −0.89, p < 0.001.

Load management appears to be a real thing and quantified. Tanking is, apparently, invisible at this scale. Perhaps I will endeavor for a new datasets with 10 or more seasons to see if there is a tanking pattern.

## Method

- **Data**: NHL public API (`api-web.nhle.com`), 3 seasons (2021-22 to 2023-24), ~3,900 regular-season games.
- **Storage**: PostgreSQL 18 with a star schema (`games`, `season_structure`) plus four derived views (`team_games`, `team_standings`, `team_elimination`, `team_clinch`).
- **Analysis**: R / RMarkdown — `httr2` for ingestion, `dplyr` + `ggplot2` for analysis, OLS regression with weighted and unweighted fits.
- **Visualization**: Power BI Desktop, 3-page interactive dashboard.

## Repository structure (format and structure is thanks to Claude Code absolute beaty ill tell you that for free)
<img width="525" height="236" alt="image" src="https://github.com/user-attachments/assets/afe3c174-583c-4cbb-b7ad-ae9f3de6ccba" />


## How to reproduce
1. Install dependencies:
   - PostgreSQL 17+ (Postgres.app on macOS works)
   - R 4.0+ with: `install.packages(c("httr2", "jsonlite", "dplyr", "purrr", "readr", "DBI", "RPostgres", "ggplot2", "tidyr"))`
2. Set up the database:
   ```bash
   createdb nhl
   psql -d nhl -f data_pipeline/sql/schema.sql
   psql -d nhl -f data_pipeline/sql/views.sql
   
Knit data_pipeline/01_fetch_games.Rmd to fetch ~3,900 games from the NHL API (~5 minutes).

Knit data_pipeline/02_load_postgres.Rmd to load the CSV into the games table.

Knit analysis/04_slice.Rmd to reproduce every figure and regression in this project.

## Limitations:
Sample size: 3 seasons is too few for high statistical power. A null slope with SE ≈ 0.24 cannot rule out moderate tanking; it can only say we didn't find it at this scale.

Playoff classification: top-16-by-points approximates the actual playoff field, which uses a division + wild-card system. Misclassifies ~1–2 teams per season.

Quality baseline contamination: pre-deadline points% as the quality baseline is partially contaminated by any tanking that began before the deadline. A frozen pre-deadline xG-differential would be better and more credible.

## What I'd do next

Expand to 10+ seasons (2014-15 onward, post lottery reform) for ~320 team-seasons.
Add roster-quality controls: man-games-lost-to-scratch for top-6 forwards, starting-goalie xG-against. I understand that tanking is a front-office act (trades, scratches, AHL call-ups), not an on-ice one. Hockey is very multi-faceted and there were many variables that I failed to consider.

I will use xG-differential as a frozen quality baseline instead of points%. Refine playoff classification to match the actual division + wild-card structure.

## Tech stack
PostgreSQL 18 · R 4.6 (httr2, dplyr, ggplot2, RPostgres, DBI) · Power BI Desktop · RMarkdown

## Author
Lucas Duan - lucas.duan@mail.utoronto.ca
