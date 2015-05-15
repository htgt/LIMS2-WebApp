CREATE TABLE crispr_plate_appends_type (
       id   VARCHAR(32) NOT NULL,
       PRIMARY KEY(id)
);

CREATE TABLE crispr_plate_appends (
       plate_id INTEGER NOT NULL REFERENCES plates(id),
       append_id VARCHAR(32) NOT NULL REFERENCES crispr_plate_appends_type(id),
       PRIMARY KEY(plate_id)
);
