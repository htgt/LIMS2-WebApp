#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use LIMS2::Model;
use feature qw(say);
use Data::Dumper;
use TryCatch;

my $model = LIMS2::Model->new({ user => 'tasks' });

my @versioned_plates = $model->schema->resultset('Plate')->search({
    'version' => { '!=' => undef },
});

say "Found ".scalar(@versioned_plates)." versioned plates";

foreach my $plate (@versioned_plates){
	my $name = $plate->name;
	my $version = $plate->version;
	say "------------------------------------------------";
    say "Preparing to delete plate $name version $version";

    my $count = scalar($plate->wells);
    if($count > 0){
    	say "ERROR: cannot delete plate as it has $count wells on it";
    	next;
    }

    my @current_plates = $model->schema->resultset('Plate')->search({
        name => $name,
        version => undef,
    });
    unless(@current_plates == 1){
    	say "ERROR: could not find current plate";
    	next;
    }

    my $current_id = $current_plates[0]->id;
    $model->schema->txn_do(sub{
    	try{
    		my $comments_updated = 0;
    		my $comments_deleted = 0;
			my $events_updated = 0;

			foreach my $comment ($plate->plate_comments){
				if($comment->comment_text =~ /removed from version/){
					$comment->delete;
					$comments_deleted++;
				}
				else{
					say 'updating comment: "'.$comment->comment_text.'"';
					$comment->update({ plate_id => $current_id });
					$comments_updated++;
				}
			}

			say "$comments_deleted comments deleted" if $comments_deleted;
			say "$comments_updated comments updated to plate id $current_id" if $comments_updated;

		    foreach my $new_plate_event ($plate->barcode_events_new_plates){
		        $new_plate_event->update({ new_plate_id => $current_id });
		        $events_updated++;
		    }

		    foreach my $old_plate_event ($plate->barcode_events_old_plates){
		        $old_plate_event->update({ old_plate_id => $current_id });
		        $events_updated++;
		    }

		    say "$events_updated events updated to plate id $current_id";

		    $plate->discard_changes;
		    $plate->delete;
		    say "Plate $name v$version deleted";
		}
		catch($err){
            $model->schema->txn_rollback;
            say "ERROR: could not delete plate $name version $version";
            say "ERROR MESSAGE: $err";
		}
	});
}