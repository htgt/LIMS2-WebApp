ALTER TABLE cell_lines ADD COLUMN description text;

CREATE TABLE cell_line_repositories (
    id text PRIMARY KEY
);

CREATE TABLE cell_line_external (
    id serial PRIMARY KEY NOT NULL,
    cell_line_id INTEGER NOT NULL REFERENCES cell_lines(id),
    remote_identifier text NOT NULL,
    repository text NOT NULL REFERENCES cell_line_repositories(id),
    url text NOT NULL
);

CREATE TABLE cell_line_internal (
    id serial PRIMARY KEY NOT NULL,
    cell_line_id INTEGER UNIQUE NOT NULL REFERENCES cell_lines(id),
    origin_well_id INTEGER NOT NULL REFERENCES wells(id),
    unique_identifier VARCHAR(4) UNIQUE
);

CREATE SEQUENCE cell_line_seq;

CREATE OR REPLACE FUNCTION alphanumeric (val int, _string text)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    _chars text = '0123456789ABCDEFGHIJKLMNPQRSTUVWXYZ';
    _modVal int;
    _divVal int;
    _charsLen int = length(_chars);
    _currChar varchar(1);
BEGIN
    IF val >= _charsLen THEN
        _divVal := val / _charsLen;
        SELECT alphanumeric FROM alphanumeric(_divVal, _string) INTO _string;
    END IF;

    _modVal := val % _charsLen;
    _currChar := substring(_chars, _modVal + 1, 1);
    _string := _string || _currChar;

    RETURN _string;
END $$;

CREATE OR REPLACE FUNCTION cell_line_identifier()
RETURNS trigger
LANGUAGE plpgsql
AS $cell_line_identifier$
DECLARE
    _nextVal int = nextval('cell_line_seq');
    _identifier text;
BEGIN
    SELECT LPAD(alphanumeric::text, 2, '0') FROM alphanumeric(_nextVal, '') INTO _identifier;
    NEW.unique_identifier := _identifier;
    RETURN NEW;
END $cell_line_identifier$;

CREATE TRIGGER cell_line_identifier BEFORE INSERT ON cell_line_internal
    FOR EACH ROW EXECUTE PROCEDURE cell_line_identifier();
