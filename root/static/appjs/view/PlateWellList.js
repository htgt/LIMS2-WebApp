/*
 * View for the grid that displays the wells on a plate
 * that the user will select for pooling
 */
Ext.define('XepApp.view.PlateWellList', {
    extend: 'Ext.grid.Panel',
    alias:  'platewells', // Remember that this becomes the xtype
    store:  'PlateWells'
});
