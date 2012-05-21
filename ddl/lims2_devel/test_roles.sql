
        
CREATE ROLE "lims2_devel_test_admin" WITH NOLOGIN NOINHERIT;
CREATE ROLE "lims2_devel_test" WITH ENCRYPTED PASSWORD 'E0fs7sYm1rKw' LOGIN INHERIT IN ROLE "lims2_devel_rw";

GRANT "lims2_devel_test_admin" TO "lims2_devel_test";
GRANT "lims2_devel_admin" TO "lims2_devel_test_admin";
