Ext.define('XepApp.view.ViewDiv', {
    extend: 'Ext.container.Container',

//    requires: [
//        'XepApp.view.SelectPlate',
//        'XepApp.view.PlateWellList'
//    ],
// Layout is required, as the default is with the flow
    layout: 'fit',

    initComponent: function() {
        this.items = [
        {
            xtype: 'panel',
            dockedItems: [{
                dock: 'top',
                xtype: 'toolbar',
                height: 80,
                items: [{
                    xtype: 'platelist', // that came from the SelectPlate view definition
                    width: 150
                }, {
                    xtype: 'component',
                    html: 'XEP_POOL App'
                }]
            }],

            layout: {
                type: 'hbox',
                align: 'stretch'
            },

/*            items: [{
                width: 250,
                xtype: 'panel',
                layout: {
                      type: 'vbox',
                      align: 'stretch'
                }
            }]
*/            
        }
    ];
    }


});
