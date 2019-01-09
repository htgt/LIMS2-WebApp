#!/bin/bash

echo Creating missing miseq well experiments...
perl ./script/create_miseq_well_exps.pl 
echo Finished creating missing miseq well experiments!
echo Migration script in progress...
perl ./script/migration_script.pl
echo Finished migrating files to the data.
echo Import_indel script in progress...
perl ./script/import_indel.pl
echo Finished importing indels.
echo Import_criprs script in progress...
perl ./script/import_crisprs.pl
echo Finished importing the crisprs submission details.
rm ./files_path.txt
