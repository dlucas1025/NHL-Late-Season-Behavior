DROP TABLE IF EXISTS games;
DROP TABLE IF EXISTS season_structure;

CREATE TABLE season_structure(
    season INTEGER PRIMARY KEY,
    season_label TEXT NOT NULL,
    trade_deadline DATE NOT NULL,
    regular_season_end DATE
);

CREATE TABLE games(
    game_id BIGINT PRIMARY KEY,
    season INTEGER NOT NULL REFERENCES season_structure(season),
    game_date DATE NOT NULL,
    home_team TEXT NOT NULL,
    away_team TEXT NOT NULL,
    home_score INTEGER NOT NULL,
    away_score INTEGER NOT NULL,
    last_period TEXT NOT NULL CHECK (last_period IN('REG', 'OT', 'SO'))
);

CREATE INDEX idx_games_season ON games(season);
CREATE INDEX idx_games_date ON games(game_date);

INSERT INTO season_structure (season, season_label, trade_deadline, regular_season_end) VALUES
    (20212022, '2021-22', '2022-03-21', '2022-04-29'),
    (20222023, '2022-23', '2023-03-03', '2023-04-14'),
    (20232024, '2023-24', '2024-03-08', '2024-04-18');