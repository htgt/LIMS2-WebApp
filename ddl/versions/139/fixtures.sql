INSERT INTO trivial_offset (gene_id, index_offset) VALUES 
    --these have experiments on both a crispr pair as well as on crisprs.
    --the ones with crisprs, have, in these cases, been already assigned trivial
    --names even though the crispr pair ones logically come first.
    --give the crispr pair experiments an index of 0.
    ('HGNC:172', -1), --ACVR1B
    ('HGNC:950', -1), --BAP1
    ('HGNC:1509', -1), --CASP8
    ('HGNC:1748', -1), --CDH1
    ('HGNC:2348', -1), --CREBBP
    ('HGNC:3373', -1), --EP300
    ('HGNC:4591', -1), --ARHGAP35
    ('HGNC:6770', -1), --SMAD4
    ('HGNC:9588', -1), --PTEN
    ('HGNC:10519', -1), --SACS
    ('HGNC:11100', -1), --SMARCA4
    ('HGNC:12637', -1), --KDM6A
    ('HGNC:12687', -1), --VHL
    ('HGNC:13723', -1), --CTCF
    ('HGNC:13726', -1), --KMT2C
    ('HGNC:14010', -1), --MGA
    ('HGNC:17810', -1), --AMOT
    ('HGNC:18040', -1), --ARID1B
    ('HGNC:18420', -1), --SETD2
    ('HGNC:18505', -1), --RNF43
    --as above, but a single crispr group rather than a pair
    ('HGNC:1338', -1), --C5AR1
    ('HGNC:1785', -1), --CDKN1B
    ('HGNC:3823', -1), --FOXP1
    ('HGNC:24283', -1), --KMT2D
    ('HGNC:9772', -1), --RAB32
    ('HGNC:9896', -1), --RBM10
    ('HGNC:11389', -1), --STK11
    --for these genes the assigned trivial names start > 1, adjust accordingly.
    ('HGNC:29187', 2), --SETD1B
    ('HGNC:29357', 2); --ASXL3


INSERT INTO trivial_offset (gene_id, crispr_id, index_offset) VALUES
    ('HGNC:2348', 190155, -1), --CREBBP
    --these have experiments with null designs, and also spreadsheet entries that want
    --design rank 1. force them first.
    ('HGNC:5009', 227708, -1), --HGMA2
    ('HGNC:5009', 225823, -1),
    ('HGNC:7000', 227705, -1), --MEIS1
    ('HGNC:7000', 227706, -1),
    ('HGNC:6107', 227707, -1), --PDX1
    ('HGNC:6107', 200293, -1),
    ('HGNC:11998', 186034, -1); --TP53

INSERT INTO trivial_backfill(gene_id, crispr_id, index) VALUES
    ('HGNC:11110', 187461, 1), --ARID1A
    ('HGNC:21498', 227988, 1), --ATG16L1
    ('HGNC:1919', 228055, 1), --CHD4
    ('HGNC:5009', 227708, 1), --HMGA2
    ('HGNC:5009', 225823, 2),
    ('HGNC:7133', 228032, 1), --KMT2D
    ('HGNC:7133', 228010, 2),
    ('HGNC:7000', 227705, 1), --MEIS1
    ('HGNC:7000', 227706, 2),
    ('HGNC:7881', 227833, 1), --NOTCH1
    ('HGNC:7881', 191668, 2),
    ('HGNC:6107', 227707, 1), --PDX1
    ('HGNC:6107', 200293, 2),
    ('HGNC:11204', 227838, 1), --SOX9
    ('HGNC:11634', 227994, 1), --TCF4
    ('HGNC:11634', 204047, 2),
    ('HGNC:11998', 186034, 1); --TP53
INSERT INTO trivial_backfill(gene_id, crispr_id, design_id, index) VALUES
    ('HGNC:9896', 227964, 1016539, 1), --RBM10
    ('HGNC:9896', 227964, 1016538, 2);
