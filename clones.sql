WITH piq_plates AS (
        SELECT * FROM plates WHERE type_id = 'PIQ'
     ),
     wells_in_piq_plates AS (
        SELECT * FROM wells JOIN piq_plates ON wells.plate_id = piq_plates.id
     )
SELECT * FROM wells_in_piq_plates;
