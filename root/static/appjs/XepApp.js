Ext.application({
    name: 'XepApp',
    appFolder: '/static/appjs',
    autoCreateViewport: false,
    models: ['Plate', 'PlateWell'],
    stores: ['Plates', 'PlateResults'],
    launch: function() {
        // This is fired as soon as the page is ready
        renderTo: 'XepAppDiv'
    }
});
