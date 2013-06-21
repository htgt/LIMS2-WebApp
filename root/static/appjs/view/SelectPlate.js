/*
 * View for the exising plate combo selector
 *
 */
Ext.define('XepApp.view.SelectPlate', {
    extend:     'Ext.form.field.ComboBox',
    alias:      'widget.platelist', //This becomes the xtype
    store:      'ExistingPlateList'
});
