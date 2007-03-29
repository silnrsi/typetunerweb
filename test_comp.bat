rem gsi_zork_test.xml indicates three features interact on one glyph
rem  (though the glyph really does NOT do this)
rem it also contains corrections to the GSI
cls
perl composer.pl -d zork.ttf gsi_zork_test.xml
