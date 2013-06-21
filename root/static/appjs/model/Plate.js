Ext.define('XepApp.model.Plate', {
    extend: 'Ext.data.Model',
    fields: ['id', 'plate_name'],

    proxy: {
        type: 'ajax',
        url: 'data/ExistingPlateList.json',
        reader: {
            type: 'json',
            root: 'results'
        }
    }
});
