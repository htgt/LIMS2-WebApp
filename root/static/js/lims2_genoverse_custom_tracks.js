// LIMS2 specific genoverse tracks
// some tracks extend tracks shared with WGE so you must also use genoverse_custom_tracks.js from
// https://github.com/htgt/WebApp-Common/tree/master/shared_static/js

Genoverse.Track.Controller.SequenceLIMS2 = Genoverse.Track.Controller.Sequence.extend({
  init: function() {
    this.base();

    console.log('initializing sequence controller');

    var browser = this.browser;
    var controls = browser.selectorControls;

    //add our find oligo button to the context menu
    $("<button class='copy_seq'>Sequence</button>").insertBefore( controls.find(".cancel") );

    //so we can access methods inside click method
    var parent = this;

    //the menu isn't extendable, so we have to add a new click method...
    controls.on('click', function (e) {
      if ( e.target.className != 'copy_seq' ) return;

      console.log('sequence selector clicked');
      var pos = browser.getSelectorPosition();
      var start = pos.start;
      var end = pos.end + 1;

      console.log('start: ' + start + ', end: ' + end);
      var features = parent.model.features.search({x: start, y: 0, w: (end - start) + 1, h: 1});
      console.log( features );

      // sequence is represented by features containing a chunk of sequence
      // (usually 1000 bases but this is configurable)
      // feature search identifies the chunks spanned by the selected region
      // then we loop through them to construct the slice of sequence
      var seq = '';
      $( features ).each(function(){
          console.log('feature start: ' + this.start);
          console.log('feature sequence: ' + this.sequence);
          var section_start;
          var section_end;

          if(start >= this.start){
            // selection starts in this chunk so we will
            // skip some bases from start of chunk
            section_start = start - this.start;
          }
          else{
            // selection starts before this chunk
            // so we want to start at the start of chunk
            section_start = 0;
          }
          console.log('section start: ' + section_start);


          if(end <= this.end){
            // selection ends in this chunk so we will
            // skip some bases from the end of the chunk
            section_end = end - this.start;
          }
          else{
            // selection ends beyond this chunk
            // so we want to end at the end of chunk
            section_end = this.end - this.start;
          }
          console.log('section end: ' + section_end);

          // select the section of the chunk we want
          var seq_section = this.sequence.substring(section_start,section_end);
          console.log('sequence section: ' + seq_section);

          // add it to any previous sequence in selection
          seq += seq_section;
      });

      console.log('selected sequence: ' + seq);
    });
  }

});


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

