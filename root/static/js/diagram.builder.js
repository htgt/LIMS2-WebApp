/*
  This file is to help build diagrams like those required for the design creation page.
  It uses raphael to do all the drawing.
*/

/*
  this is basically a list used by DiagramBuilder, but each time you add a node it draws
  a line between them. it also keeps track of everything that has been added
  to the chain so more functionality could be added.
*/
function Diagram(diagramBuilder) {
  this._diagramBuilder = diagramBuilder;
  this._chain = []; 
  
  Diagram.prototype.lastElement = function() {
    return this._chain[this._chain.length - 1];
  }

  Diagram.prototype.addNode = function(node) {
    if (this._chain.length) {
      this._diagramBuilder._connectBoxes(this.lastElement(), node);
    }

    //return the index in case they want it.
    return this._chain.push(node);
  }

  Diagram.prototype.getNode = function(index) {
    return this._chain[index];
  }

  Diagram.prototype.empty = function() {
    this._chain = [];
  }
}

/*
HOW TO USE:
include Raphael, jquery and qtip2 for jquery as they are all required. 

Then add this html to your page somewhere:

<div id="diagram" style="position:relative;">
  <div id="holder" style="padding-top:20px">
  </div>
</div>

then in the js add something like:

$(document).ready(function() {
  var builder = new DiagramBuilder("holder", 850, 150);

  builder.addBox("G5");
  builder.addExon();

  //etc.
});

look at how its used on create_design page for a full usage example.

An underscore before a method/attribute means, changing it will break stuff.
*/
function DiagramBuilder(id, width, height) {
  this._paper =  Raphael(id, width, height);
  this._parentDiv = $("#" + id); //this is $("#holder") in my example
  this._textFields = []; //we store any text fields we create in here for easy cleanup

  //we have this so its easy to reset. these are just global positioning type stuff
  DiagramBuilder.prototype._createAttributes = function() {
    return {
      x: 2, //this gets updated as you add elements
      y: 10,
      width: 50,
      height: 40,
      spacing: 65,
      textWidth: 50
    };
  };

  this._attributes = this._createAttributes();
  this._chain = new Diagram(this);

  //used to automatically space elements added to the chain
  DiagramBuilder.prototype._getElementAttributes = function(width) {
    //allow the user to optionally specify a width, if not use default
    width = (typeof width === "undefined") ? this._attributes.width : width;

    //we need to update this value before we return, so store it.
    var nextX = this._attributes.x;

    //update the value ready for the next element
    this._attributes.x = nextX + width + this._attributes.spacing;

    //copying objects is non trivial in js so just do this
    return {x: nextX, y: this._attributes.y, width: width, height: this._attributes.height};
  };

  //destroy everything
  DiagramBuilder.prototype.clearDiagram = function() {
    this._paper.clear();
    //now remove all text fields. could have just used a jquery selector
    for(var i=0; i<this._textFields.length; i++) {
      this._textFields[i].remove();
    }

    //reset all the variables
    this._textFields = [];
    this._chain.empty();
    this._attributes = this._createAttributes();
  };

  //if someone needs to do some more ADVANCED things they may ened the paper instance
  DiagramBuilder.prototype.getPaper = function() {
    return this._paper;
  };

  //draw a line between any two elements
  DiagramBuilder.prototype._connectBoxes = function(first, second) {
    var first_coords = first.getBBox();
    var second_coords = second.getBBox();

    var start = first_coords.x2 + "," + ( first_coords.y + first_coords.height/2 );
    var end = second_coords.x + "," + ( second_coords.y + second_coords.height/2 );

    return this._paper.path( "M" + start + "L" + end + "z" );
  };

  DiagramBuilder.prototype.addBox = function(text) {
    var attrs = this._getElementAttributes();
    //draw the box
    var box = this._paper.rect(attrs.x, attrs.y, attrs.width, attrs.height).attr({
      "fill": "#356AA0", 
      "stroke-width": 1.5, 
      "fill-opacity": 0.2
    });
    var text = this._paper.text(attrs.x + (attrs.width/2), attrs.y + (attrs.height/2), text).attr({
      "font-size": 16,
      "font-weight": "bold"
    });

    //add the new element to our chain
    this._chain.addNode(box);

    return box;
  };

  DiagramBuilder.prototype.addExon = function() {
    var attrs = this._getElementAttributes(70); //make these slightly wider
    //label all the different co-ordinates we use to (attempt to) make the code more readable.
    var coords = {
      boxLeft: attrs.x, 
      boxRight: attrs.x+attrs.width*0.7, //the actual box part only comes out 70% of the way, the remaining 30% is the point
      boxTop: attrs.y, 
      boxBottom: attrs.y+attrs.height, 
      pointX: attrs.x+attrs.width, //this is the pointed part on the side of the box
      pointY: attrs.y+attrs.height/2
    }

    var lines = [
      {x: coords.boxLeft, y: coords.boxTop}, //initial start
      {x: coords.boxRight, y: coords.boxTop}, //top line of box
      {x: coords.pointX, y: coords.pointY}, //diagonal down to point
      {x: coords.boxRight, y: coords.boxBottom}, //back in to box
      {x: coords.boxLeft, y: coords.boxBottom} //bottom line of box
    ];

    //build the lines array
    var path_str = "M";
    for (var i=0; i<lines.length; i++) {
      path_str += lines[i].x + "," + lines[i].y + ",";
    }

    path_str = path_str.slice(0, -1) + "z"; //remove trailing "," and add z to complete the shape

    //create the path object and set its attributes
    var path = this._paper.path(path_str).attr({
      "stroke-width": 1.5,
      "fill": '#3F4C6B',
    });

    //now add the EXON label
    this._paper.text(attrs.x+((attrs.width*0.7)/2), attrs.y+(attrs.height/2), "Exon").attr({
      "fill": "#fff",
      "font-size": 16,
      "font-weight": "bold"
    });

    this._chain.addNode(path);

    return path; 
  };

  //critical just has the colour changed
  DiagramBuilder.prototype.addCriticalExon = function() {
    return this.addExon().attr("fill", "#CC0000");
  };

  DiagramBuilder.prototype._createArrow = function(x, y, type, to) {
    //type is H or V
    return this._paper.path("M" + x + "," + y + type + to).attr({
      "stroke-width": 2,
      "arrow-end": "classic-wide-long"
    });
  };

  DiagramBuilder.prototype.addField = function(box, name, defaultValue, title, placement) {
    var coords = box.getBBox();

    var offset = coords.x; //default placement is directly above the element
    if (placement == "before") {
      offset = coords.x - this._attributes.textWidth; //using the actual width makes the box too far in
    } 
    else if (placement == "after") {
      offset = coords.x2 + 5;
    }

    //make a new input field and position it relative to the provided box
    var field = $("<input type='text' name='" + name + "' id='" + name + "' value='" + defaultValue + "' placeholder='"+title+"' />")
      .css( {
        position: "absolute", 
        left: (offset-2) + "px", //offset from left of div to correct position 
        width: this._attributes.textWidth,
        padding: 0,
        "z-index": 100
      } )
      .insertBefore( this._parentDiv );
    
    //add tooltip as a label
    field.qtip({
        content: { attr: 'placeholder' },
        position: { my: "bottomMiddle", at:"topMiddle" },
        style: { classes: 'qtip-blue' }
    });

    //we store all the text fields so we can easily delete them
    this._textFields.push(field);

    return field;
  }

  DiagramBuilder.prototype.addLabel = function(first, second, text, orientation, name, defaultValue) {
    //this will make a |<-- 5' retrieval arm length -->| or whatever label underneath two elements.
    //it will also add a text box inline with the text
    var first_coords = first.getBBox();
    var second_coords = second.getBBox();

    //what if they're not level? everything will break.
    var y_offset = 10; //how much space to leave after elements
    var line_height = 60; //height of the label
    var text_offset = 15; //how far the text is from the line

    var coords = {
      y: first_coords.y2 + y_offset
    };

    coords.y2 = coords.y + line_height;
    coords.yCentre = coords.y + line_height/2;

    //allow the function to draw arrows at different points:
    if(orientation == "left") { 
      coords.x = first_coords.x; //start at the start of the first element
      coords.x2 = second_coords.x; //end at the start of the last element
    } else if (orientation == "right") {
      coords.x = first_coords.x2; //start at the end of the first element
      coords.x2 = second_coords.x2; //end at the end of the last element
    } else {
      coords.x = first_coords.x; //by default start of first -> end of last.
      coords.x2 = second_coords.x2;
    }

    coords.xCentre = coords.x + Math.abs(coords.x - coords.x2)/2;

    //create the path string to draw a vertical line under each element
    var left_line = "M" + coords.x + "," + coords.y  + "V" + coords.y2;
    var right_line = "M" + coords.x2 + "," + coords.y + "V" + coords.y2;

    var path = this._paper.path(left_line + right_line);

    //make a double ended arrow in the middle of the two lines we just drew
    this._createArrow(coords.xCentre, coords.yCentre, "H", coords.x);
    this._createArrow(coords.xCentre, coords.yCentre, "H", coords.x2);

    //write the text and centre it accounting for the text box
    var textF = this._paper.text(coords.xCentre-this._attributes.textWidth/2, coords.yCentre+text_offset, text).attr({"font-size": 14});

    //create the text box and adjust its y position. we're kind of just hacking around the addField function here really.
    var field = this.addField(textF, name, defaultValue, text, "after");
    //we have to add 10 to adjust for the padding on our div. 
    field.css( { top: coords.yCentre+text_offset+10 } ); //adjust y position as the function doesnt do that

    return path;
  };
};