ALTER TABLE wells ADD COLUMN to_report BOOLEAN DEFAULT TRUE NOT NULL;
ALTER TABLE summaries ADD COLUMN to_report BOOLEAN;

