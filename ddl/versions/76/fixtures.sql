INSERT INTO schema_versions(version) VALUES (76);

INSERT INTO barcode_states(id,description) values
('checked_out','checked out of freezer'),
('in_freezer','in a rack in the freezer'),
('discarded','destroyed, see comment field for reason - tube no longer exists'),
('frozen_back', 'FP wells that have been frozen back into PIQs - tube no longer exists'),
('sent_out','PIQ wells that have been sent out, e.g. to CGAP, tube no longer exists at Sanger')

