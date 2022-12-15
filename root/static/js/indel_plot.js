function buildIndelPlot(element_id, data) {

    /**
     * Plot indel number against relative (i.e. percentage) frequency.
     *
     * @param {String} element_id - The ID of the element into which the plot
     *   will be added.
     * @param {Object[]} data - Each object should have an `indel` and
     *   `frequency` attribute
     */

    var percentage = 0;

    var margin = {top: 40, right: 20, bottom: 70, left: 90},
        width = window.innerWidth*0.56,
        height = window.innerHeight*0.6;


    var total_reads = 0;
    var max_ticks = width/21;
    var ticksArray= [];
    var min = data[1].indel;
    var max = data[data.length-2].indel;
    if (data.length <= max_ticks) {
        for (var i = 1; i < data.length-1; i++) {
            ticksArray.push(data[i].indel);
        }
    }
    else {
        ticksArray.push(min);

        var quart = Math.floor((data.length-1)/4);
        ticksArray.push(data[quart].indel);
        ticksArray.push(data[quart*2].indel);
        ticksArray.push("0");
        ticksArray.push(data[quart*3].indel);
        ticksArray.push(max);
    }

    for (var i = 0; i < data.length; i++) {
        total_reads += data[i].frequency;
    }

    var x = d3.scaleBand()
        .rangeRound([0, width])
        .padding(0.1);

    var y = d3.scaleLinear()
        .range([height, 0]);

    var xAxis = d3.axisBottom()
        .scale(x)
        .ticks(ticksArray.length)
        .tickValues(ticksArray);

    var yAxis = d3.axisLeft()
        .scale(y)
        .ticks(10);

    var svg = d3.select("#" + element_id)
        .append("svg")
        .attr("width", width + margin.left + margin.right)
        .attr("height", height + margin.top + margin.bottom)
        .append("g")
        .attr("transform", "translate(" + margin.left + "," + margin.top + ")")


    x.domain(data.map(function(d) { return d.indel; }));
    y.domain([0, d3.max(data, function(d) { return d.frequency/total_reads*100; })]);
    y.nice(10);

    svg.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + height + ")")
      .call(xAxis)
      .selectAll("text")

    svg.append("g")
      .attr("class", "y axis")
      .call(yAxis)
      .append("text")
      .attr("transform", "rotate(-90)")
      .attr("y", 6)
      .attr("dy", ".71em")
      .style("text-anchor", "end");

    var div = d3.select("body").append("div")
        .attr("class", "tooltip")
        .style("opacity", 0);

    var tip = d3.tip()
        .attr('class', 'tooltip')
        .offset([-10, 0])
        .html(function(d) {
            return `
                <table class="tiptable">
                <tr><td>Indel Size<td><b>:</b>&nbsp` + d.indel + `
                <tr><td>#Reads<td><b>:</b>&nbsp` + d.frequency + `
                <tr><td>%Reads<td><b>:</b>&nbsp` + (d.frequency/total_reads*100).toFixed(2) + `%
                </table>`;
                })

    svg.call(tip);

    svg.selectAll("bar")
      .data(data)
      .enter()
      .append("rect")
      .attr("class", "bar")
      .attr("x", function(d) { return x(d.indel); })
      .attr("width", x.bandwidth())
      .attr("y", function(d) { return y(d.frequency/total_reads*100); })
      .attr("height", function(d) { return height - y(d.frequency/total_reads*100); })
      .style("fill", function(d) {
            if (d.indel == 0) {
                return "#8C2626"; //Red
            }
            else {
                return "steelblue";
            }
        })
     .on("mouseover.color", function(d) {
       d3.select(this).style('fill', 'orange');})
     .on("mouseout.color", function(d) {
       d3.select(this).style("fill", function(d) {
           if (d.indel == 0) {
                return "#8C2626"; //Red
           }
           else {
                return "steelblue";
           }
        })
       })
     .on("mouseover.tip",  tip.show)
     .on("mouseout.tip", tip.hide);

    svg.append("text")
      .attr("class", "axisLabels")
      .attr("transform",
            "translate(" + (width/2) + " ," +
                           (height + margin.top + 20) + ")")
      .style("text-anchor", "middle")
      .text("Indel Size");

    svg.append("text")
      .attr("class", "axisLabels")
      .attr("transform", "rotate(-90)")
      .attr("y", 0 - margin.left)
      .attr("x",0 - (height / 2))
      .attr("dy", "1em")
      .style("text-anchor", "middle")
      .text("Read Frequency %");

    function type(d) {
        d.frequency = +d.frequency;
    return d;
    }
}


        function prepareDataForIndelPlot(inputData) {
            // This is a shim to get the data in the correct form. See commit
            // message for why this is needed.
            let inclusiveRange = (theMin, theMax) => Array.from(
                 Array(theMax - theMin +1),
                 (_, index) => index + theMin,
            );
            let indelsWithNonZeroFrequency = inputData
                .filter(e => e['frequency'] != 0)
                .map(e => e['indel'])
            let plotMin = Math.min(...indelsWithNonZeroFrequency) - 1;
            let plotMax = Math.max(...indelsWithNonZeroFrequency) + 1;
            let fullData = inclusiveRange(plotMin, plotMax)
                .map(
                    n => {
                        let originalData = inputData.find(e => e['indel'] == n);
                        return originalData ? originalData : {'indel': n, 'frequency': 0};
                    }
                );
            return fullData;
        }
