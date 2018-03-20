INSERT INTO messages (message, created_date, expiry_date, priority, lims) VALUES
    ('Experiments now have trivial names for easy labelling', 
        now(), now() + interval '7' day, 'normal', 't');
