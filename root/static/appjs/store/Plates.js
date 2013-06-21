/*
 * extJS store names are plural, by convention
 */
Ext.define('XepApp.store.Plates', {
    extend: 'Ext.data.Store',
    requires: 'XepApp.model.Plate',
    model: 'XepApp.model.Plate'
});
