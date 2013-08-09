package LIMS2::Report::Summary;

use Moose;
use Log::Log4perl qw(:easy);
use namespace::autoclean;
#use Readonly;


Log::Log4perl->easy_init($DEBUG);

extends qw( LIMS2::ReportGenerator );



#  my %REPORT_CATEGORIES => (
# 	gene	=> {
#  		name	=> 'Gene',
# 		order	=> 1,
# 	},
# 	project	=> {
#  		name	=> 'Project',
# 		order	=> 2,
# 	},
# 	key	=> {
#  		name	=> 'ID',
# 		order	=> 3,
# 	},
# 	fepd_targeted_clones	=> {
#  		name	=> 'FEPD Targeted Clones',
# 		order	=> 4,
# 	},
# 	sepd_targeted_clones	=> {
#  		name	=> 'SEPD Targeted Clone',
# 		order	=> 5,
# 	},
# 	a1_design_id	=> {
#  		name	=> '1st allele targeting design ID',
# 		order	=> 6,
# 	},
# 	a1_drug_resistance	=> {
#  		name	=> '1st allele targeting drug resistance',
# 		order	=> 7,
# 	},
# 	a1_targeting_promoter	=> {
#  		name	=> '1st allele targeting promotor',
# 		order	=> 8,
# 	},
# 	a1_targeting_vector_plate	=> {
#  		name	=> '1st allele targeting vector plate',
# 		order	=> 9,
# 	},
# 	fepd_number	=> {
#  		name	=> 'FEPD Number',
# 		order	=> 10,
# 	},
# 	a2_design_id	=> {
#  		name	=> '2nd allele targeting design ID',
# 		order	=> 11,
# 	},
# 	a2_drug_resistance	=> {
#  		name	=> '2nd allele targeting drug resistance',
# 		order	=> 12,
# 	},
# 	a2_targeting_promoter	=> {
#  		name	=> '2nd allele targeting promotor',
# 		order	=> 13,
# 	},
# 	a2_targeting_vector_plate	=> {
#  		name	=> '2nd allele targeting vector plate',
# 		order	=> 14,
# 	},
# 	sepd_number	=> {
# 		name	=> 'SEPD Number',
# 		order	=> 15,
# 	},
# );



override _build_name => sub {
    return 'Test Report';
};




override _build_columns => sub {
    return [
		"Gene",
		"Project",
		"ID",
		"FEPD Targeted Clones",
		"SEPD Targeted Clone",
		"1st allele targeting design ID",
		"1st allele targeting drug resistance",
		"1st allele targeting promotor",
		"1st allele targeting vector plate",
		"FEPD Number",
		"2nd allele targeting design ID",
		"2nd allele targeting drug resistance",
		"2nd allele targeting promotor",
		"2nd allele targeting vector plate",
		"SEPD Number",
    ];
};


sub build_summary_data {
    my $self = shift;
    use Smart::Comments;
    ## $self
	my $sponsor = 'Syboss';
	my %report_data;

	my $data_rs = $self->model->schema->resultset('Project');
	
	my (@rows) = $data_rs->search({
		sponsor_id => $sponsor,
		targeting_type => 'double_targeted',
	})->all;

	# Loop through genes
	foreach my $gene_id (@rows) {
#		print 'gene: ' . $gene->gene_id . "\n";
		
		#my $data_rs = $model->schema->resultset('GeneDesign');
		my $data_rs = $self->model->schema->resultset('GeneDesign');
		my (@rows) = $data_rs->search({
			gene_id => $gene_id->gene_id
		})->all;

		# Loop through designs
		foreach my $design (@rows) {
#			print "\tdesign: " . $design->design_id. "\n";

			#my $data_rs = $model->schema->resultset('Summary');
			my $data_rs = $self->model->schema->resultset('Summary');

			my (@rows) = $data_rs->search({
				design_id => $design->design_id,
				final_cassette_cre => '0',
				-or => [ ep_plate_name => { '!=', undef },
				 {sep_plate_name => { '!=', undef } },],
			})->all;
			
			my %current_well;
			my %fepd_wells;
			my %fepd_plates;
			my %accepted_fepd_wells;
			my %sepd_wells;
			my %sepd_plates;
			my %accepted_sepd_wells;

			# This is the actual summaries table rows
			foreach my $data (@rows) {
				# print "$counter\t\tdesign: " . $data->design_id. "\tdna_plate_name: " . 
				#	$data->dna_plate_name. "\tdna_well_name: " . $data->dna_well_name. "\n";
				my $plate = $data->ep_plate_name;
				my $well = $data->ep_well_name;
				my $EP_well_name = "$plate"."_"."$well" unless (!defined $plate || !defined $well);
				if (defined $EP_well_name && !exists $report_data{$EP_well_name}) { 
					$report_data{$EP_well_name} = \%current_well unless ($EP_well_name eq '_');
					#say $EP_well_name;
				};

				my $gene = $data->design_gene_symbol;
				$current_well{gene} = $gene;
				$current_well{project} = $sponsor;
				
				# FEPD Targeted Clones
				if ($data->ep_pick_well_name) {
					my $fepd_plate = $data->ep_pick_plate_name;
					my $fepd_well = $data->ep_pick_well_name;
					my $fepd_well_name = "$fepd_plate"."_"."$fepd_well" unless (!defined $fepd_plate || !defined $fepd_well);
					$fepd_wells{$fepd_well_name} = 1;
					$fepd_plates{$fepd_plate} = 1;
				}


				if ($data->ep_pick_well_accepted) {
					my $fepd_plate = $data->ep_pick_plate_name;
					my $fepd_well = $data->ep_pick_well_name;
					my $accepted_fepd_well_name = "$fepd_plate"."_"."$fepd_well" unless (!defined $fepd_plate || !defined $fepd_well);
					$accepted_fepd_wells{$accepted_fepd_well_name} = 1;
				}

				$current_well{'fepd_number'} = join ":", keys %fepd_plates;
				$current_well{'fepd_targeted_clones'} = scalar keys (%accepted_fepd_wells);
				undef %fepd_plates;

				# SEPD Targeted Clones
				if ($data->sep_pick_well_name) {
					my $sepd_plate = $data->sep_pick_plate_name;
					my $sepd_well = $data->sep_pick_well_name;
					my $sepd_well_name = "$sepd_plate"."_"."$sepd_well" unless (!defined $sepd_plate || !defined $sepd_well);
					$sepd_wells{$sepd_well_name} = 1;
					$sepd_plates{$sepd_plate} = 1;
				}


				if ($data->sep_pick_well_accepted) {
					my $sepd_plate = $data->sep_pick_plate_name;
					my $sepd_well = $data->sep_pick_well_name;
					my $accepted_sepd_well_name = "$sepd_plate"."_"."$sepd_well" unless (!defined $sepd_plate || !defined $sepd_well);
					$accepted_sepd_wells{$accepted_sepd_well_name} = 1;
				}

				$current_well{'sepd_number'} = join ":", keys %sepd_plates;
				$current_well{'sepd_targeted_clones'} = scalar keys (%accepted_sepd_wells);
				undef %sepd_plates;

				if ($data->ep_well_name) {
					$current_well{'1_design_id'} = $data->design_id;
					$current_well{'1_drug_resistance'} = $data->final_pick_cassette_resistance;
					if (!$data->final_pick_cassette_promoter) {
						$current_well{'1_targeting_promoter'} = 'Promoterless';
					} else {
						$current_well{'1_targeting_promoter'} = $data->final_pick_cassette_name;
					}
					$current_well{'1_targeting_vector_plate'} = $data->final_pick_plate_name;
				}
				if (!$data->ep_well_name) {
					$current_well{'2_design_id'} = $data->design_id;
					$current_well{'2_drug_resistance'} = $data->final_pick_cassette_resistance;
					if (!$data->final_pick_cassette_promoter) {
						$current_well{'2_targeting_promoter'} = 'Promoterless';
					} else {
						$current_well{'2_targeting_promoter'} = $data->final_pick_cassette_name;
					}				
					$current_well{'2_targeting_vector_plate'} = $data->final_pick_plate_name;

				}

			}

		}
	}
	

	my @output;

	while ( my ($key, $value) = each %report_data ) {
	#print "$key\n";		

		use Smart::Comments;
		## %report_data

		# trick to print out key
		#$$value{'key'} = $key;


		my @line = 	( [
					"$$value{'project'}",
					"$key",
					"$$value{'fepd_targeted_clones'}",
					"$$value{'sepd_targeted_clones'}",
					"$$value{'1_design_id'}",
					"$$value{'1_drug_resistance'}",
					"$$value{'1_targeting_promoter'}",
					"$$value{'1_targeting_vector_plate'}",
					"$$value{'fepd_number'}",
					"$$value{'2_design_id'}",
					"$$value{'2_drug_resistance'}",
					"$$value{'2_targeting_promoter'}",
					"$$value{'2_targeting_vector_plate'}",
					"$$value{'sepd_number'}",
					] );

		push(@output, @line);
	}
	#my @output = ( [ 'o1ne','on2e','two1','o2ne','t123wo','123123one','two','one','two','one','two','one','two','one','two' ], 
				#	  [ 'o2123ne','o21321ne','t323wo','one21','tw2o','on213e','t123wo','one','two','one','two','one','two','one','two' ]
					#);
 	return @output;
 	#$self->summary_data = @output;
 	#return $self->summary_data;
}




override iterator => sub {
	my ( $self ) = @_;
			use Smart::Comments;
			### $self
 	#my $test_data_ref = $self->summary_data;
 	## $self->summary_data;
 	## $test_data_ref
 	#my @test_data = @$test_data_ref;

 	 my @test_data = $self -> build_summary_data();
 	 #( [ 'one','one','two','one','two','one','two','one','two','one','two','one','two','one','two' ], 
	#	 			  [ 'one','one','two','one','two','one','two','one','two','one','two','one','two','one','two' ]
	#	 			);
	#my @test_data = ( [ 'one','one','two','one','two','one','two','one','two','one','two','one','two','one','two' ], 
	#				  [ 'one','one','two','one','two','one','two','one','two','one','two','one','two','one','two' ]
	#				);

	return Iterator::Simple::iter( \@test_data );
};

__PACKAGE__->meta->make_immutable;

1;

__END__











































