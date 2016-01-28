ALTER TABLE sponsors ADD COLUMN abbr text;
ALTER TABLE sponsors ADD UNIQUE (abbr);