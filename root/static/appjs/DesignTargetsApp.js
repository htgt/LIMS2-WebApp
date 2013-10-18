Ext.application({
    requires: ['Ext.grid.Panel', 'Ext.form.*'], 
    name: 'DesignTargetsApp',
    frame: false,
    autoCreateViewport: false,
    appFolder: '../static/appjs',
    models: ['DesignTarget'],
    stores: ['DesignTargets'],
    controllers: ['LoadDesignTargetsView'],

    launch: function() {
        // This is fired as soon as the page is ready

        Ext.create('Ext.FormPanel', {
            title: 'Project Selection',
            frame: true,
            fieldDefaults: {
                labelWidth: 110
            },
            width: 1170,
            renderTo: 'SelectProjectDiv',
            bodyPadding: 10,
            items: [{
                xtype: 'radiogroup',
               // fieldLabel: 'Auto Layout',
                cls: 'x-check-group-alt',
                items: [
                    {boxLabel: 'Core', name: 'rb-auto', inputValue: 1, checked: true},
                    {boxLabel: 'Cre Knockin', name: 'rb-auto', inputValue: 2},
                    {boxLabel: 'Pathogens', name: 'rb-auto', inputValue: 3},
                    {boxLabel: 'Syboss', name: 'rb-auto', inputValue: 4}
                    //,{boxLabel: 'Item 5', name: 'rb-auto', inputValue: 5}
                ]
            }],
            buttons: [{
                text: 'Go',
                handler: function(){
                    Ext.create('Ext.grid.Panel', {
                        title: 'Design Targets List: Core Project',
                        store: 'DesignTargets',
                        // store: Ext.data.StoreManager.lookup('DesignTargets'),
                        layout: 'fit',
                        height: 750,
                        width: 1170,
                        autoScroll: true,

                        columns: [
                            // { header: 'ID', dataIndex: 'id' },
                            { header: 'Marker Symbol', dataIndex: 'marker_symbol', type: 'string' },
                            { header: 'Ensembl gene id', dataIndex: 'ensembl_gene_id', type: 'string', width: 150 },
                            { header: 'Ensembl exon id', dataIndex: 'ensembl_exon_id', type: 'string', width: 150 },
                            { header: 'Exon size', dataIndex: 'exon_size', width: 50 },
                            { header: 'Exon rank', dataIndex: 'exon_rank', width: 50 },
                            { header: 'Canonical transcript', dataIndex: 'canonical_transcript', type: 'string', width: 150 },
                            // { header: 'Species id', dataIndex: 'species_id' },
                            // { header: 'Assembly id', dataIndex: 'assembly_id' },
                            { header: 'build id', dataIndex: 'build_id', width: 50 },
                            { header: 'Chr id', dataIndex: 'chr_id', width: 50 },
                            { header: 'Chr start', dataIndex: 'chr_start' },
                            { header: 'Chr end', dataIndex: 'chr_end' },
                            { header: 'Chr strand', dataIndex: 'chr_strand', width: 60, 
                                renderer : function(val) {
                                    if (val > 0) {
                                        return 'forward';
                                    } else if (val < 0) {
                                        return 'reverse';
                                    }
                                    return val;
                                },
                            },
                            { header: 'Picked?', dataIndex: 'automatically_picked', width: 50,
                                renderer : function(val) {
                                    if (val > 0) {
                                        return '<span style="color:' + 'green' + '">yes</span>';
                                    } else {
                                        return '<span style="color:' + 'red' + '">no</span>';
                                    }
                                },
                            },
                            // { header: 'Comment', dataIndex: 'comment' },
                            { header: 'Gene id', dataIndex: 'gene_id' },
                            { header: '# Designs', dataIndex: 'design_count', width: 50 },
                            { header: 'Designs', dataIndex: 'designs', type: 'string' },
                            { header: 'Crisprs', dataIndex: 'crisprs', width: 50 }
                        ],

                        columnLines: true,
                        viewConfig: {
                            enableTextSelection: true,
                            stripeRows: true
                        },

                        // items: 
                        //     {
                        //         xtype: 'DesignTargetsView'
                        //     },

                        renderTo: 'DesignTargetsDiv',

                    });
                }
            }]
        });




        // Ext.create('Ext.grid.Panel', {
        //     title: 'Design Targets List: Core Project',
        //     store: 'DesignTargets',
        //     // store: Ext.data.StoreManager.lookup('DesignTargets'),
        //     layout: 'fit',
        //     height: 750,
        //     width: 1170,
        //     autoScroll: true,

        //     columns: [
        //         // { header: 'ID', dataIndex: 'id' },
        //         { header: 'Marker Symbol', dataIndex: 'marker_symbol', type: 'string' },
        //         { header: 'Ensembl gene id', dataIndex: 'ensembl_gene_id', type: 'string', width: 150 },
        //         { header: 'Ensembl exon id', dataIndex: 'ensembl_exon_id', type: 'string', width: 150 },
        //         { header: 'Exon size', dataIndex: 'exon_size', width: 50 },
        //         { header: 'Exon rank', dataIndex: 'exon_rank', width: 50 },
        //         { header: 'Canonical transcript', dataIndex: 'canonical_transcript', type: 'string', width: 150 },
        //         // { header: 'Species id', dataIndex: 'species_id' },
        //         // { header: 'Assembly id', dataIndex: 'assembly_id' },
        //         { header: 'build id', dataIndex: 'build_id', width: 50 },
        //         { header: 'Chr id', dataIndex: 'chr_id', width: 50 },
        //         { header: 'Chr start', dataIndex: 'chr_start' },
        //         { header: 'Chr end', dataIndex: 'chr_end' },
        //         { header: 'Chr strand', dataIndex: 'chr_strand', width: 60, 
        //             renderer : function(val) {
        //                 if (val > 0) {
        //                     return 'forward';
        //                 } else if (val < 0) {
        //                     return 'reverse';
        //                 }
        //                 return val;
        //             },
        //         },
        //         { header: 'Picked?', dataIndex: 'automatically_picked', width: 50,
        //             renderer : function(val) {
        //                 if (val > 0) {
        //                     return '<span style="color:' + 'green' + '">yes</span>';
        //                 } else {
        //                     return '<span style="color:' + 'red' + '">no</span>';
        //                 }
        //             },
        //         },
        //         // { header: 'Comment', dataIndex: 'comment' },
        //         { header: 'Gene id', dataIndex: 'gene_id' },
        //         { header: '# Designs', dataIndex: 'design_count', width: 50 },
        //         { header: 'Designs', dataIndex: 'designs', type: 'string' },
        //         { header: 'Crisprs', dataIndex: 'crisprs', width: 50 }
        //     ],

        //     columnLines: true,
        //     viewConfig: {
        //         enableTextSelection: true,
        //         stripeRows: true
        //     },

        //     // items: 
        //     //     {
        //     //         xtype: 'DesignTargetsView'
        //     //     },

        //     renderTo: 'DesignTargetsDiv',

        // });
    }
});
