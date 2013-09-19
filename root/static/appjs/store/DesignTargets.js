Ext.define('DesignTargetsApp.store.DesignTargets', {
    extend: 'Ext.data.Store',
    requires: 'DesignTargetsApp.model.DesignTarget',
    model: 'DesignTargetsApp.model.DesignTarget',
    autoLoad: true,


           
            store: {
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
                ]
                // sorters: ['marker_symbol', 'ensembl_gene_id', 'ensembl_exon_id', 'build_id']
            },


            // proxy: {
            //     type: 'ajax',
            //     api: {
            //         read: 'data/departments.json'
            //     },
            //     reader: {
            //         type: 'json',
            //         root: 'departments',
            //         successProperty: 'success'
            //     }
            // }




});