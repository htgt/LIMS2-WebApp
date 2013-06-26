Ext.application({
    requires: ['Ext.container.Container'], 
    name: 'XepApp',
    appFolder: '/static/appjs',
    autoCreateViewport: false,
//    models: ['Plate', 'PlateWell'],
//    stores: ['Plates', 'PlateResults'],
//    controllers: ['LoadXepView'],

    launch: function() {
        // This is fired as soon as the page is ready
        Ext.create('Ext.container.Container', {
            renderTo: 'XepAppDiv',
            layout: 'fit',
            items: [
                {
                    xtype: 'panel',
                    title: 'Plates',
                    html : 'List of plates will go here'
                }
            ]
        });
    }
});
