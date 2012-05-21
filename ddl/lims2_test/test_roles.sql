
        
CREATE ROLE "lims2_test_test_admin" WITH NOLOGIN NOINHERIT;
CREATE ROLE "lims2_test_test" WITH ENCRYPTED PASSWORD '33RyehG9x0JX' LOGIN INHERIT IN ROLE "lims2_test_rw";

GRANT "lims2_test_test_admin" TO "lims2_test_test";
GRANT "lims2_test_admin" TO "lims2_test_test_admin";
