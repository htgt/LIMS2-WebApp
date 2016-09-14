(function(t) {
    t.module('Test module');

    t.pageTest("first test", function(page) {
        console.log("open");
        page.open('http://t87-dev.internal.sanger.ac.uk:3232/user/create_design_plate');
        page.log(page.window()); 

        page.step('check landing', ['.page-header'], function(header) {
                console.log("check landing");
                console.log(header);
        });
        QUnit.test("Find page", function(assert) {
            page.open('/user/create_design_plate');
            console.log(page);
            //var $ = page.global('jQuery');
            var title; 
            page.step('check landing', ['.page-header'], function(header) {
                console.log("check landing");
                console.log(header);
                title = header;
            });

            assert.equal(title,"upload design plate", "title is correct");
        });

        QUnit.test("Control test", function(assert) {
            page.step('control step', ['.create_plate'], function(button) {
                button.click();

                console.log("control click");
            });
        });
        console.log("control");
        page.step('first step', [ '.page-header' ], function(element) {
            console.log("First test - element: " + element.val()  );

        });
        console.log("first");
        QUnit.test("Rear", function(assert) { assert.equal(1,1,"1 = 1"); });
        console.log("rear");
    });
})(QUnit);
