package LIMS2::Model::Plugin::GenotypingQC;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use Hash::MoreUtils qw( slice_def );
use LIMS2::Model::Util::DataUpload qw( parse_csv_file );
use LIMS2::Model::Util qw( sanitize_like_expr );
use List::MoreUtils qw( uniq );
use Log::Log4perl qw( :easy );
use namespace::autoclean;

requires qw( schema check_params throw );

sub pspec_update_genotyping_qc_data{
    return {
    	csv_fh     => { validate => 'file_handle' },
        created_by => { validate => 'existing_user' },
    };
}

sub update_genotyping_qc_data{
	my ($self, $params) = @_;

	my $val_params = $self->check_params( $params, $self->pspec_update_genotyping_qc_data );
	my $data = parse_csv_file( $val_params->{csv_fh});

	my @assay_types = sort map { $_->id } $self->schema->resultset('GenotypingResultType')->all;
	my @required_data = qw(copy_number copy_number_range);
	my @primer_bands = qw(tr_pcr lr_pcr gr3 gr4 gf3 gf4);
    my @messages;

    # Build a hash of all valid col names so we can report anything not recognized
    my $recognized = $self->_valid_column_names(\@assay_types, \@primer_bands);
    my $not_recognized = {};

	my $counter;
	foreach my $datum (@$data){
		$counter++;
        
        # Store unrecognized columns to report to user
		grep { $not_recognized->{$_} = 1 } grep { not $recognized->{$_} } keys %$datum;

		unless ($datum->{well_name}){
			die "No well name provided for line $counter";
		}

		# split well name and retrieve well
		my ($plate_name,$well_name) = ( $datum->{well_name} =~ /^(.*)_([A-Z]\d{2})$/g );
		my $search_params = { plate_name => $plate_name, well_name => $well_name };
        my $well = $self->retrieve_well( $search_params )
            or $self->throw(NotFound => { entity_class => 'Well', search_params => $search_params });

        push @messages, "Well ".$datum->{well_name}.":";
		# update targeting_pass and chromosome_fail if provided
		foreach my $overall qw(targeting_pass targeting-puro_pass chromosome_fail){
			if (my $result = $datum->{$overall}){

                # Change targeting-puro (targeting minus puro) to targeting_puro 
                # for consistency with naming of db tables
                my $table = $overall;
                $table =~ s/targeting-puro/targeting_puro/;
                
				# Tidy up result input values
				$result =~ s/\s*//g;
				$result = lc($result) unless $result eq "Y";

				my $method = "update_or_create_well_".$table;
				my ($result, $message) = $self->$method({
					well_id    => $well->id,
					result     => $result,
					created_by => $val_params->{created_by},
				});
				push @messages, "- ".$message;
			}
		}

		# for each assay type see if we have pass/call
		# if we do and pass/call == na or fa then create/update with no values
		# for other pass/call values create/update result with all available data (confidence is optional)
		foreach my $assay (@assay_types){
			if (my $call = $datum->{$assay."_pass"}){
				my ($result, $message);

				# Tidy up call input values
				$call =~ s/\s*//g;
				$call = lc($call);

				if ($call eq "na" or $call eq "fa"){
					# Update call - any existing copy number etc will be removed from db
					($result, $message) = $self->update_or_create_well_genotyping_result({
						well_id    => $well->id,
						genotyping_result_type_id => $assay,
						call       => $call,
						created_by => $val_params->{created_by},
					});
				}
				else{
					# Check we have required fields
					my %new_values;
					foreach my $field (@required_data){
						defined( $new_values{$field} = $datum->{$assay."_$field"} )
						    or die "No $assay $field value found for ".$well->name;
					}
					# confidence is optional
					if (defined (my $conf = $datum->{$assay."_confidence"}) ){
						$new_values{'confidence'} = $conf;
					}

					($result, $message) = $self->update_or_create_well_genotyping_result({
						well_id => $well->id,
						genotyping_result_type_id => $assay,
						call => $call,
						created_by => $val_params->{created_by},
						%new_values,
					})
				}
				push @messages, "- ".$message;
			}
		}
		
		# Handle well primer band status
		foreach my $primer (@primer_bands){
			my $value = $datum->{$primer};
			if (defined $value){
				die "Invalid data \"$value\" provided for well ".$datum->{well_name}." $primer" unless $value eq "yes";
				
				# FIXME: need an update or create method        
				$self->create_well_primer_bands({
					well_id          => $well->id,
					primer_band_type => $primer,
					pass             => 1,
					created_by       => $val_params->{created_by},
				});
				
				push @messages, "- Created $primer primer band with pass";
			}
		}
	}

    if (keys %$not_recognized){
    	unshift @messages, "The following unrecognized columns were ignored: "
    	                   .join ", ", sort keys %$not_recognized;
    }
	return \@messages;
}

sub _valid_column_names{
	my ($self, $assay_types, $primer_bands) = @_;
	
	# Overall results including primer bands
    my %recognized = map { $_ => 1 } qw(well_name targeting_pass targeting-puro_pass chromosome_fail), 
                                     @$primer_bands;
    
    # Assay specific results                       
    foreach my $assay (@$assay_types){
    	foreach my $colname qw( pass confidence copy_number copy_number_range){
    		$recognized{$assay."_".$colname} = 1;
    	}
    }
    return \%recognized;
}


#    update_genotyping_qc_value updates one item on each call. As the user makes changes to
#    each cell in the user interface, the controller opens a transaction and calls this method.
#    Once an item is successfully updated the controller will close the transaction by issuing
#    a commit.


sub pspec_update_genotyping_qc_value {
    return {
        well_id           => { validate => 'integer' },
        assay_name        => { validate => 'non_empty_string' },
        assay_value       => { validate => 'non_empty_string' },
        created_by        => { validate => 'existing_user' },
    }

}

sub update_genotyping_qc_value {
    my ($self, $params) = @_;

# Define dispatch table for the various assay types
$DB::single=1;

# The dispatch table is for matching specific assays to specified function calls.
    my $assays_dispatch = {
        'chromosome_fail'       => \&well_assay_update,
        'targeting_pass'        => \&well_assay_update,
        'targeting_puro_pass'   => \&well_assay_update,
        'tr_pcr'                => \&tr_pcr_update,
        'gr3'                   => \&gr_band_update,
        'gr4'                   => \&gr_band_update,
        'gf3'                   => \&gf_band_update,
        'gf4'                   => \&gf_band_update,
    };

#  The more generic assay, call, copy_number, copy_range, confidence call is easier to handle.
	my $vp = $self->check_params( $params, $self->pspec_update_genotyping_qc_value );

    my $assay_name = $vp->{'assay_name'};
    my $assay_value = $vp->{'assay_value'};
    my $well_id = $vp->{'well_id'};
    my $user = $vp->{'created_by'};
    # $assay_value needs translating from string to value before sending down the line
    # if it is a pcr band update
    # Possible values are 'true', 'false', '-' (the latter gets passed through as is)
    if ( $assay_name =~ /g[r|f]/ ) {
        if ( $assay_value eq 'true' ) {
            $assay_value = 1;
            }
        elsif ( $assay_value eq 'false' ) {
            $assay_value = 0;
        }
    }

    my $genotyping_qc_result;

$DB::single=1;
    if (exists $assays_dispatch->{$assay_name} ) {
        $genotyping_qc_result = $assays_dispatch->{$assay_name}->($self, $assay_name, $assay_value, $well_id, $user);
    }
    elsif ( $assay_name =~ /#/ ) {
        # deal with the generic genotyping_qc assays that all have the same format
        # $assay_name contains a '#' separating the actual assay name
        # from the field within that assay that is scheduled for an update operation
        # So we fish those out of the $assay_name variable and call the generic update
        # or create method.
        my ($genotyping_assay, $assay_field) = split( '#', $assay_name);
        $genotyping_qc_result = $self->generic_assay_update(
            $genotyping_assay, $assay_field, $assay_value, $well_id, $user, 
        );
    }
    else {
        # throw an error
        require LIMS2::Exception::Implementation;
        LIMS2::Exception::Implementation->throw( "Assay $assay_name not found in dispatch table" );
    }


    return $genotyping_qc_result;
}

# TODO: Update these methods to use the 'params' and slice_def technique. However, the code works as is.
sub well_assay_update{
    my $self = shift;
    my $assay_name = shift;
    my $assay_value = shift;
    my $well_id = shift;
    my $user = shift;

    my $update_method = 'update_or_create_well_' . $assay_name;
    my $well_assay_tag = $self->$update_method({
            	created_by => $user,
            	result     => $assay_value,
            	well_id    => $well_id,
            });

    return $well_assay_tag;
}

sub targeting_pass_update{
    my $self = shift;
    my $assay_name = shift;
    my $assay_value = shift;
    my $well_id = shift;
    my $user = shift;

    my $targeting_pass = $self->update_or_create_well_targeting_pass({
            	created_by => $user,
            	result     => $assay_value,
            	well_id    => $well_id,
            });

    return $targeting_pass;
}

sub chromosome_fail_update{
    my $self = shift;
    my $assay_name = shift;
    my $assay_value = shift;
    my $well_id = shift;
    my $user = shift;

    my $chromosome_fail = $self->update_or_create_well_chromosome_fail({
            created_by => $user,
            result     => $assay_value,
            well_id    => $well_id,
        });

    return $chromosome_fail;
}

sub targeting_puro_pass_update{
    my $self = shift;
    my $assay_name = shift;
    my $assay_value = shift;
    my $well_id = shift;
    my $user = shift;

    my $targeting_puro_pass = $self->update_or_create_well_targeting_puro_pass({
            created_by => $user,
            result     => $assay_value,
            well_id    => $well_id,
        });
    return $targeting_puro_pass;
}

sub tr_pcr_update {

}

sub gr_band_update {
    my $self = shift;
    my $assay_name = shift;
    my $assay_value = shift;
    my $well_id = shift;
    my $user = shift;

    my $well_primer_band;

    if ( $assay_value eq '-' ){
        $well_primer_band = $self->delete_well_primer_band({
                primer_band_type => $assay_name,
                created_by => $user,
                well_id => $well_id,
            });
    }
    else {
        $well_primer_band = $self->update_or_create_well_primer_bands({
                primer_band_type => $assay_name,
                pass => $assay_value,
            	created_by => $user,
            	well_id    => $well_id,
            });
    }
    return $well_primer_band;

}

# Generic assay update method wrapper
sub generic_assay_update{
    my $self = shift;
    my $genotyping_assay = shift;
    my $assay_field = shift;
    my $assay_value = shift;
    my $well_id = shift;
    my $user = shift;

    my $well_genotyping_result = $self->update_or_create_well_genotyping_result({
            well_id => $well_id,
            genotyping_result_type_id => $genotyping_assay,
            $assay_field => $assay_value,
            created_by => $user,
        });

    return $well_genotyping_result;
}

# Use a direct SQL query to return data quickly to the browser. This means we do not use the model
# to populate the interface.
# However, the model must be used for the database updates.

sub get_genotyping_qc_browser_data {
    my $self = shift;
    my $plate_name = shift;

# SQL query requires plate id as input
my $sql_query =  <<'SQL_END';    
    with wd as (
	select p.id "Plate ID"
	, p.name "plate"
	, w.name "well"
	, w.id "Well ID"
	, wgt.genotyping_result_type_id
	, wgt.call
	, wgt.copy_number
	, wgt.copy_number_range
	, wgt.confidence
	from plates p, wells w, well_genotyping_results wgt
		where p.name = ?
		and w.plate_id = p.id
		and wgt.well_id = w.id
	order by w.name, wgt.genotyping_result_type_id )
select wd."Plate ID", wd."plate", wd."Well ID", wd."well", wd.genotyping_result_type_id, wd.call,
	wd.copy_number, wd.copy_number_range, wd.confidence,
	well_chromosome_fail.result "Chr fail",
	well_targeting_pass.result "Tgt pass",
	well_targeting_puro_pass.result "Puro pass",
	well_primer_bands.primer_band_type_id "Primer band type",
	well_primer_bands.pass "Primer pass?"
from wd
left outer
	join well_chromosome_fail
		on wd."Well ID" = well_chromosome_fail.well_id
left outer
	join well_targeting_pass
		on wd."Well ID" = well_targeting_pass.well_id
left outer
	join well_targeting_puro_pass
		on wd."Well ID" = well_targeting_puro_pass.well_id
left outer
	join well_primer_bands
		on wd."Well ID" = well_primer_bands.well_id
SQL_END

my $sql_result =  $self->schema->storage->dbh_do(
    sub {
         my ( $storage, $dbh ) = @_;
         my $sth = $dbh->prepare_cached( $sql_query );
         $sth->execute( $plate_name );
         $sth->fetchall_arrayref({
             'Well ID' => 1,
             'well' => 1,
             'Chr fail' => 1,
             'Tgt pass' => 1,
             'Puro pass' => 1,
             'genotyping_result_type_id' => 1,
             'call' => 1,
             'copy_number' => 1,
             'confidence' => 1,
             'copy_number_range' => 1,
         });
    }
);
my @all_data;
foreach my $row ( @{$sql_result} ) {
    my $datum;
    $datum->{id} = $row->{'Well ID'};
    $datum->{well} = $row->{'well'};
    $datum->{chromosome_fail} = $row->{'Chr fail'};
    $datum->{targeting_pass} = $row->{'Tgt pass'};
    $datum->{targeting_puro_pass} = $row->{'Puro pass'};
    $datum->{gf3} = $row->{'gf3'};
    $datum->{gf4} = $row->{'gf4'};
    $datum->{gr3} = $row->{'gr3'};
    $datum->{gr4} = $row->{'gr4'};

   push @all_data, $datum;
}
return @all_data;
}
1;
