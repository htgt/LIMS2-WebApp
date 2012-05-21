
        
CREATE ROLE "lims2_test_admin" NOLOGIN NOINHERIT;
CREATE ROLE "lims2_test_rw" NOLOGIN NOINHERIT;
CREATE ROLE "lims2_test_ro" NOLOGIN NOINHERIT;
CREATE ROLE "lims2_test_webapp" WITH ENCRYPTED PASSWORD 'fjWfMnXQvBrX' LOGIN NOINHERIT IN ROLE "lims2_test_ro";
CREATE ROLE "lims2_test_webapp_ro" WITH ENCRYPTED PASSWORD 'JmAggr7e8UMD' LOGIN INHERIT IN ROLE "lims2_test_ro";
CREATE ROLE "lims2_test_task" WITH ENCRYPTED PASSWORD 'UfJXjYTY65X1' LOGIN INHERIT IN ROLE "lims2_test_rw";

GRANT "lims2_test_rw" TO "rm7@sanger.ac.uk";
GRANT "rm7@sanger.ac.uk" TO "lims2_test_webapp";
GRANT "lims2_test_rw" TO "sp12@sanger.ac.uk";
GRANT "sp12@sanger.ac.uk" TO "lims2_test_webapp";

GRANT "lims2_test_admin" TO "rm7";
GRANT "lims2_test_ro" TO "rm7";
GRANT "lims2_test_rw" TO "rm7";
GRANT "lims2_test_admin" TO "sp12";
GRANT "lims2_test_ro" TO "sp12";
GRANT "lims2_test_rw" TO "sp12";
