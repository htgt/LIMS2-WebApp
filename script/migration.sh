#!/bin/bash

echo Migration Script Initiated.
echo Extraction of paths in progres...
perl script/extracting_alleles_freq_paths.pl
echo Finished extracting paths!
echo Creating missing miseq well experiments...
perl script/migration_script_2.pl
echo Finished creating missing miseq well experiments!
echo Migration script in progress...
perl script/migration_script.pl
echo Finished migrating files to the data
