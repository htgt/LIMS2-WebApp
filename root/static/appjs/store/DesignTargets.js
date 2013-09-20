Ext.define('DesignTargetsApp.store.DesignTargets', {
    extend: 'Ext.data.Store',
    requires: 'DesignTargetsApp.model.DesignTarget',
    model: 'DesignTargetsApp.model.DesignTarget',
    autoLoad: true,


    // fields: [
    //     'id',
    //     'marker_symbol',
    //     'ensembl_gene_id',
    //     'ensembl_exon_id',
    //     'exon_size',
    //     'exon_rank',
    //     'canonical_transcript',
    //     'species_id',
    //     'assembly_id',
    //     'build_id',
    //     'chr_id',
    //     'chr_start',
    //     'chr_end',
    //     'chr_strand',
    //     'automatically_picked',
    //     'comment',
    //     'gene_id'
    // ],
    // sorters: ['marker_symbol', 'ensembl_gene_id', 'ensembl_exon_id', 'build_id']


    // data: [
    // //     {
    //         "id": 763,
    //         "marker_symbol": "ASIC1",
    //         "ensembl_gene_id": "ENSG00000110881",
    //         "ensembl_exon_id": "ENSE00003102201",
    //         "exon_size": 151,
    //         "exon_rank": 4,
    //         "canonical_transcript": "ENST00000228468",
    //         "species_id" :"Human",
    //         "assembly_id": "GRCh37",
    //         "build_id": 70,
    //         "chr_id": 33,
    //         "chr_start": 50470996,
    //         "chr_end": 50471146,
    //         "chr_strand": 1,
    //         "automatically_picked": "t",
    //         "comment": "",
    //         "gene_id": "HGNC:100"
    //     }, {
    //         "id": 764,
    //         "marker_symbol": "ASIC1",
    //         "ensembl_gene_id": "ENSG00000110881",
    //         "ensembl_exon_id": "ENSE00003043858",
    //         "exon_size": 128,
    //         "exon_rank": 5,
    //         "canonical_transcript": "ENST00000228468",
    //         "species_id" :"Human",
    //         "assembly_id": "GRCh37",
    //         "build_id": 70,
    //         "chr_id": 33,
    //         "chr_start": 50471783,
    //         "chr_end": 50471910,
    //         "chr_strand": 1,
    //         "automatically_picked": "t",
    //         "comment": "",
    //         "gene_id": "HGNC:100"
    //     }],


    proxy: {
        type: 'ajax',
        url: url_for_json,
        reader: {
            type: 'json',
            root: 'results',
            successProperty: 'success'
        }
    },








});