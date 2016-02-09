INSERT INTO schema_versions(version) VALUES (110);

INSERT INTO dna_templates VALUES
    ('BOB'),
    ('KOLF2');

UPDATE processes SET dna_template = 'KOLF2' WHERE type_id = 'int_recom' AND id IN ( 
    SELECT DISTINCT COALESCE( process_input_well.process_id, process_output_well.process_id )
    FROM process_input_well
    FULL OUTER JOIN process_output_well
    ON process_input_well.process_id=process_output_well.process_id
    WHERE process_input_well.well_id IN (
        SELECT id FROM wells WHERE plate_id IN (
            SELECT id FROM plates WHERE name similar to 'HINT001\d\S*'
        )
    )
    OR process_output_well.well_id IN (
        SELECT id FROM wells WHERE plate_id IN (
            SELECT id FROM plates WHERE name similar to 'HINT001\d\S*'
        )
    )
);

UPDATE processes SET dna_template = 'BOB' WHERE type_id = 'int_recom' AND id IN ( 
    SELECT DISTINCT COALESCE( process_input_well.process_id, process_output_well.process_id )
    FROM process_input_well
    FULL OUTER JOIN process_output_well
    ON process_input_well.process_id=process_output_well.process_id
    WHERE process_input_well.well_id IN (
        SELECT id FROM wells WHERE plate_id IN (
            SELECT id FROM plates WHERE name similar to 'HINT000\d\S*'
        )
    )
    OR process_output_well.well_id IN (
        SELECT id FROM wells WHERE plate_id IN (
            SELECT id FROM plates WHERE name similar to 'HINT000\d\S*'
        )
    )
);

UPDATE summaries SET dna_template = 'KOLF2' WHERE int_plate_name similar to 'HINT001\d\S*';

UPDATE summaries SET dna_template = 'BOB' WHERE int_plate_name similar to 'HINT000\d\S*';
