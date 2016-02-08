INSERT INTO schema_versions(version) VALUES (110);

INSERT INTO dna_templates VALUES
    ('BOB'),
    ('KOLF2');

UPDATE processes SET dna_template = 'KOLF2' WHERE id IN ( 
    SELECT DISTINCT COALESCE( process_input_well.process_id, process_output_well.process_id )
    FROM process_input_well
    FULL OUTER JOIN process_output_well
    ON process_input_well.process_id=process_output_well.process_id
    WHERE process_input_well.process_id IN (
        SELECT id FROM wells WHERE plate_id IN ('8871','9274','10434','10513')
    )
    OR process_output_well.process_id IN (
        SELECT id FROM wells WHERE plate_id IN ('8871','9274','10434','10513')
    )
);

UPDATE processes SET dna_template = 'BOB' WHERE id IN ( 
    SELECT DISTINCT COALESCE( process_input_well.process_id, process_output_well.process_id )
    FROM process_input_well
    FULL OUTER JOIN process_output_well
    ON process_input_well.process_id=process_output_well.process_id
    WHERE process_input_well.process_id IN (
        SELECT id FROM wells WHERE plate_id IN ('5995','6458','6678','6983','7453','7551','7768','8408','10433')
    )
    OR process_output_well.process_id IN (
        SELECT id FROM wells WHERE plate_id IN ('5995','6458','6678','6983','7453','7551','7768','8408','10433')
    )
);

UPDATE summaries SET dna_template = 'KOLF2' WHERE design_plate_name IN ('HG10','HG11','HG12','HG13','HG15');

UPDATE summaries SET dna_template = 'BOB' WHERE design_plate_name IN ('HG1','HG2','HG3','HG4','HG5','HG6','HG7','HG8','HG9','HG14');
