// LIMS2 specific genoverse tracks
// some tracks extend tracks shared with WGE so you must also use genoverse_custom_tracks.js from
// https://github.com/htgt/WebApp-Common/tree/master/shared_static/js

Genoverse.Track.Controller.DesignsLIMS2 = Genoverse.Track.Controller.extend({
  click: function (e) {
    var x = e.pageX - this.container.parent().offset().left + this.browser.scaledStart;
    var y = e.pageY - $(e.target).offset().top;
    var feature = this[e.target.className === 'labels' ? 'labelPositions' : 'featurePositions'].search({ x: x, y: y, w: 1, h: 1 }).sort(function (a, b) { return a.sort - b.sort; })[0];
    if (feature){
      // Attempt to show menu for individual CDS
      if(feature.cds){
        // get event click position
        var scaled_x = Math.floor(x / this.scale);

        // go through cds array and set feature=cds if there is a
        // cds at click position
        for (i = 0; i < feature.cds.length; i++) {
          var cds = feature.cds[i];
          if(scaled_x >= cds.start && scaled_x <= cds.end){
            // bingo, we have our cds
            parent_feature = feature;
            feature = cds;
            feature.label = feature.name || feature.id || '';
            feature.oligo_name = feature.name;
            feature.name = parent_feature.name;
            $.extend(feature, { label: feature.name || feature.id || '', exons: [], cds: [] }, {});

            break;
          }
        }
        // if not we just continue using the parent feature as normal
      }

      this.browser.makeMenu(feature, e, this.track);
    }
  }
});

Genoverse.Track.DesignsLIMS2 = Genoverse.Track.extend({
  model     : Genoverse.Track.Model.Transcript.GFF3,
  view      : Genoverse.Track.View.Transcript,
  controller : Genoverse.Track.Controller.DesignsLIMS2,
  populateMenu : function (f) {
    // get up to date feature object
    var feature = this.track.model.featuresById[f.id] || f;
    var id = feature.name.replace('D_','');
    var link = "<a href='" + this.track.design_report_uri + "?design_id=" + id
                + "' target='_blank'><font color='#00FFFF'>Design View</font></a>";

    var atts;
    console.log("LIMS2 genoverse custom tracks");
    if(feature.oligo_name){
      atts = {
        Name  : (feature.oligo_name + " oligo"),
        'Oligo Start' : feature.start,
        'Oligo End'   : feature.end,
        Strand : feature.strand,
        Design: feature.name,
        URL   : link
      };
    }
    else{
      atts = {
        Name : feature.name,
        Type : feature.type,
        Start : feature.start,
        End : feature.end,
        URL : link
      };
    }

    return atts;
  }
});

Genoverse.Track.Crisprs.LIMS2 = Genoverse.Track.Crisprs.extend({
  threshold    : 10000,
  // override populate menu as we need some LIMS2 specific content
  populateMenu : function (f) {
    // get up to date feature object
    var feature = this.track.model.featuresById[f.id];

    var id = feature.name.replace('LIMS2-','');
    var report_link = "<a href='" + this.track.crispr_report_uri + "/" + id
        + "/view' target='_blank'><font color='#00FFFF'>Crispr View</font></a>";

    var atts = {
       Start  : feature.start,
       End    : feature.end,
       Strand : feature.strand,
       Seq    : feature.seq,
       Name   : feature.name,
       PAM_right : feature.pam_right,
       WGE_id : feature.wge_ref,
       URL    : report_link
    };
    return atts;
  }
});

Genoverse.Track.CrisprPairs.LIMS2 = Genoverse.Track.CrisprPairs.extend({
    threshold    : 10000,
    populateMenu : function (f) {
        // get up to date feature object
        var feature = this.track.model.featuresById[f.id];

        var id = feature.name.replace('LIMS2-','');
        var report_link = "<a href='" + this.track.pair_report_uri + "/"
                                + id
                                + "/view' target='_blank'><font color='#00FFFF'>Crispr Pair View</font></a>";
        var atts = {
            Start  : feature.start,
            End    : feature.end,
            Strand : feature.strand,
            Name   : feature.name,
            URL    : report_link
        };
        return atts;
    }
});

Genoverse.Track.CrisprGroupsLIMS2 = Genoverse.Track.CrisprPairs.extend({
    threshold    : 10000,
    populateMenu : function (f) {
        // get up to date feature object
        var feature = this.track.model.featuresById[f.id];

        var id = feature.name.replace('LIMS2-','');
        var report_link = "<a href='" + this.track.group_report_uri + "/"
                                + id
                                + "/view' target='_blank'><font color='#00FFFF'>Crispr Group View</font></a>";
        var atts = {
            Start  : feature.start,
            End    : feature.end,
            Strand : feature.strand,
            Name   : feature.name,
            URL    : report_link
        };
        return atts;
    }
});

Genoverse.Track.PrimersLIMS2 = Genoverse.Track.extend({
    model     : Genoverse.Track.Model.Transcript.GFF3,
    view      : Genoverse.Track.View.Transcript,
    populateMenu : function(f){
      var feature = this.track.model.featuresById[f.id];

      var atts = {
        Type   : feature.type,
      };

      // List primers with forward primer first;
      var primers = feature.cds;
      primers.sort(function(a,b){ if(a.strand > b.strand){ return 1 }else{ return -1 } });
      primers.forEach(function(primer){
        atts[primer.id + ' Start'] = primer.start;
        atts[primer.id + ' End'] = primer.end;
        atts[primer.id + ' Strand'] = primer.strand;
      });

      return atts;
    }
});

// Add extra parameters to a URL for a genoverse track
function build_uri_params( params_to_build ) {
    var param_stub = "?";
    var param_end = [
        "chr=__CHR__",
        "start=__START__",
        "end=__END__",
        "content-type=text/plain"
    ];
    params_to_build = params_to_build.concat( param_end );
    var param_str = params_to_build.join("&");
    return param_stub.concat( param_str );
}

