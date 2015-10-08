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

function TraceViewer(trace_url, button) {
    if ( ! button && trace_url ) {
        console.log("Please provide a trace button and trace URL");
        return;
    }

    this.url = trace_url;
    this.show_traces(button);
}

TraceViewer.prototype.toString = function() { return "TraceViewer"; };

TraceViewer.prototype.extract_sequence = function(elem) {
    if ( elem.text().match(/(?:No alignment)|(?:No Read)/) ) return "";

    var m = elem.text().match(/([ACGTNacgtn]+)/g);
    if ( ! m ) return "";

    return m.join("").toUpperCase();
};


TraceViewer.prototype.show_traces = function(button) {
    //create container divs with placeholder divs inside to hold the required graphs
    //graphs. Placeholder is where the graph actually gets isnerted
    var fwd_placeholder = $("<div>", {"class":"demo-placeholder"});
    this.fwd_container   = $("<div>", {"class":"demo-container"} ).append( fwd_placeholder );

    var rev_placeholder = $("<div>", {"class":"demo-placeholder"});
    this.rev_container   = $("<div>", {"class":"demo-container"} ).append( rev_placeholder );

    //pull up the coloured sequence that is nearby to our button
    var seqs = button.parent().find(".coloured_seq");

    //should maybe just do this in perl and always take forward/rev_full
    //if there's a full sequence take it, if not strip away everythign but the nucleotides
    var fwd_seq = button.closest("td").find(".forward_full").text() || this.extract_sequence( seqs.first() );
    var rev_seq = button.closest("td").find(".reverse_full").text() || this.extract_sequence( seqs.last() );


    this.create_plot(fwd_placeholder, button.data("fwd"), fwd_seq, 0, button.data("context"));
    this.create_plot(rev_placeholder, button.data("rev"), rev_seq, 1, button.data("context"));

    // create button to hide the traces and restore the "View Traces" button
    var hide_button = $("<a>",{
        "class":"btn hide-traces",
        "text":"Hide Traces",
        "click": function(){
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
TraceViewer.prototype.create_plot = function(placeholder, name, search_seq, reverse, context) {
    if ( ! name ) { placeholder.parent().hide(); return }; //skip if we do not have a read name

    //create local var for this, as "this" in getJSON is different
    var parent = this;

    //fetch the users data and add a new graph when the data comes back
    $.getJSON(
        this.url,
        { "name": name, "search_seq": search_seq, "reverse": reverse, "context": context },
        function(data) {
            parent._create_plot(placeholder, data);
        }
    )
    .fail(function( jqxhr, textStatus, error ) {
        console.log( jqxhr.responseText );
    });
};

//function that actually creates the plot
TraceViewer.prototype._create_plot = function(placeholder, graph_data) {
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
            reserveSpace: true,
            show: false
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
    this.plot = plot;
};