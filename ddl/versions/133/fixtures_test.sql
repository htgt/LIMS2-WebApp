DO $$
DECLARE
    _col varchar;
    _row varchar;
    _fp varchar;
    _id integer;
    _well varchar;
BEGIN
    _fp := 'Miseq_004_FP';
    INSERT INTO plates (name, type_id, created_by_id, species_id) VALUES (_fp, 'FP', 432, 'Human');
    SELECT id INTO _id FROM plates WHERE name = _fp;
    RAISE NOTICE 'PlateID: %', _id;
    FOR ro IN 65..80 LOOP
        _row := chr(ro);
        FOR co IN 1..24 LOOP
            _col := co;
            IF (co < 10) THEN
                _col := '0' || _col;
            END IF;
            _well := _row || _col;
            INSERT INTO wells (plate_id, name, created_by_id) VALUES (_id, _well, 432);
        END LOOP;
    END LOOP;
    RETURN;
END; $$
