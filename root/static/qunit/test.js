(function(t) {
    t.module('Test module');

    t.pageTest("first test", function(page) {

        page.open('[% c.uri_for("/user/create_design_plate") %]');

        QUnit.test("My first test", function(assert) { assert.equal(1,1,"1 = 1"); });

    });
})(QUnit);
