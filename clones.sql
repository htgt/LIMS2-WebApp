WITH piq_plates AS (
        SELECT id FROM plates WHERE type_id = 'PIQ'
     ),
     wells_in_piq_plates AS (
        SELECT wells.id AS id FROM wells JOIN piq_plates ON wells.plate_id = piq_plates.id
     ),
     wells_in_parent_plates AS (
        SELECT process_output_well.well_id AS id
        FROM process_output_well
        JOIN processes ON processes.id = process_output_well.process_id
        JOIN process_input_well ON processes.id = process_input_well.process_id
        WHERE process_input_well.well_id IN (SELECT id FROM wells_in_piq_plates)
     )
SELECT * FROM wells_in_parent_plates;
