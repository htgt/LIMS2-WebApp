
        
CREATE ROLE "lims2_staging_admin" NOLOGIN NOINHERIT;
CREATE ROLE "lims2_staging_rw" NOLOGIN NOINHERIT;
CREATE ROLE "lims2_staging_ro" NOLOGIN NOINHERIT;
CREATE ROLE "lims2_staging_webapp" WITH ENCRYPTED PASSWORD 'cxjkBaL7puC7' LOGIN NOINHERIT IN ROLE "lims2_staging_ro";
CREATE ROLE "lims2_staging_webapp_ro" WITH ENCRYPTED PASSWORD 'VFJO7BINbSXX' LOGIN INHERIT IN ROLE "lims2_staging_ro";
CREATE ROLE "lims2_staging_task" WITH ENCRYPTED PASSWORD 'K2V4BEv95jdn' LOGIN INHERIT IN ROLE "lims2_staging_rw";

GRANT "lims2_staging_rw" TO "rm7@sanger.ac.uk";
GRANT "rm7@sanger.ac.uk" TO "lims2_staging_webapp";
GRANT "lims2_staging_rw" TO "sp12@sanger.ac.uk";
GRANT "sp12@sanger.ac.uk" TO "lims2_staging_webapp";

GRANT "lims2_staging_admin" TO "rm7";
GRANT "lims2_staging_ro" TO "rm7";
GRANT "lims2_staging_rw" TO "rm7";
GRANT "lims2_staging_admin" TO "sp12";
GRANT "lims2_staging_ro" TO "sp12";
GRANT "lims2_staging_rw" TO "sp12";
