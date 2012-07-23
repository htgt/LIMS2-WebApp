--
-- Minimal Bac Data
--

INSERT INTO bac_clones VALUES (92013, 'CT7-156D8', 'black6');
INSERT INTO bac_clones VALUES (92039, 'CT7-297D11', 'black6');

INSERT INTO bac_clone_loci (bac_clone_id, assembly_id, chr_id, chr_start, chr_end)
SELECT 92013, 'NCBIM37', chromosomes.id, 194454015, 194680061
FROM chromosomes WHERE chromosomes.name = '1' and chromosomes.species_id = 'Mouse';

INSERT INTO bac_clone_loci (bac_clone_id, assembly_id, chr_id, chr_start, chr_end)
SELECT 92039, 'NCBIM37', chromosomes.id, 194839227, 195070608
FROM chromosomes WHERE chromosomes.name = '1' and chromosomes.species_id = 'Mouse';
