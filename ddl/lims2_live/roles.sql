
        
CREATE ROLE "lims2_live_admin" NOLOGIN NOINHERIT;
CREATE ROLE "lims2_live_rw" NOLOGIN NOINHERIT;
CREATE ROLE "lims2_live_ro" NOLOGIN NOINHERIT;
CREATE ROLE "lims2_live_webapp" WITH ENCRYPTED PASSWORD '3Udg2bhzeG5q' LOGIN NOINHERIT IN ROLE "lims2_live_ro";
CREATE ROLE "lims2_live_webapp_ro" WITH ENCRYPTED PASSWORD 'eIpCbK5GiLnE' LOGIN INHERIT IN ROLE "lims2_live_ro";
CREATE ROLE "lims2_live_task" WITH ENCRYPTED PASSWORD 'IfuqUIrrEGaE' LOGIN INHERIT IN ROLE "lims2_live_rw";

GRANT "lims2_live_rw" TO "rm7@sanger.ac.uk";
GRANT "rm7@sanger.ac.uk" TO "lims2_live_webapp";
GRANT "lims2_live_rw" TO "sp12@sanger.ac.uk";
GRANT "sp12@sanger.ac.uk" TO "lims2_live_webapp";

GRANT "lims2_live_admin" TO "rm7";
GRANT "lims2_live_ro" TO "rm7";
GRANT "lims2_live_rw" TO "rm7";
GRANT "lims2_live_admin" TO "sp12";
GRANT "lims2_live_ro" TO "sp12";
GRANT "lims2_live_rw" TO "sp12";
