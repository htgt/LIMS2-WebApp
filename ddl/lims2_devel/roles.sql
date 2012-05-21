
        
CREATE ROLE "lims2_devel_admin" NOLOGIN NOINHERIT;
CREATE ROLE "lims2_devel_rw" NOLOGIN NOINHERIT;
CREATE ROLE "lims2_devel_ro" NOLOGIN NOINHERIT;
CREATE ROLE "lims2_devel_webapp" WITH ENCRYPTED PASSWORD 'ilgexmYeojd9' LOGIN NOINHERIT IN ROLE "lims2_devel_ro";
CREATE ROLE "lims2_devel_webapp_ro" WITH ENCRYPTED PASSWORD 'VUSybNGoSAih' LOGIN INHERIT IN ROLE "lims2_devel_ro";
CREATE ROLE "lims2_devel_task" WITH ENCRYPTED PASSWORD 'QXsNMvLz6sJ1' LOGIN INHERIT IN ROLE "lims2_devel_rw";

GRANT "lims2_devel_rw" TO "rm7@sanger.ac.uk";
GRANT "rm7@sanger.ac.uk" TO "lims2_devel_webapp";
GRANT "lims2_devel_rw" TO "sp12@sanger.ac.uk";
GRANT "sp12@sanger.ac.uk" TO "lims2_devel_webapp";

GRANT "lims2_devel_admin" TO "rm7";
GRANT "lims2_devel_ro" TO "rm7";
GRANT "lims2_devel_rw" TO "rm7";
GRANT "lims2_devel_admin" TO "sp12";
GRANT "lims2_devel_ro" TO "sp12";
GRANT "lims2_devel_rw" TO "sp12";
