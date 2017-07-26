INSERT INTO schema_versions(version) VALUES (132);

INSERT INTO plate_types VALUES ('MISEQ','MiSEQ QC Plate');

INSERT INTO process_types VALUES ('miseq_oligo','Create miseq plate with oligo for HDR events');
INSERT INTO process_types VALUES ('miseq_vector','Create miseq plate with vector for HDR events');
INSERT INTO process_types VALUES ('miseq_no_template','Create miseq plate for analysis of NHEJ events only');

DO $$
DECLARE
    _col varchar;
    _row varchar;
    _fp varchar;
    _id integer;
    _well varchar;
    _wellRS varchar;
BEGIN
    FOR fp IN 1..13 LOOP
        _fp := 'MiSeq_TT_FP_' || fp;
        INSERT INTO plates (name, type_id, created_by_id, species_id) VALUES (_fp, 'FP', 432, 'Human');
        SELECT id INTO _id FROM plates WHERE name = _fp;
        RAISE NOTICE 'PlateID: %', _id;
        FOR ro IN 65..72 LOOP
            _row := chr(ro);
            FOR co IN 1..12 LOOP
                _col := co;
                IF (co < 10) THEN
                    _col := '0' || _col;
                END IF;
                _well := _row || _col;
                INSERT INTO wells (plate_id, name, created_by_id) VALUES (_id, _well, 432);
            END LOOP;
        END LOOP;
    END LOOP;
    RETURN;
END; $$
