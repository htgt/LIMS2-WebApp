INSERT INTO cassette_function (id, promoter, conditional, cre, well_has_cre, well_has_no_recombinase)
VALUES ('ko_first',null,true,null,null,true);

INSERT INTO cassette_function (id, promoter, conditional, cre, well_has_cre, well_has_no_recombinase)
VALUES ('ko_first_promoter',true,true,null,null,true);

INSERT INTO cassette_function (id, promoter, conditional, cre, well_has_cre, well_has_no_recombinase)
VALUES ('ko_first_promoterless',false,true,null,null,true);

INSERT INTO cassette_function (id, promoter, conditional, cre, well_has_cre, well_has_no_recombinase)
VALUES ('reporter_only',null,true,null,true,null);

INSERT INTO cassette_function (id, promoter, conditional, cre, well_has_cre, well_has_no_recombinase)
VALUES ('reporter_only_promoter',true,true,null,true,null);

INSERT INTO cassette_function (id, promoter, conditional, cre, well_has_cre, well_has_no_recombinase)
VALUES ('reporter_only_promoterless',false,true,null,true,null);

INSERT INTO cassette_function (id, promoter, conditional, cre, well_has_cre, well_has_no_recombinase)
VALUES ('cre_knock_in',null,null,true,null,null);

INSERT INTO schema_versions(version)
VALUES (21);
