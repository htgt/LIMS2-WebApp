INSERT INTO assemblies(id)
VALUES ('NCBIM34'), ('NCBIM36'), ('NCBIM37');

INSERT INTO chromosomes (id)
VALUES ('1'), ('2'), ('3'), ('4'), ('5'), ('6'), ('7'), ('8'), ('9'),
       ('10'), ('11'), ('12'), ('13'), ('14'), ('15'), ('16'),
       ('17'), ('18'), ('19'), ('X'), ('Y');

INSERT INTO bac_libraries (id) VALUES ('129'), ('black6');

INSERT INTO design_types(id)
VALUES ('conditional'), ('deletion'), ('insertion'), ('artificial-intron'), ('intron-replacement'), ('cre-bac');

INSERT INTO design_oligo_types(id)
VALUES ('G5'), ('U5'), ('U3'), ('D5'), ('D3'), ('G3');

INSERT INTO process_types(id,description)
VALUES ('create_di', 'Create design instance'),
       ('cre_bac_recom', 'Cre/BAC recombineering'),
       ('int_recom', 'Intermediate recombineering'),
       ('2w_gateway', 'Two-way gateway'),
       ('3w_gateway', 'Three-way gateway'),
       ('rearray', 'rearray wells'),
       ('dna_prep', 'dna prep'),
       ('recombinase', 'apply recombinase');

INSERT INTO recombinases(id)
VALUES ('Cre'),('Flp'),('Dre');

INSERT INTO plate_types(id,description)
VALUES ('DESIGN', 'Design Instances'),
       ('INT', 'Intermediate Vectors' ),
       ('POSTINT', 'Post-intermediate Vectors' ),
       ('FINAL', 'Final Vectors' ),
       ('CREBAC', 'Cre/BAC Vectors' ),
       ('DNA', 'DNA QC' );

INSERT INTO recombineering_result_types(id)
VALUES ('pcr_u'),('pcr_d'),('pcr_g'),('rec_u'),('rec_d'),('rec_g'),('rec_ns'),('rec_result');

INSERT INTO cassettes( name, description, promoter, phase_match_group, phase )
VALUES
( 'Ty1_EGFP', '', TRUE, NULL, NULL ),
( 'Ifitm2_intron_L1L2_GT2_LF2A_LacZ_BetactP_neo', '', TRUE, 'Ifitm2_intron_L1L2_GT?_LF2A_LacZ_BetactP_neo', 2 ),
( 'L1L2_st0', 'Secretory Trap versions  of EUCOMM vector with CD4 Tm domain for targeting secreted/TM loci', FALSE, 'L1L2_st?', NULL ),
( 'L1L2_NTARU-1', '', FALSE, 'L1L2_NTARU-?', 1 ),
( 'L1L2_GT0_LacZ_BSD', '', FALSE, 'L1L2_GT?_LacZ_BSD', NULL ),
( 'L1L2_GT2_LF2A_LacZ_BetactP_neo', '', TRUE, 'L1L2_GT?_LF2A_LacZ_BetactP_neo', 2 ),
( 'L1L2_NTARU-0', '', FALSE, 'L1L2_NTARU-?', NULL ),
( 'pL1L2_GT2_T2A_iCre_KI_Puro', '', TRUE, 'pL1L2_GT?_T2A_iCre_KI_Puro', 2 ),
( 'Ifitm2_intron_L1L2_GT1_LF2A_LacZ_BetactP_neo', '', TRUE, 'Ifitm2_intron_L1L2_GT?_LF2A_LacZ_BetactP_neo', 1 ),
( 'L1L2_GT0_T2A_H2BVenus_PGKPuro_delRsrII_NO_DTA', '', TRUE, 'L1L2_GT?_T2A_H2BVenus_PGKPuro_delRsrII_NO_DTA', 2 ),
( 'B1B2_frame2_Norcomm', '', FALSE, 'B1B2_frame?_Norcomm', 2 ),
( 'Ifitm2_intron_R1_ZeoPheS_R2', '', FALSE, NULL, NULL ),
( 'ZEN-Ub1', '', TRUE, NULL, NULL ),
( 'L1L2_NorCOMM', '', FALSE, NULL, NULL ),
( 'B1B2_framek_Norcomm', '', FALSE, 'B1B2_frame?_Norcomm', -1 ),
( 'L1L2_6XOspnEnh_Bact_P', '', TRUE, NULL, NULL ),
( 'pL1L2_GT2_LF2A_nEGFPO_T2A_CreERT_puro', '', FALSE, 'pL1L2_GT?_LF2A_nEGFPO_T2A_CreERT_puro', 2 ),
( 'L1L2_st1', 'Secretory Trap versions  of EUCOMM vector with CD4 Tm domain for targeting secreted/TM loci', FALSE, 'L1L2_st?', 1 ),
( 'L1L2_GT0_LF2A_LacZ_BetactP_neo', '', TRUE, 'L1L2_GT?_LF2A_LacZ_BetactP_neo', NULL ),
( 'pL1L2_GT0_LF2A_H2BCherry_Puro', '', TRUE, 'pL1L2_GT?_LF2A_H2BCherry_Puro', NULL ),
( 'L1L2_Del_BactPneo_FFL', '', TRUE, NULL, NULL ),
( 'L1L2_GT2_LacZ_BSD', '', FALSE, 'L1L2_GT?_LacZ_BSD', 2 ),
( 'L1L2_NTARU-2', '', FALSE, 'L1L2_NTARU-?', 2 ),
( 'L1L2_gtk', 'K frame contains Kozak/ATG for insertions after 5'' UTR''s', FALSE, 'L1L2_gt?', -1 ),
( 'L1L2_NTARU-K', '', FALSE, 'L1L2_NTARU-?', -1 ),
( 'B1B2_frame1_Norcomm', '', FALSE, 'B1B2_frame?_Norcomm', 1 ),
( 'pL1L2_GT1_bsd_frt15_neo_barcode', '', TRUE, 'pL1L2_GT?_bsd_frt15_neo_barcode', 1 ),
( 'L1L2_gt0', 'Standard EUCOMM promoterless cassettes with T2 sequences in driving independent translation  of lacZ and neo', FALSE, 'L1L2_gt?', NULL ),
( 'pL1L2_GT0_LF2A_nEGFPO_T2A_CreERT_puro', '', FALSE, 'pL1L2_GT?_LF2A_nEGFPO_T2A_CreERT_puro', NULL ),
( 'L1L2_st2', 'Secretory Trap versions  of EUCOMM vector with CD4 Tm domain for targeting secreted/TM loci', FALSE, 'L1L2_st?', 2 ),
( 'pR6K_R1R2_ZP', 'Standard intermediate vector cassette', FALSE, NULL, NULL ),
( 'L1L2_hubi_P', '', TRUE, NULL, NULL ),
( 'L1L2_GOHANU', '', TRUE, NULL, NULL ),
( 'L1L2_Pgk_PM', 'PGK promoter driving mutant  neo.  Frame indendent IRES driven lacZ reporter', TRUE, NULL, NULL ),
( 'pL1L2_GT1_LF2A_nEGFPO_T2A_CreERT_puro', '', FALSE, 'pL1L2_GT?_LF2A_nEGFPO_T2A_CreERT_puro', 1 ),
( 'pL1L2_GT0_T2A_H2BCherry_Puro_delRsrll_NO_DTA', '', TRUE, 'pL1L2_GT?_T2A_H2BCherry_Puro_delRsrll_NO_DTA', NULL ),
( 'pL1L2_GT0_T2A_iCre_KI_Puro', '', TRUE, 'pL1L2_GT?_T2A_iCre_KI_Puro', NULL ),
( 'pL1L2_GT1_LF2A_H2BCherry_Puro', '', TRUE, 'pL1L2_GT?_LF2A_H2BCherry_Puro', 1 ),
( 'L1L2_Pgk_P', 'PGK promoter driving WT neo.  Frame indendent IRES driven lacZ reporter', TRUE, NULL, NULL ),
( 'L1L2_GT1_LacZ_BSD', '', FALSE, 'L1L2_GT?_LacZ_BSD', 1 ),
( 'pL1L2_GT0_bsd_frt15_neo_barcode', '', TRUE, 'pL1L2_GT?_bsd_frt15_neo_barcode', NULL ),
( 'pL1L2_frt15_BetactinBSD_frt14_neo_Rox', '', TRUE, NULL, NULL ),
( 'Ifitm2_intron_L1L2_GTK_LacZ_BetactP_neo', '', TRUE, 'Ifitm2_intron_L1L2_GT?_LF2A_LacZ_BetactP_neo', -1 ),
( 'pL1L2_GT1_T2A_H2BCherry_Puro_delRsrll_NO_DTA', '', TRUE, 'pL1L2_GT?_T2A_H2BCherry_Puro_delRsrll_NO_DTA', 1 ),
( 'Ifitm2_intron_L1L2_GT0_LF2A_LacZ_BetactP_neo', '', TRUE, 'Ifitm2_intron_L1L2_GT?_LF2A_LacZ_BetactP_neo', NULL ),
( 'L1L2_GT1_LF2A_LacZ_BetactP_neo', '', TRUE, 'L1L2_GT?_LF2A_LacZ_BetactP_neo', 1 ),
( 'L1L2_GTK_LacZ_BSD', '', FALSE, 'L1L2_GT?_LacZ_BSD', -1 ),
( 'L1L2_gt0_Del_LacZ', '', FALSE, 'L1L2_gt?_Del_LacZ', NULL ),
( 'L1L2_Bact_EM7', '', TRUE, NULL, NULL ),
( 'L1L2_Del_BactPneo_FFL_TAG1A', '', TRUE, NULL, NULL ),
( 'V5_Flag_biotin', '', TRUE, NULL, NULL ),
( 'L1L2_Bact_P', 'Human beta actin promoter driving WT neo.  Frame independent IRES driven LacZ reporter', TRUE, NULL, NULL ),
( 'pL1L2_GT1_T2A_iCre_KI_Puro', '', TRUE, 'pL1L2_GT?_T2A_iCre_KI_Puro', 1 ),
( 'L1L2_gt1_Del_LacZ', '', FALSE, 'L1L2_gt?_Del_LacZ', 1 ),
( 'L1L2_gt1', 'Standard EUCOMM promoterless cassettes with T2 sequences in driving independent translation  of lacZ and neo', FALSE, 'L1L2_gt?', 1 ),
( 'B1B2_frame0_Norcomm', '', FALSE, 'B1B2_frame?_Norcomm', NULL ),
( 'pL1L2_GT2_T2A_H2BCherry_Puro_delRsrll_NO_DTA', '', TRUE, 'pL1L2_GT?_T2A_H2BCherry_Puro_delRsrll_NO_DTA', 2 ),
( 'pL1L2_GT2_LF2A_H2BCherry_Puro', '', TRUE, 'pL1L2_GT?_LF2A_H2BCherry_Puro', 1 ),
( 'pL1L2_GTK_nEGFPO_T2A_CreERT_puro', '', FALSE, 'pL1L2_GT?_LF2A_nEGFPO_T2A_CreERT_puro', -1 ),
( 'L1L2_gt2_Del_LacZ', '', FALSE, 'L1L2_gt?_Del_LacZ', 2 ),
( 'L1L2_gt2', 'Standard EUCOMM promoterless cassettes with T2 sequences in driving independent translation  of lacZ and neo', FALSE, 'L1L2_gt?', 2 ),
( 'pL1L2_GT2_bsd_frt15_neo_barcode', '', TRUE, 'pL1L2_GT?_bsd_frt15_neo_barcode', 2 );

INSERT INTO backbones( name, description, antibiotic_res, gateway_type )
VALUES
( 'R3R4_pBR_amp', 'medium copy number vector backbone from gap repair plasmid from recombineering which remains after 2-way Gateway reaction. Reactive R3 and R4 sites remain on plasmid.', 'AmpR', '2-way' ),
( 'L3L4_pZero_DTA_spec', '', '', '' ),
( 'L3L4_pZero_DTA_kan_for_norcomm', '', '', '' ),
( 'L3L4_pZero_kan', 'high copy number, no DTA', 'KanR', '3-way' ),
( 'L3L4_pD223_spec', 'high copy number with DTA', 'spec R', '3-way' ),
( 'R3R4_pBR_DTA _Bsd_amp', 'medium copy number vector backbone from 4th recombineering after gap repair plasmid recombineering which remains after 2-way Gateway reaction. Reactive R3 and R4 sites remain on plasmid.', 'AmpR', '2-way' ),
( 'L3L4_pD223_DTA_T_spec', 'high copy number with DTA', 'spec R', '3-way' ),
( 'L3L4_pD223_DTA_spec', 'high copy number with DTA; version w/o E. Coli transcription terminator on L4 side; used in a ver limited number of experiments', 'spec R', '3-way' ),
( 'R3R4_pBR_DTA+_Bsd_amp', 'medium copy number vector backbone from 4th recombineering after gap repair plasmid recombineering which remains after 2-way Gateway reaction. Reactive R3 and R4 sites remain on plasmid.', 'AmpR', '2-way' ),
( 'L3L4_pZero_DTA_kan', 'high copy number; standard backbone for promoterless vectors', 'KanR', '3-way' ),
( 'L4L3_pD223_DTA_spec', 'INVERTED R3 and R4 Gateway Sites with Linearization close to DTA pA, potentially compromising negative selection', 'spec R', '3-way' );
       
