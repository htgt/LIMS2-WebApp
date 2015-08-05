function addQCVerifiedLabel(cell,value){
  console.log('Value: ' + value);
  if(value === null){
    cell.html('');
    return;
  }

  if(value.match(/1/)){
    console.log('true');
    cell.html('<span class="label label-success">Good</span>');
  }
  else if(value.match(/0/)){
    console.log('false');
    cell.html('<span class="label label-warning">Not Good</span>');
  }
  else{
    console.log('undefined');
    cell.html('');
  }
}