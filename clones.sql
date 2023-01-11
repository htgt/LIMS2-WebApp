WITH piq_plates AS (
        SELECT id FROM plates WHERE type_id = 'PIQ'
     ),
     wells_in_piq_plates AS (
        SELECT wells.id AS id FROM wells JOIN piq_plates ON wells.plate_id = piq_plates.id
     )
SELECT * FROM wells_in_piq_plates;
