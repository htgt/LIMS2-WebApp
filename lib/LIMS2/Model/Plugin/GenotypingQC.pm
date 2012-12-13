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

1;