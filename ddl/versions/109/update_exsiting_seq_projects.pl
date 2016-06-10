#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Model;
use Path::Class;
use POSIX;
use Try::Tiny;

my $model = LIMS2::Model->new({ user => 'tasks' });

my $data_dir = dir($ENV{LIMS2_SEQ_FILE_DIR});

foreach my $subdir ($data_dir->children){
	my $project = $subdir->basename;
	my $modified = strftime("%Y-%m-%dT%H:%M:%S", localtime( ( stat $subdir )[9] ));
	print "Project $project modified $modified\n";
        $model->schema->txn_do( sub{
          try{
              $model->update_sequencing_project({
                  name              => $project,
                  available_results => 1,
                  results_imported_date => $modified,
              });
          }
          catch{
              warn "Could not update data availability info for project $project: $_";
              $model->schema->txn_rollback;
          };
        });
}
