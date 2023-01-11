WITH piq_plates AS (SELECT * FROM plates WHERE type_id = 'PIQ')
SELECT * FROM wells JOIN piq_plates ON wells.plate_id = piq_plates.id;
