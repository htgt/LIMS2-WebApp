Ext.define('DesignTargetsApp.store.DesignTargets', {
    extend: 'Ext.data.Store',
    requires: 'DesignTargetsApp.model.DesignTarget',
    model: 'DesignTargetsApp.model.DesignTarget',
    autoLoad: true,




    // proxy: {
    //     type: 'ajax',
    //     url: '/static/appjs/data/DesignTargetsExample.json',
    //     reader: {
    //         type: 'json',
    //         root: 'results',
    //         successProperty: 'success'
    //     }
    // },



    proxy: {
        type: 'rest',
        url: url_for_data,
        headers: {'Content-Type': 'application/json'},
        reader: {
            type: 'json' //,
            // root: 'results',
            // successProperty: 'success'
        }
    },


});

