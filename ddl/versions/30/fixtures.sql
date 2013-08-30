UPDATE cassettes SET resistance = 'bsd'  WHERE resistance = 'blastR';
UPDATE cassettes SET resistance = 'neo'  WHERE resistance = 'neoR';
UPDATE cassettes SET resistance = 'zeo'  WHERE resistance = 'zeoR';
UPDATE cassettes SET resistance = 'puro' WHERE resistance = 'puroR';

UPDATE summaries SET final_cassette_resistance      = 'bsd'  WHERE final_cassette_resistance      = 'blastR';
UPDATE summaries SET final_pick_cassette_resistance = 'bsd'  WHERE final_pick_cassette_resistance = 'blastR';
UPDATE summaries SET final_cassette_resistance      = 'neo'  WHERE final_cassette_resistance      = 'neoR';
UPDATE summaries SET final_pick_cassette_resistance = 'neo'  WHERE final_pick_cassette_resistance = 'neoR';
UPDATE summaries SET final_cassette_resistance      = 'puro' WHERE final_cassette_resistance      = 'puroR';
UPDATE summaries SET final_pick_cassette_resistance = 'puro' WHERE final_pick_cassette_resistance = 'puroR';

UPDATE cassettes SET resistance = 'neo'  WHERE name = 'Ifitm2_intron_L1L2_GT0_LF2A_LacZ_BetactP_neo';
UPDATE cassettes SET resistance = 'neo'  WHERE name = 'Ifitm2_intron_L1L2_GT1_LF2A_LacZ_BetactP_neo';
UPDATE cassettes SET resistance = 'neo'  WHERE name = 'Ifitm2_intron_L1L2_GT2_LF2A_LacZ_BetactP_neo';
UPDATE cassettes SET resistance = 'neo'  WHERE name = 'Ifitm2_intron_L1L2_GTK_LacZ_BetactP_neo';
UPDATE cassettes SET resistance = 'neo'  WHERE name = 'L1L2_6XOspnEnh_Bact_P';
UPDATE cassettes SET resistance = 'neo'  WHERE name = 'L1L2_Bact_EM7';
UPDATE cassettes SET resistance = 'neo'  WHERE name = 'L1L2_Del_BactPneo_FFL_TAG1A';
UPDATE cassettes SET resistance = 'neo'  WHERE name = 'L1L2_GOHANU';
UPDATE cassettes SET resistance = 'puro' WHERE name = 'L1L2_GT0_T2A_H2BVenus_PGKPuro_delRsrII_NO_DTA';
UPDATE cassettes SET resistance = 'neo'  WHERE name = 'L1L2_hubi_P';
UPDATE cassettes SET resistance = 'neo'  WHERE name = 'L1L2_st0';
UPDATE cassettes SET resistance = 'neo'  WHERE name = 'L1L2_st2';
UPDATE cassettes SET resistance = 'bsd'  WHERE name = 'pL1L2_GT0_bsd_frt15_neo_barcode';
UPDATE cassettes SET resistance = 'puro' WHERE name = 'pL1L2_GT0_LF2A_H2BCherry_Puro';
UPDATE cassettes SET resistance = 'puro' WHERE name = 'pL1L2_GT0_T2A_H2BCherry_Puro_delRsrll_NO_DTA';
UPDATE cassettes SET resistance = 'bsd'  WHERE name = 'pL1L2_GT1_bsd_frt15_neo_barcode';
UPDATE cassettes SET resistance = 'puro' WHERE name = 'pL1L2_GT1_LF2A_H2BCherry_Puro';
UPDATE cassettes SET resistance = 'puro' WHERE name = 'pL1L2_GT1_T2A_H2BCherry_Puro_delRsrll_NO_DTA';
UPDATE cassettes SET resistance = 'bsd'  WHERE name = 'pL1L2_GT2_bsd_frt15_neo_barcode';
UPDATE cassettes SET resistance = 'puro' WHERE name = 'pL1L2_GT2_LF2A_H2BCherry_Puro';
UPDATE cassettes SET resistance = 'puro' WHERE name = 'pL1L2_GT2_T2A_H2BCherry_Puro_delRsrll_NO_DTA';

INSERT INTO schema_versions(version) VALUES (30);