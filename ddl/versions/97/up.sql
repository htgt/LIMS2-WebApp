CREATE TABLE well_het_status (
    well_id INT PRIMARY KEY REFERENCES wells(id),
    five_prime BOOLEAN NOT NULL DEFAULT FALSE,
    three_prime BOOLEAN NOT NULL DEFAULT FALSE
);
