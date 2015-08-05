function getCell(column_name, id_column_name, row_name) {
    // column_name is the name of the column contaning the cell we want
    // id_column_name is the name of the id column we look in to find the row_name
    var column_index = getColumnIndexByName(column_name);
    var id_column_index = getColumnIndexByName(id_column_name) + 1;

    var id_column = $('table tr td:nth-child(' + id_column_index + ')');
    var row = id_column.filter(function(){
      return ($(this).text().trim() == row_name)
    }).closest('tr');
    return row.find('td').eq(column_index);
}

function getColumnIndexByName(column_name){
    if(!$("table th:contains(" + column_name + ")").length){
      console.log("table does not contain column named " + column_name);
      return;
    }

    return $("table th:contains(" + column_name + ")").index();
}

var valid_label = '<span class="label label-success validation-status pull-right">Validated</span>';
var not_valid_label = '<span class="label label-default validation-status pull-right">Not Validated</span>';
var button_html = '<button class="btn btn-mini">Change validation state</button>';

function addPrimerValidationState(cell, api_url, object_id_param, object_id, primer_type, is_validated){

  $(button_html).appendTo(cell).click(function(e){
    var this_cell = $(this).parent();
    var uri = api_url + "?" + object_id_param + "=" + object_id + "&primer_type=" + primer_type;
    $.ajax(uri).done(function(data){
      console.log(data);
      if(data.success){
        this_cell.children('.validation-status').remove();
        if(data.is_validated == 1){
          this_cell.append(valid_label);
        }
        else{
          this_cell.append(not_valid_label);
        }
      }
      else{
        console.log('primer validation status change failed with error ' + data.error);
        // if not successful we change nothing..
      }
    });
  });

  if(is_validated){
    cell.append(valid_label);
  }
  else{
    cell.append(not_valid_label);
  }
}
