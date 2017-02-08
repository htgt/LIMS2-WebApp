ALTER TABLE summaries ADD COLUMN requester TEXT;

CREATE TABLE requesters (
    id text primary key
);

ALTER TABLE experiments ADD COLUMN requester TEXT REFERENCES requesters(id);
