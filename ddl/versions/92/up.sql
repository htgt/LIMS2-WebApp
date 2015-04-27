CREATE TABLE process_parameters(
        process_id integer not null REFERENCES processes(id),
        parameter_name text not null,
        parameter_value text,
        unique (process_id, parameter_name)
);