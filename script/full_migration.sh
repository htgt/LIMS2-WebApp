echo Extraction of paths in progress...
perl ./script/extracting_alleles_freq_paths.pl
echo Finished extracting paths!
echo Migration Script Initiated.
sh ./script/migration.sh
