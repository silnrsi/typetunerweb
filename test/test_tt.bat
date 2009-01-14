cls
if "%1"=="" goto usage
if "%1"=="pl" set TT=perl ..\typetuner.pl -d
if "%1"=="exe" set TT=..\typetuner.exe -d
if "%1"=="clean" goto clean

if not exist zork.ttf copy DoulosSILR.ttf zork.ttf

if exist zork_tt.ttf del zork_tt.ttf
%TT% add feat_all.xml zork.ttf
pause
ttfdump -tx -nx zork_tt.ttf
pause
if exist feat.xml del feat.xml
%TT% createset zork_tt.ttf feat.xml
fc feat_set_def.xml feat.xml
pause
%TT% -o feat_set_metrics.xml setmetrics SILDoulosTest.ttf feat_set.xml
pause
if exist zork_tt_tt.ttf del zork_tt_tt.ttf
%TT% applyset feat_set_metrics.xml zork_tt.ttf
pause
if exist zork_tt_tt_1.ttf del zork_tt_tt_1.ttf
ren zork_tt_tt.ttf zork_tt_tt_1.ttf
if exist zork_tt_tt.ttf del zork_tt_tt.ttf
%TT% applyset feat_set_2.xml zork_tt.ttf
pause
if exist zork_tt_tt_2.ttf del zork_tt_tt_2.ttf
ren zork_tt_tt.ttf zork_tt_tt_2.ttf
ttfdump -tx -nx zork_tt_tt_2.ttf
pause
if exist feat.xml del feat.xml
%TT% extract zork_tt_tt_2.ttf feat.xml
fc feat_set_2.xml feat.xml
pause
copy zork_tt_tt_2.ttf foo.ttf
if exist foo_tt.ttf del foo_tt.ttf
%TT% delete foo.ttf
pause
ttfdump -tx -nx foo_tt.ttf
goto end

:clean
if exist zork_tt.ttf del zork_tt.ttf
if exist zork_tt_tt_1.ttf del zork_tt_tt_1.ttf
if exist zork_tt_tt_2.ttf del zork_tt_tt_2.ttf
if exist foo.ttf del foo.ttf
if exist foo_tt.ttf del foo_tt.ttf
if exist feat.xml del feat.xml
if exist feat_set_metrics.xml del feat_set_metrics.xml
goto end

:usage
@echo usage: test pl - to test perl version, test exe - to test exe version

:end
