del TypeTuner\TypeTuner.zip
copy TypeTuner.exe TypeTuner
copy Composer.exe TypeTuner
copy eggs.ttf TypeTuner
copy gsi_eggs.xml TypeTuner
copy test_tt_w_comp.bat TypeTuner
copy feat_all.dtd TypeTuner
copy feat_set.dtd TypeTuner
if exist TypeTuner.zip del TypeTuner.zip
zip TypeTuner TypeTuner\*.*
copy TypeTuner.zip i:\dropbox
move TypeTuner.zip TypeTuner
