CREATE ROLE "[% admin_role     %]" NOLOGIN NOINHERIT;
CREATE ROLE "[% rw_role        %]" NOLOGIN NOINHERIT;
CREATE ROLE "[% ro_role        %]" NOLOGIN NOINHERIT;
CREATE ROLE "[% webapp_role    %]" WITH ENCRYPTED PASSWORD '[% webapp_passwd    %]' LOGIN NOINHERIT IN ROLE "[% ro_role %]";
CREATE ROLE "[% webapp_ro_role %]" WITH ENCRYPTED PASSWORD '[% webapp_ro_passwd %]' LOGIN INHERIT IN ROLE "[% ro_role %]";
CREATE ROLE "[% task_role      %]" WITH ENCRYPTED PASSWORD '[% task_passwd      %]' LOGIN INHERIT IN ROLE "[% rw_role %]";
CREATE ROLE "[% test_role      %]" WITH ENCRYPTED PASSWORD '[% test_passwd      %]' LOGIN INHERIT IN ROLE "[% rw_role %]";

[%- FOR u IN webapp_users %]
GRANT "[% rw_role %]" TO "[% u %]";
GRANT "[% u %]" TO "[% webapp_role %]";
[%- END %]

[%- FOR u IN system_users %]
  [%- FOR r IN [ admin_role ro_role rw_role ] %]
GRANT "[% r %]" TO "[% u %]";
  [%- END %]
[%- END %]
