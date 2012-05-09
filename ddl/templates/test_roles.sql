CREATE ROLE "[% test_admin_role %]" WITH NOLOGIN NOINHERIT;
CREATE ROLE "[% test_role       %]" WITH ENCRYPTED PASSWORD '[% test_passwd      %]' LOGIN INHERIT IN ROLE "[% rw_role %]";

GRANT "[% test_admin_role %]" TO "[% test_role       %]";
GRANT "[% admin_role      %]" TO "[% test_admin_role %]";
