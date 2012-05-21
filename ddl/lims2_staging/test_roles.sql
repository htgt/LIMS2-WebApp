
        
CREATE ROLE "lims2_staging_test_admin" WITH NOLOGIN NOINHERIT;
CREATE ROLE "lims2_staging_test" WITH ENCRYPTED PASSWORD 'vTnpa0MTXeoX' LOGIN INHERIT IN ROLE "lims2_staging_rw";

GRANT "lims2_staging_test_admin" TO "lims2_staging_test";
GRANT "lims2_staging_admin" TO "lims2_staging_test_admin";
