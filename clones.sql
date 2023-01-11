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
     ),
     wells_in_freeze_plates AS (
        SELECT wells.id AS well_id,
               wells.name AS well_name,
               plates.id AS plate_id,
               plates.name AS plate_name
        FROM wells_in_parent_plates
        JOIN wells ON wells.id = wells_in_parent_plates.id
        JOIN plates ON plates.id = wells.plate_id
        WHERE plates.type_id = 'FP'
     )
SELECT * FROM wells_in_freeze_plates;
