ALTER TABLE audit.users ADD COLUMN access_key character(36);
ALTER TABLE audit.users ADD COLUMN secret_key character(67);
