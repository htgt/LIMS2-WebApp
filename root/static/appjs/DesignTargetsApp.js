Ext.application({
    requires: ['Ext.grid.Panel'], 
    name: 'DesignTargetsApp',
    autoCreateViewport: false,
    appFolder: '/static/appjs',
    models: ['DesignTarget'],
    stores: ['DesignTargets'],
    controllers: ['LoadDesignTargetsView'],

    launch: function() {
        // This is fired as soon as the page is ready
        Ext.create('Ext.grid.Panel', {
            title: 'Design Targets List',
            store: 'DesignTargets',
            // store: Ext.data.StoreManager.lookup('DesignTargets'),
            layout: 'fit',
            height: 750,
            width: 1170,
            autoScroll: true,

            columns: [
                // { header: 'ID', dataIndex: 'id' },
                { header: 'Marker Symbol', dataIndex: 'marker_symbol' },
                { header: 'Ensembl gene id', dataIndex: 'ensembl_gene_id' },
                { header: 'Ensembl exon id', dataIndex: 'ensembl_exon_id' },
                { header: 'Exon size', dataIndex: 'exon_size' },
                { header: 'Exon rank', dataIndex: 'exon_rank' },
                { header: 'Canonical transcript', dataIndex: 'canonical_transcript' },
                // { header: 'Species id', dataIndex: 'species_id' },
                { header: 'Assembly id', dataIndex: 'assembly_id' },
                { header: 'build id', dataIndex: 'build_id' },
                { header: 'Chr id', dataIndex: 'chr_id' },
                { header: 'Chr start', dataIndex: 'chr_start' },
                { header: 'Chr end', dataIndex: 'chr_end' },
                { header: 'Chr strand', dataIndex: 'chr_strand' },
                { header: 'Picked?', dataIndex: 'automatically_picked' },
                { header: 'Comment', dataIndex: 'comment' },
                { header: 'Gene id', dataIndex: 'gene_id' }
            ],

            columnLines: true,
            viewConfig: {
                stripeRows: true
            },

            // items: 
            //     {
            //         xtype: 'DesignTargetsView'
            //     },

            renderTo: 'DesignTargetsDiv',

        });
    }
});
