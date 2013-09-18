Ext.application({
    requires: ['Ext.container.Container'], 
    name: 'DesignTargetsApp',
    autoCreateViewport: false,
    appFolder: '/static/appjs',
    //models: ['DesignTarget'],
    //stores: ['DesignTargets'],
    controllers: ['LoadDesignTargetsView'],

    launch: function() {
        // This is fired as soon as the page is ready
        Ext.create('Ext.container.Container', {
            renderTo: 'DesignTargetsDiv',
            layout: 'fit',
            items: 
                {
                    xtype: 'DesignTargetsView'
                }
        });
    }
});
