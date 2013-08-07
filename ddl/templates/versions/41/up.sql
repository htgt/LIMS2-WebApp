CREATE TABLE gene_types (
    id                    TEXT PRIMARY KEY,
    description           TEXT,
    local                 BOOL
);
GRANT SELECT ON gene_types TO "[% ro_role %]";
GRANT SELECT, INSERT, UPDATE, DELETE ON gene_types TO "[% rw_role %]";

INSERT INTO gene_types ( id, description, local )
VALUES ( 'MGI', 'MGI Accession ID ( Mouse Genome Informatics )', 'f' ),
       ( 'HGNC', 'HGNC ID ( HUGO Gene Nomenclature Committee )', 'f' ),
       ( 'enhancer-region', 'Enhancer Region ID', 'y' ),
       ( 'CPG-island', 'CPG Island ID', 'y' ),
       ( 'miRBase', 'miRNA id ( miRBase )', 'f' ),
       ( 'marker-symbol', 'Gene marker symbol', 'f');

-- can only set column to NOT NULL once I have filled in data
ALTER TABLE gene_design ALTER COLUMN local SET NOT NULL;

ALTER TABLE gene_design ADD gene_type_id TEXT REFERENCES gene_types(id);

-- disable audit triggers on gene_design table
ALTER TABLE gene_design DISABLE TRIGGER gene_design_audit;

UPDATE gene_design
SET gene_type_id = ( CASE
WHEN gene_id LIKE 'MGI%' THEN 'MGI'
WHEN gene_id LIKE 'HGNC%' THEN 'HGNC'
WHEN gene_id LIKE 'LBL%' THEN 'enhancer-region'
WHEN gene_id LIKE 'CGI%' THEN 'CPG-island'
WHEN gene_id LIKE 'mmu%' THEN 'miRBase'
ELSE 'marker-symbol' END);

-- can only set column to NOT NULL once I have filled in data
ALTER TABLE gene_design ALTER COLUMN gene_type_id SET NOT NULL;

-- enable trigger
ALTER TABLE gene_design ENABLE TRIGGER gene_design_audit;
