function extract_sequence(elem) {
    if ( elem.text().match(/(?:No alignment)|(?:No Read)/) ) return "";

    var m = elem.text().match(/([ACGTNacgtn]+)/g);
    if ( ! m ) return "";

    return m.join("").toUpperCase();
}

(function ($) {
        function init(plot) {
            plot.hooks.processOptions.push(processLabels);
            plot.hooks.draw.push(draw);
        }

        function processLabels(plot, options) {
            //add to plot so its 1 set of labels per plot
            plot.labels       = options.labels;
            plot.labelFont    = options.labelFont;
            plot.labelPadding = options.labelPadding;
        }

        function draw(plot, ctx) {
            ctx.save();

            var all_series = plot.getData();
            //ctx.fillStyle = series[0].cColor;
            ctx.font = plot.labelFont;

            //console.log( plot.width(), plot.height() );

            /* really we only want to draw once, not per series */
            var x = plot.getAxes().xaxis;

            plot._pos = x.min;
            var reads = [];
            for ( var i = 0; i < plot.labels.length; i++ ) {
                var label = plot.labels[i];
                //only show values within the range we're looking
                if ( label.x < x.min || label.x > x.max ) {
                    //console.log(label.x + " < " + x.min + " || " + label.x + " > " + x.max);
                    continue;
                }

                //need to deal with N separately
                var series = all_series[label.series];

                ctx.fillStyle = series.color;

                //should maybe plot at the top instead of above the peak, but above the peak
                //seems more logical? y values will break when y zooming
                var loc = plot.pointOffset({ x: label.x, y: label.y });

                if (loc.left > 0)
                    drawNucleotide(series, label.nuc, loc.left, loc.top);
                    reads.push(label);
            }

            // sort reads left to right to produce sequence search string
            reads.sort(function(a, b){
              if(a.x == b.x) return 0;
              return a.x > b.x ? 1 : -1;
            });
            var read = "";
            $.each(reads, function(i,label){ read += label.nuc });
            plot._read = read;
            // If we can find the trace_sequence preceding the plot highlight the
            // search sequence string within it
            var seq_td = plot.getPlaceholder().parents("tr").prev().children(".trace_sequence");
            if(seq_td){
              var context = seq_td.text().split(read);
              if(context[2]){
                // search sequence must be repeated. do not attempt to highlight.
                // remove previous highlighing
                seq_td.html(seq_td.text());
              }
              else{
                var highlighted = "<span class='traceviewer_highlight'>" + read + "</span>";
                var new_html = context.join(highlighted);

                seq_td.html(new_html);
              }
              //console.log(new_html + " new_html");
            }

            // If we have coloured_seq spans above the plot then highlight this
            var seqs = plot.getPlaceholder().parents("td").find(".coloured_seq");
            if(seqs){
                var seq;
                var direction;
                if( plot.getPlaceholder().hasClass("reverse") ){
                    seq = seqs.last();
                    direction = "rev";
                }
                else{
                    // default is to link to forward read
                    seq = seqs.first();
                    direction = "fwd";
                }

                var seq_string = extract_sequence($(seq));

                // Find position of traceviewer read within seq_string
                var start = seq_string.indexOf(read);

                // read is found only once
                if(start > -1 && seq_string.lastIndexOf(read) == start){
                    var end = start + read.length;

                    // Loop through coloured seq spans, ignoring "-" for deleted region
                    // Add border to bases in the traceviewer read range
                    var span_start = 0;
                    seq.children().each(function(i,span){
                        var span_seq = extract_sequence($(span));
                        if(span_seq.length){
                            var before = span_seq.substring(0, start - span_start);
                            var read = span_seq.substring(start - span_start, end - span_start);
                            var after = span_seq.substring(end - span_start, span_seq.length);

                            var span_html = "";
                            if(before.length){
                                span_html+=before;
                            }
                            if(read.length){
                                var style = "border-style:solid;border-color:black;";
                                if(end > span_start + span_seq.length){
                                    style+="border-right-style:none;";
                                }
                                if(start < span_start){
                                    style+="border-left-style:none";
                                }

                                span_html+="<span id='" + direction + "' style='" + style + "'>"
                                           + read + "</span>";
                            }
                            if(after.length){
                                span_html+=after;
                            }
                            $(span).html(span_html);
                        }
                        else{
                            // No sequence content - keep old span as it is
                        }

                        span_start += span_seq.length;
                    });
                }
                else{
                    // read from traceviewer not found in sequence string
                    // remove existing highlighting
                    seq.children().each(function(i,span){
                        $(span).html( $(span).text() );
                    });
                }

            }

            ctx.restore();

            function drawNucleotide(series, nuc, x, y) {
                //console.log("Drawing at: " + x + ", " + y);
                var radius = series.points.radius;
                var tWidth = ctx.measureText(nuc).width;

                switch (series.labelPlacement) {
                    case "above":
                        x -= tWidth / 2;
                        y -= (plot.labelPadding + radius);
                        ctx.textBaseline = "bottom";
                        break;
                    case "left":
                        x -= tWidth + plot.labelPadding + radius;
                        ctx.textBaseline = "middle";
                        break;
                    case "right":
                        x += plot.labelPadding + radius;
                        ctx.textBaseline = "middle";
                        break;
                    case "axis":
                        x -= tWidth / 2;
                        y = plot.getAxes().xaxis.box.top;
                    default:
                        ctx.textBaseline = "top";
                        y += plot.labelPadding + radius;
                        x = x - tWidth / 2;
                }
                ctx.fillText(nuc, x, y);
            }
        }




        var options = {
            labels: [],
            labelFont: "9px, san-serif",
            labelPadding: 4,
            series: {
                labelPlacement: "axis",
                cColor: "#F00",
            }
        };

        $.plot.plugins.push({
            init: init,
            options: options,
            name: "traceviewer",
            version: "0.1"
        });
})(jQuery);

//add a TraceViewer object for easy creation of plots
//this is incredibly specific to our layout, though.

function TraceViewer(trace_url, button, full_trace, version) {
    if ( ! button && trace_url ) {
        console.log("Please provide a trace button and trace URL");
        return;
    }

    this._pos = 250;
    this._read = 'A';
    this._initPos = 250;
    this._ref = [];
    this._locHash = new Object();
    this.url = trace_url;
    this.show_traces(button, full_trace, version);
}

TraceViewer.prototype.toString = function() { return "TraceViewer"; };

TraceViewer.prototype.show_traces = function(button, full_trace, version) {
    //create container divs with placeholder divs inside to hold the required graphs
    //graphs. Placeholder is where the graph actually gets isnerted
    var fwd_placeholder = $("<div>", {"class":"demo-placeholder forward"});
    this.fwd_container   = $("<div>", {"class":"demo-container"} ).append( fwd_placeholder );

    var rev_placeholder = $("<div>", {"class":"demo-placeholder reverse"});
    this.rev_container   = $("<div>", {"class":"demo-container"} ).append( rev_placeholder );

    //pull up the coloured sequence that is nearby to our button
    var seqs = button.parent().find(".coloured_seq");

    //should maybe just do this in perl and always take forward/rev_full
    //if there's a full sequence take it, if not strip away everythign but the nucleotides
    var fwd_seq = button.closest("td").find(".forward_full").text() || extract_sequence( seqs.first() );
    var rev_seq = button.closest("td").find(".reverse_full").text() || extract_sequence( seqs.last() );

    // We want to display the full trace, not search for a sequence within in
    if(full_trace){
        fwd_seq = "";
        rev_seq = "";
    }

    this.create_plot(fwd_placeholder, button.data("fwd"), fwd_seq, 0, button.data("context"), "fwd", version);
    this.create_plot(rev_placeholder, button.data("rev"), rev_seq, 1, button.data("context"), "rev", version);

    // create button to hide the traces and restore the "View Traces" button
    var hide_button = $("<a>",{
        "class":"btn btn-info hide-traces",
        "text":"Hide Traces",
        "click": function(){
            // remove sequence highlighting
            var seq_td = $(this).parents("tr").prev().children(".trace_sequence");
            if(seq_td){
                seq_td.html( seq_td.text() );
            }

            // remove coloured_seq highlighting
            var seqs = $(this).parents("td").find(".coloured_seq");
            $.each(seqs,function(i,seq){
                $(seq).children().each(function(i,span){
                    $(span).html( $(span).text() );
                });
            });

            // show the show button
            var div = $(this).parent();
            var show_button = div.prev();
            show_button.show();
            div.remove();
        }
     } );

    //add hide traces button and both the graphs into a single div and hide the "View Traces" button
    button.after( $("<div>").append(hide_button).append(this.fwd_container).append(this.rev_container) );
    button.hide();
};

//wait for data then give it to the real plot creation method
TraceViewer.prototype.create_plot = function(placeholder, name, search_seq, reverse, context, dir, version) {
    if ( ! name ) { placeholder.parent().hide(); return }; //skip if we do not have a read name

    //create local var for this, as "this" in getJSON is different
    var parent = this;
    var ref = [];

    //fetch the users data and add a new graph when the data comes back
    $.getJSON(
        this.url,
        {
            "name": name,
            "search_seq": search_seq,
            "reverse": reverse,
            "context": context,
            "version": version
        },
        function(data) {
            console.log(data.bases);
            for (var key in data.bases) {
                //console.log(key);
                ref.push(key);
            }

            for (i in ref) {
                var key = ref[i];
                var value = data.bases[key];
            }
            parent._create_plot(placeholder, data, dir, ref);
        }
    )
    .fail(function( jqxhr, textStatus, error ) {
        console.log( jqxhr.responseText );
    });
};

//function that actually creates the plot
TraceViewer.prototype._create_plot = function(placeholder, graph_data, dir, ref) {
    var set = graph_data.series[0]["data"];

    var left_boundary = parseInt(set[0][0]);

    var right_boundary = set[set.length - 1][0];

    var plot = $.plot(placeholder, graph_data.series, {
        labels: graph_data.labels,
        series: {
            lines: {
                show: true
            },
            shadowSize: 0
        },
        xaxis: {
            zoomRange: [50, set.length],
            panRange: [left_boundary, right_boundary],
            min: left_boundary,
            max: left_boundary+250,
            show: false,
            reserveSpace: true
        },
        yaxis: {
            zoomRange: [100, 10000],
            panRange: false,
            labelWidth: 60,
            show: true,
        },
        zoom: {
            interactive: false
        },
        pan: {
            interactive: true
        },
        legend: {
            show: false,
            position: "nw"
        }
    });
    plot._initPos = left_boundary;
    var refData = createReference(graph_data.labels);
    plot._indices = refData[0];
    plot._labels = refData[1];
    plot._ref = ref;
    plot._dir = dir;
    function addZoom(text, left, top, args) {
        $("<div class='button' style='left:" + left + "px;top:" + top + "px;width:7px;text-align:center'>" + text + "</div>")
        .appendTo(placeholder)
        .click(function (e) {
            e.preventDefault();
            plot.zoom( args );
        });
    }

    //todo: add a loop to do this rubbish
    $("<div style='left:2px;top:7px;width:7px;text-align:center;position:absolute;'>X</div>")
    .appendTo(placeholder);
    addZoom("+", 0, 25, {
        axis: "xaxis",
        center: { left: plot.width() / 2, top: plot.height() },
        amount: 1.2
    });
    addZoom("-", 0, 47, {
        axis: "xaxis",
        center: { left: plot.width() / 2, top: plot.height() },
        amount: 1/1.2
    });

    $("<div style='left:14px;top:7px;width:7px;text-align:center;position: absolute;'>Y</div>")
    .appendTo(placeholder);
    addZoom("+", 14, 25, {
        axis: "yaxis",
        center: { left: plot.width() / 2, top: plot.height() },
        amount: 1.2
    });
    addZoom("-", 14, 47, {
        axis: "yaxis",
        center: { left: plot.width() / 2, top: plot.height() },
        amount: 1/1.2
    });

    //make world accessible
    if (dir == "fwd") {
        this.fwd_plot = plot;
    } else {
        this.rev_plot = plot;
    }
};

TraceViewer.prototype.moveToPoint = function (plot, first, last) {
    var xaxis = plot.getAxes().xaxis;
    xaxis.min = first;
    xaxis.max = last;
    plot._pos = first;
    plot.draw(); //Leaves TV blank until page updates
    plot.pan(0); //Forces an update
};

function createReference(labels){
    var sorted_labels = labels.sort(function(a,b) {
        return a['x'] > b['x'];
    });
    var pos = [];
    var ref = [];
    sorted_labels.forEach(function(label) {
        pos.push(label.x);
        ref.push(label.nuc);
    });
    ref = ref.join("");
    return [pos,ref];
}
