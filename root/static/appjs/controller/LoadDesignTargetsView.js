Ext.define('DesignTargetsApp.controller.LoadDesignTargetsView', {
    extend: 'Ext.app.Controller',

    views: ['DesignTargetsView'],

    init: function() {
        console.log('Initialized Design Targets View');
        this.control({
        'container > panel': {
            render: this.onPanelRendered
        }
        });
    },

    onPanelRendered: function() {
        console.log('The panel was rendered');
        console.log(url_for_json);
    }
});