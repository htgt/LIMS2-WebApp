CREATE TABLE cached_reports (
       id           CHAR(36) PRIMARY KEY,
       report_class TEXT NOT NULL,
       params       TEXT NOT NULL,
       expires      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP + INTERVAL '8 hours',
       complete     BOOLEAN NOT NULL DEFAULT FALSE
);
GRANT SELECT ON cached_reports TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON cached_reports TO "[% rw_role %]";
CREATE INDEX cached_reports_report_class_params_idx ON cached_reports(report_class,params);

-- Intentionally no audit for cached_reports.
