INSERT INTO schema_versions(version) VALUES (136);
UPDATE users SET first_login = FALSE WHERE id < 488;
