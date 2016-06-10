// update crispr_es_qc_well values, one as a time
// the form textbox or checkbox object that triggers this must have following attributes
// data-crispr_data_type
// data-crispr_well_id
$(document).ready(function() {
    $(".update_crispr_es_qc_well").change(function() {

        // give warning class to element
        var element = $(this).parent().parent();
        element.removeClass('error').removeClass('success').addClass('warning');
        // grab data type and well_id
        var data_type = $(this).attr('data-crispr_data_type');
        var crispr_well_id = $(this).attr('data-crispr_well_id');
        var data = {};
        data['id'] = crispr_well_id;
        // if checkbox use checked, otherwise its value
        if ( $(this).attr('type') == 'checkbox' ) {
            data[data_type] = this.checked;
        }
        else {
            data[data_type] = this.value;
        }

        if ( data_type == 'damage_type' ) {
            var accepted_checkbox = $( '#accepted_' + crispr_well_id );
            if ( this.value == 'mosaic' || this.value == 'no-call' ) {
                accepted_checkbox.prop('checked', false);
                accepted_checkbox.prop('disabled', true);
            }
            else {
                accepted_checkbox.prop('disabled', false)
            }
        }

        // ajax request to update the crispr es qc well value
        $.ajax({
            type: "POST",
            url: api_url,
            data: data,
            success: function(data) {
                console.log(data);
                element.delay(500).queue(function(){
                    $(this).removeClass('warning').removeClass('error').addClass('success').dequeue();
                });
            },
            error: function(data) {
                console.log(data);
                element.addClass('error');
                element.delay(500).queue(function(){
                    $(this).removeClass('warning').removeClass('success').addClass('error').dequeue();
                });
                alert( 'Error updating crispr ' +  data_type + ', change not saved' );
            },
            dataType: 'json'
        });

    });
});
