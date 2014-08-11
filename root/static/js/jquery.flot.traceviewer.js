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
