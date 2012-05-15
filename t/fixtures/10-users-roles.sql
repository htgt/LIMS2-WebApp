INSERT INTO roles (name)
VALUES ('admin'),('edit'),('read');

-- test_user has password 'ahdooS1e'
INSERT INTO users (name,password) VALUES ('test_user@example.org','{SSHA}yXvorbcq7J+gx0zvVZxlOKmmFRbOWjDn');

INSERT INTO user_role (user_id,role_id)
SELECT users.id, roles.id
FROM users, roles
WHERE users.name = 'test_user@example.org' AND roles.name = 'edit';
