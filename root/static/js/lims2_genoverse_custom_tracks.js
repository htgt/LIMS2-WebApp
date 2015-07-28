// LIMS2 specific genoverse tracks
// some tracks extend tracks shared with WGE so you must also use genoverse_custom_tracks.js from
// https://github.com/htgt/WebApp-Common/tree/master/shared_static/js

Genoverse.Track.DesignsLIMS2 = Genoverse.Track.extend({
  model     : Genoverse.Track.Model.Transcript.GFF3,
  view      : Genoverse.Track.View.Transcript,
  populateMenu : function (f) {
    // get up to date feature object
    var feature = this.track.model.featuresById[f.id];
    var id = feature.name.replace('D_','');
    var link = "<a href='" + this.track.design_report_uri + "?design_id=" + id
                + "' target='_blank'><font color='#00FFFF'>Design View</font></a>";

    var atts = {
      Name  : feature.name,
      Type  : feature.type,
      Start : feature.start,
      End   : feature.end,
      Strand : feature.strand,
      URL   : link
    };
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

