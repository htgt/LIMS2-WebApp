CREATE TABLE miseq_plate (
    id SERIAL PRIMARY KEY,
    plate_id INTEGER REFERENCES plates(id) NOT NULL,
    run_id INTEGER,
    is_384 BOOLEAN NOT NULL,
    results_available BOOLEAN DEFAULT FALSE
);

CREATE TABLE miseq_well_experiment (
    id SERIAL PRIMARY KEY,
    well_id INTEGER REFERENCES wells(id) NOT NULL,
    miseq_exp_id INTEGER REFERENCES miseq_experiment(id) NOT NULL,
    classification TEXT REFERENCES miseq_classification(id),
    frameshifted BOOLEAN DEFAULT FALSE,
    status TEXT REFERENCES miseq_status NOT NULL
);
