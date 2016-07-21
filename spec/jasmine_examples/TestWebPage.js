
  console.log("Hello yes");

describe('test ', function () {
  beforeEach(function () {
    $('#fixture').remove();
    $.ajax({
      async: false, // must be synchronous to guarantee that no tests are run before fixture is loaded
      dataType: 'html',
      url: 'http://t87-dev.internal.sanger.ac.uk:3232/',
      success: function(data) {
        $('body').append($(data));
      }
    });
  });
  console.log($('body'));
  it('should use DOM fixture', function () {
    $('#fixture').myTestedJqueryPlugin();
    expect($('#fixture')).toSomething();
  });
 
  it('should use DOM fixture again', function () {
    $('#fixture').myTestedJqueryPlugin();
    expect($('#fixture')).toSomethingElse();
  });
});
