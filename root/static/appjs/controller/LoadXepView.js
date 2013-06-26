Ext.define('XepApp.controller.LoadXepView', {
    extend: 'Ext.app.Controller',

    views: ['ViewDiv'],

    init: function() {
        console.log('Initialized Load Xep View');
        this.control({
        'container > panel': {
            render: this.onPanelRendered
        }
        });
    },

    onPanelRendered: function() {
        console.log('The panel was rendered');
    }
});
