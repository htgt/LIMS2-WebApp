//utility function to highlight a string, taken from WGE
//result_obj is optional, used if you want additional data in the returned result
String.prototype.match_str = function(q, result_obj) {
  //make sure the lengths are the same, technically we don't need this though we'd just truncate
  if (q.length != this.length) {
    return { "str": "error - size mismatch", "total": -1 };
  }

  var result = "";
  var total = 0;

  for (var i = 0; i < this.length; i++) {
    if (this.charCodeAt(i) ^ q.charCodeAt(i)) {
        result += "<span class='mismatch'>" + q.charAt(i) + "</span>";
        total++;
    }
    else {
        result += q.charAt(i)
    }
  }

  //blank object if user didnt provide one
  result_obj = result_obj || {};

  //var res = { "str": result, "total": total };

  result_obj.str   = result;
  result_obj.total = total;

  return result_obj;
}
