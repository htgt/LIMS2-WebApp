/* Add strategy to project */

CREATE TABLE strategies (
    id TEXT PRIMARY KEY,
    description TEXT
);

ALTER TABLE projects ADD COLUMN strategy_id TEXT REFERENCES strategies(id);