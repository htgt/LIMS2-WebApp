INSERT INTO roles (name)
VALUES ('admin'),('edit'),('read');

-- test_user has password 'ahdooS1e'
INSERT INTO users (name,password) VALUES ('test_user@example.org','{SSHA}yXvorbcq7J+gx0zvVZxlOKmmFRbOWjDn');

INSERT INTO user_role (user_id,role_id)
SELECT users.id, roles.id
FROM users, roles
WHERE users.name = 'test_user@example.org' AND roles.name IN ('read', 'edit');

SET ROLE lims2_test_admin;
DROP ROLE IF EXISTS "test_user@example.org";
CREATE ROLE "test_user@example.org" WITH NOLOGIN INHERIT IN ROLE lims2_test_rw;
GRANT "test_user@example.org" TO lims2_test_webapp;
RESET ROLE;

-- admin_user has password 'Quegohs0'
INSERT INTO users( name, password ) VALUES ( 'admin_user@example', '{SSHA}xtpaBEcAxXFwWSJAQ3hN/gAMfIXP5jS9' );

INSERT INTO user_role (user_id, role_id)
SELECT users.id, roles.id FROM users, roles WHERE users.name='admin_user@sanger.ac.uk';

SET ROLE lims2_test_admin;
DROP ROLE IF EXISTS "admin_user@example.org";
CREATE ROLE "admin_user@example.org" WITH NOLOGIN INHERIT IN ROLE lims2_test_rw;
GRANT "admin_user@example.org" TO lims2_test_webapp;
RESET ROLE;

