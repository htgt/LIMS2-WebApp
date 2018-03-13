window.onload = function(){
  document.getElementById("projectheader").click();
  document.getElementById("crisprheader").click();
  document.getElementById("designheader").click();

  $("#table_tooltip").tooltip({
      placement : 'top'
  });

  $(".project_info_btn").tooltip({
      placement : 'top'
  });

  $("#find_assembly_ii_experiments").tooltip({
      placement : 'top'
  });

  $("#ep_ii_plate_tooltip").tooltip({
      placement : 'right'
  });

  $("#save_assembly_ii").tooltip({
      placement : 'top'
  });

  $("#find_assembly_ii_project").tooltip({
      placement : 'top'
  });

  $("#expand_table").tooltip({
      placement : 'top'
  });

};

function populate_project_section(project_id) {
  reset_wells();
  var btns = document.getElementsByClassName("project_info_btn");
  for (i=0; i<btns.length; i++) {
    btns[i].style.removeProperty("background-color");
  }
  document.getElementById(project_id).style.backgroundColor = "#A3E1CC";
  var info = document.getElementById(project_id).value;
  var elems = info.split(',');

  for (i=0; i < elems.length; i++) {
    var key_val = elems[i].split("-");
    if (key_val[0] != "targeting_type_assembly_ii" ) {
      document.getElementById(key_val[0]).value = key_val[1];
    } else {
      if (key_val[1] == "single_targeted") {
        document.getElementById("single_targeted").checked = true;
        document.getElementById("double_targeted").checked = false;
      } else {
        document.getElementById("single_targeted").checked = false;
        document.getElementById("double_targeted").checked = true;
      }
    }
  }

}

function create_project_check() {
  var gene = document.getElementById('gene_id_assembly_ii').value.trim();
  var single_targeted = document.getElementById('single_targeted').checked;
  var double_targeted = document.getElementById('double_targeted').checked;
  var cell_line = document.getElementById('cell_line_assembly_ii').value.trim();
  var strategy = document.getElementById('strategy_assembly_ii').value.trim();

  if (!gene) {
    alert('Gene name is missing.');
    return false;
  }
  if ((!single_targeted) && (!double_targeted)) {
    alert('Targeting Type is missing.');
    return false;
  }
  if (!cell_line) {
    alert('Cell line is missing.');
    return false;
  }
  if (!strategy) {
    alert('Strategy is missing.');
    return false;
  }
  return true;
}

function find_project_check() {
  var gene = document.getElementById('gene_id_assembly_ii').value.trim();
  if (!gene) {
    alert('Gene name is missing.');
    return false;
  }
  return true;
}

function create_exp_check() {
  var gene = document.getElementById('gene_id_assembly_ii').value.trim();
  var crispr = document.getElementById('crispr_id_assembly_ii').value.trim();
  var wge_crispr = document.getElementById('wge_crispr_assembly_ii').value.trim();
  var design = document.getElementById('design_id_assembly_ii').value.trim();
  var import_crispr = document.getElementById("import_assembly_ii_crispr").checked;

  if (!gene) {
    alert('Gene name is missing.');
    return false;
  }
  if ((!crispr) && (!wge_crispr)) {
    alert('Crispr is missing.');
    return false;
  }
  if ((!crispr) && (!import_crispr)) {
    alert('Use "import Crispr from WGE" checkbox.');
    return false;
  }
  if (!design) {
    alert('Design is missing.');
    return false;
  }
  return true;
}

function reset_wells() {
  var square_ids = ['well_01', 'well_02', 'well_03', 'well_04', 'well_05', 'well_06', 'well_07', 'well_08', 'well_09', 'well_10', 'well_11', 'well_12', 'well_13', 'well_14', 'well_15', 'well_16'];
  for (i = 0; i < square_ids.length; i++) {
    document.getElementById(square_ids[i]).value = '';
    document.getElementById(square_ids[i]).style.display = 'none';
  }

  var square_labels = ['well_01_label', 'well_02_label', 'well_03_label', 'well_04_label', 'well_05_label', 'well_06_label', 'well_07_label', 'well_08_label', 'well_09_label', 'well_10_label', 'well_11_label', 'well_12_label', 'well_13_label', 'well_14_label', 'well_15_label', 'well_16_label'];
  for (i = 0; i < square_labels.length; i++) {
    document.getElementById(square_labels[i]).innerHTML = '';
  }
}

function view_toggle (target_id) {
  var object = document.getElementById(target_id);
  if (object.style.display == 'none') {
    object.style.display = 'block';
  } else if (object.style.display == 'block') {
    object.style.display = 'none';
  }
}

function dragstart_handler(ev) {
  ev.dataTransfer.setData("text/plain", ev.target.id);
}

function dragover_handler(ev) {
  ev.preventDefault();
  //ev.dataTransfer.dropEffect = "move";
}

function drop_handler(ev) {
  ev.preventDefault();
  var data = ev.dataTransfer.getData("text/plain");
  // remove any existing experiments DIV
  var children = ev.target.children;

  for (i=0; i<children.length; i++) {
    if (children[i].className == 'experiment_well') {
      if (children[i].value == '') {
        children[i].value = data;
//        children[i].style.width = '60px';
//        children[i].style.height = '20px';
//        children[i].style.display = 'block';
//        children[i].style.color = 'red';
      }
    }
    if (children[i].className == 'label label-danger') {
        children[i].innerHTML = data;
      }
  }
}

function scaleup(square_id) {
  document.getElementById(square_id).style.transform = "scale(1.5)";
  document.getElementById(square_id).style.zIndex = "1";
  document.getElementById(square_id).style.position = "relative";
  document.getElementById(square_id).style.transitionDuration = "0.1s";
  document.getElementById(square_id).style.opacity = "0.8";
}

function scaledown(square_id) {
  document.getElementById(square_id).style.transform = "";
  document.getElementById(square_id).style.zIndex = "0";
  document.getElementById(square_id).style.position = "";
  document.getElementById(square_id).style.transitionDuration = "";
  document.getElementById(square_id).style.opacity = "0.5";
}

function refresh_square(square_id) {
  var square = document.getElementById(square_id);
  var children = square.children;
  for (i=0; i<children.length; i++) {
    if (children[i].className == 'experiment_well') {
      children[i].value = '';
    }
    if (children[i].className == 'label label-danger') {
        children[i].innerHTML = '';
    }
  }
}

function save_plate_check() {
  var plate_name = document.getElementById('assembly_ii_plate_name').value.trim();
  var cell_line = document.getElementById('cell_line_assembly_ii').value.trim();
  if (!plate_name) {
    alert('Plate name is missing.');
    return false;
  }
  if (!cell_line) {
    alert('Cell line is missing.');
    return false;
  }
  var flag = false;
  var square_ids = ['well_01', 'well_02', 'well_03', 'well_04', 'well_05', 'well_06', 'well_07', 'well_08', 'well_09', 'well_10', 'well_11', 'well_12', 'well_13', 'well_14', 'well_15', 'well_16'];
  for (i = 0; i < square_ids.length; i++) {
    var temp_value = document.getElementById(square_ids[i]).value;
    if (temp_value != '') {
      flag = true;
    }
  }
  if (!flag) {
    alert('Well data is missing.');
    return false;
  }

  return true;
}

function save_add_exp_check() {
  var gene = document.getElementById('gene_id_assembly_ii').value.trim();
  var cell_line = document.getElementById('cell_line_assembly_ii').value.trim();
  var strategy = document.getElementById('strategy_assembly_ii').value.trim();
  var single_targeted = document.getElementById('single_targeted').checked;
  var double_targeted = document.getElementById('double_targeted').checked;

  if (!cell_line) {
    alert('Cell line is missing.');
    return false;
  }
  if (!gene) {
    alert('Gene is missing.');
    return false;
  }
  if (!strategy) {
    alert('strategy is missing.');
    return false;
  }
  if ((!single_targeted) && (!double_targeted)) {
    alert('Targeting type is missing.');
    return false;
  }
  return true;
}

