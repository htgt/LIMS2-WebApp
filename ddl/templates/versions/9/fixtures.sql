INSERT INTO schema_versions(version)
VALUES (9);

UPDATE cassettes SET conditional = TRUE
WHERE name IN (
 'Ifitm2_intron_L1L2_GT0_LF2A_LacZ_BetactP_neo',
 'Ifitm2_intron_L1L2_GT1_LF2A_LacZ_BetactP_neo',
 'Ifitm2_intron_L1L2_GT2_LF2A_LacZ_BetactP_neo',
 'Ifitm2_intron_L1L2_GTK_LacZ_BetactP_neo',
 'Ifitm2_intron_R1_ZeoPheS_R2',
 'L1L2_Bact_EM7',
 'L1L2_Bact_P',
 'L1L2_gt0',
 'L1L2_gt0_Del_LacZ',
 'L1L2_GT0_LacZ_BSD',
 'L1L2_GT0_LF2A_LacZ_BetactP_neo',
 'L1L2_gt1',
 'L1L2_gt1_Del_LacZ',
 'L1L2_GT1_LacZ_BSD',
 'L1L2_GT1_LF2A_LacZ_BetactP_neo',
 'L1L2_gt2',
 'L1L2_gt2_Del_LacZ',
 'L1L2_GT2_LacZ_BSD',
 'L1L2_GT2_LF2A_LacZ_BetactP_neo',
 'L1L2_gtk',
 'L1L2_GTK_LacZ_BSD',
 'pL1L2_frt15_BetactinBSD_frt14_neo_Rox',
 'pL1L2_GT0_bsd_frt15_neo_barcode',
 'pL1L2_GT1_bsd_frt15_neo_barcode',
 'pL1L2_GT2_bsd_frt15_neo_barcode'
);

INSERT INTO sponsors(id,description)
VALUES ( 'Core',        'Homozygous - Core' ),
       ( 'Syboss',      'Homozygous - Syboss' ),
       ( 'Pathogens',   'Homozygous - Pathogens' ),
       ( 'Cre Knockin', 'EUCOMMTools-Cre Knockin' ),
       ( 'Cre BAC',     'EUCOMMTools-Cre BAC' ),
       ( 'Human',       'Homozygous - Human' );
