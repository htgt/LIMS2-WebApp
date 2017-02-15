ALTER TABLE summaries ADD COLUMN requester TEXT;

CREATE TABLE requesters (
    id text primary key
);

ALTER TABLE experiments ADD COLUMN requester TEXT REFERENCES requesters(id);

ALTER TABLE miseq_projects ADD COLUMN run_id INTEGER;
