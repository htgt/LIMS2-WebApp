CREATE TABLE priorities (
    id text primary key
);

CREATE TABLE message (
    id serial primary key NOT NULL,
    message text,
    created_date timestamp with time zone,
    expiry_date timestamp with time zone,
    priority text references priorities(id),
    wge bool default '0',
    lims bool default '0',
    htgt bool default '0'
);

