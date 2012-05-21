
        
CREATE ROLE "lims2_live_test_admin" WITH NOLOGIN NOINHERIT;
CREATE ROLE "lims2_live_test" WITH ENCRYPTED PASSWORD 'H6soxoL61tFG' LOGIN INHERIT IN ROLE "lims2_live_rw";

GRANT "lims2_live_test_admin" TO "lims2_live_test";
GRANT "lims2_live_admin" TO "lims2_live_test_admin";
