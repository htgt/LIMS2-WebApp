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
    my @messages;

use Data::Dumper;
$self->log->debug(Dumper($data));

	my $counter;
	foreach my $datum (@$data){
		$counter++;
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
		foreach my $overall qw(targeting_pass chromosome_fail){
			if (my $result = $datum->{$overall}){

				# Tidy up result input values
				$result =~ s/\s*//g;
				$result = lc($result) unless $result eq "Y";

				my $method = "update_or_create_well_".$overall;
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
					# FIXME: do we need to set existing results in DB to undef?
					# will the update validation allow this?
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
						# Remove < > prefix
						$conf =~ s/^\s*[<>]\s*//g;
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

	}

	return \@messages;
}

1;