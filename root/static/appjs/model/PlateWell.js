/*
 * extJS model names are singular, by convention
 */
Ext.define('XepApp.model.PlateWell', {
    extend: 'Ext.data.Model',
    fields: ['id', 'plate_name', 'well_name'],

    proxy: {
        type: 'ajax',
        url: 'data/PlateWells.json',
        reader: {
            type: 'json',
            root: 'results'
        }
    }
});
