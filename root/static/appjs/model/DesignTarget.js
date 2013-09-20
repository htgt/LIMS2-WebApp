Ext.define('DesignTargetsApp.model.DesignTarget', {
    extend: 'Ext.data.Model',
    fields: [
        'id',
        'marker_symbol',
        'ensembl_gene_id',
        'ensembl_exon_id',
        'exon_size',
        'exon_rank',
        'canonical_transcript',
        'species_id',
        'assembly_id',
        'build_id',
        'chr_id',
        'chr_start',
        'chr_end',
        'chr_strand',
        'automatically_picked',
        'comment',
        'gene_id'
    ],
    // proxy: {
    //     type: 'ajax',
    //     url: url_for_json,
    //     reader: {
    //         type: 'json',
    //         root: 'results'
    //     }
    // }
});