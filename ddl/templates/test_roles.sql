CREATE ROLE "[% test_admin_role %]" WITH NOLOGIN NOINHERIT;
CREATE ROLE "[% test_role       %]" WITH ENCRYPTED PASSWORD '[% test_passwd      %]' LOGIN INHERIT IN ROLE "[% rw_role %]";

GRANT "[% test_admin_role %]" TO "[% test_role       %]";
GRANT "[% admin_role      %]" TO "[% test_admin_role %]";
GRANT "[% ro_role         %]" TO "[% webapp_role     %]";

GRANT "test_user@example.org" TO "[% webapp_role  %]";
GRANT "admin_user@example.org" TO "[% webapp_role %]";

GRANT "[% rw_role %]" TO "test_user@example.org";
GRANT "[% rw_role %]" TO "admin_user@example.org";
