INSERT INTO schema_versions(version) VALUES (136);
UPDATE users SET first_login = FALSE WHERE id < 488;
UPDATE users SET first_login = FALSE WHERE name = 'test_user@example.org';
