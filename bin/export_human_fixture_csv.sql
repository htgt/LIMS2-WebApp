\copy (select * from designs where species_id='Human') to 'Design.csv' with CSV HEADER;
\copy (select gd.* from gene_design gd, designs d where d.species_id='Human' and d.id=gd.design_id) to 'GeneDesign.csv' with CSV HEADER;
\copy (select * from plates where species_id='Human') to 'Plate.csv' with CSV HEADER;
\copy (select pr.* from processes pr, process_output_well po, wells w,plates p where p.species_id='Human' and w.plate_id=p.id and po.well_id=w.id and pr.id=po.process_id) to 'Process.csv' with CSV HEADER;
\copy (select prb.* from process_backbone prb, process_output_well po, wells w,plates p where p.species_id='Human' and w.plate_id=p.id and po.well_id=w.id and prb.process_id=po.process_id) to 'ProcessBackbone.csv' with CSV HEADER;
\copy (select prb.* from process_cassette prb, process_output_well po, wells w,plates p where p.species_id='Human' and w.plate_id=p.id and po.well_id=w.id and prb.process_id=po.process_id) to 'ProcessCassette.csv' with CSV HEADER;
\copy (select prb.* from process_cell_line prb, process_output_well po, wells w,plates p where p.species_id='Human' and w.plate_id=p.id and po.well_id=w.id and prb.process_id=po.process_id) to 'ProcessCellLine.csv' with CSV HEADER;
\copy (select prb.* from process_design prb, process_output_well po, wells w,plates p where p.species_id='Human' and w.plate_id=p.id and po.well_id=w.id and prb.process_id=po.process_id) to 'ProcessDesign.csv' with CSV HEADER;
\copy (select prb.* from process_input_well prb, process_output_well po, wells w,plates p where p.species_id='Human' and w.plate_id=p.id and po.well_id=w.id and prb.process_id=po.process_id) to 'ProcessInputWell.csv' with CSV HEADER;
\copy (select po.* from process_output_well po, wells w,plates p where p.species_id='Human' and w.plate_id=p.id and po.well_id=w.id) to 'ProcessOutputWell.csv' with CSV HEADER;
\copy (select prb.* from process_recombinase prb, process_output_well po, wells w,plates p where p.species_id='Human' and w.plate_id=p.id and po.well_id=w.id and prb.process_id=po.process_id) to 'ProcessRecombinase.csv' with CSV HEADER;
\copy (select prb.* from process_nuclease prb, process_output_well po, wells w,plates p where p.species_id='Human' and w.plate_id=p.id and po.well_id=w.id and prb.process_id=po.process_id) to 'ProcessNuclease.csv' with CSV HEADER;
\copy (select prb.* from process_crispr prb, process_output_well po, wells w,plates p where p.species_id='Human' and w.plate_id=p.id and po.well_id=w.id and prb.process_id=po.process_id) to 'ProcessCrispr.csv' with CSV HEADER;
\copy (select w.* from wells w,plates p where p.species_id='Human' and w.plate_id=p.id) to 'Well.csv' with CSV HEADER;



