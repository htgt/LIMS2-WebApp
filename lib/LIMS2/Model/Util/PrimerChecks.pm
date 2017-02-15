package LIMS2::Model::Util::PrimerChecks;
## no critic(RequireUseStrict,RequireUseWarnings)
{
    $LIMS2::Model::Util::PrimerChecks::VERSION = '0.445';
}
## use critic


use strict;
use warnings FATAL => 'all';
use feature "switch";

use Sub::Exporter -setup => {
    exports => [
        qw(
              repeats_between_primer_and_target
          )
    ]
};

use Log::Log4perl qw( :easy );
use List::MoreUtils qw( uniq );
use Data::Dumper;

sub repeats_between_primer_and_target{
    my ($primer, $ensembl_util) = @_;

    my $target = $primer->get_target;

    DEBUG("Checking sequence between primer ".$primer->id." and target ".$target->id);
    # search for repeats in ......
    # | SF1 |.........>| target |<.......| SR1 |
    my ($region_start, $region_end);
    if($primer->start < $target->start){
        $region_start = $primer->end;
        $region_end   = $target->start;
    }
    else{
        $region_start = $target->end;
        $region_end   = $primer->start;
    }

    my $slice = $ensembl_util->slice_adaptor->fetch_by_region(
        'chromosome',
        $primer->chr_name,
        $region_start,
        $region_end
    );

    my $seq = $slice->seq();

    DEBUG("Coords: chr".$primer->chr_name.":$region_start-$region_end");
    DEBUG("Sequence: $seq");
    if(my ($repeat) = $seq =~ /(A{15,}|T{15,}|C{15,}|G{15,})/g){
    	DEBUG("Found same base repeated 15+ times: $repeat");
        my $info = {
            primer_id => $primer->id,
            primer_name => $primer->primer_name->primer_name,
            is_validated => ($primer->is_validated // ''),
            is_rejected => ($primer->is_rejected // ''),
            crispr_id => ($primer->crispr_id // ''),
            crispr_pair_id => ($primer->crispr_pair_id // ''),
            crispr_group_id => ($primer->crispr_group_id // ''),
            species => $target->species_id,
            chromosome => $primer->chr_name,
            region_start => $region_start,
            region_end => $region_end,
            repeat_length => length($repeat),
            repeat => $repeat,
            sequence => $seq,
        };
    	return $info;
    }

    return;
}

1;