echo Extraction of paths in progress...
find /warehouse/team229_wh01/lims2_managed_miseq_data/. -name Alleles_frequency_table.txt >> files_paths.txt
echo Finished extracting paths!
echo Migration Script Initiated.
sh ./script/migration.sh
