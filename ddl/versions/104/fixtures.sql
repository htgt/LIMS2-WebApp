INSERT INTO schema_versions(version) VALUES (104);

INSERT INTO design_types(id) VALUES('fusion-deletion');

INSERT INTO design_oligo_types(id) VALUES('f5F'),('f3R');

INSERT INTO design_oligo_appends(id, design_oligo_type_id, seq)
    VALUES ('artificial-intron','G3','CCACTGGCCGTCGTTTTACA'),
    ('artificial-intron','G5','TCCTGTGTGAAATTGTTATCCGC'),
    ('artificial-intron','D3','TGAACTGATGGCGAGCTCAGACC'),
    ('artificial-intron','U3','CTGAAGGAAATTAGATGTAAGGAGC'),
    ('artificial-intron','D5','GAGATGGCGCAACGCAATTAATG'),
    ('artificial-intron','U5','GTGAGTGTGCTAGAGGGGGTG'),
    ('standard-ko','G5','TCCTGTGTGAAATTGTTATCCGC'),
    ('standard-ko','G3','CCACTGGCCGTCGTTTTACA'),
    ('standard-ko','U5','AAGGCGCATAACGATACCAC'),
    ('standard-ko','U3','CCGCCTACTGCGACTATAGA'),
    ('standard-ko','D5','GAGATGGCGCAACGCAATTAATG'),
    ('standard-ko','D3','TGAACTGATGGCGAGCTCAGACC'),
    ('standard-insdel','G5','TCCTGTGTGAAATTGTTATCCGC'),
    ('standard-insdel','G3','CCACTGGCCGTCGTTTTACA'),
    ('standard-insdel','U5','AAGGCGCATAACGATACCAC'),
    ('standard-insdel','D3','CCGCCTACTGCGACTATAGA'),
    ('gibson','5F','AACGACGGCCAGTGAATTCGAT'),
    ('gibson','5R','TATCGTTATGCGCCTTGAT'),
    ('gibson','EF','TAGTCGCAGTAGGCGGAAGA'),
    ('gibson','ER','AGCCAATTGGCGGCCGAAGA'),
    ('gibson','3F','CTGAGCTAGCCATCAGTGAT'),
    ('gibson','3R','CCATGATTACGCCAAGCTTGAT'),
    ('fusion','f5F','GCCAGTGAATTCGAT'),
    ('fusion','f3R','TACGCCAAGCTTGAT'),
    ('fusion','U5','AAGGCGCATAACGATACCAC'),
    ('fusion','D3','CCGCCTACTGCGACTATAGA'),
    ('global-shortened','G5','ACAACTTATATCGTATGGGGC'),
    ('global-shortened','G3','TTACGCCCCGCCCTGCCACTC');


