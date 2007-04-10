rem create a feat_all file with no options to choose for testing
rem create a feat_set file with all settings set to non-default values
rem tune a font maximally

cls
if "%1"=="" goto usage
if "%1"=="pl" set TT=perl typetuner.pl -d
if "%1"=="pl" set CO=perl rfcomposer.pl -d
if "%1"=="exe" set TT=typetuner.exe -d
if "%1"=="exe" set CO=rfcomposer.exe -d
if "%1"=="clean" goto clean

if not exist eggs.ttf copy DoulosSILR_4100.ttf eggs.ttf

%CO% -t eggs.ttf gsi_eggs.xml dblenc_eggs.txt
pause
%TT% -t createset feat_all_composer.xml feat_set_composer.xml
pause
%TT% applyset_xml feat_all_composer.xml feat_set_composer.xml eggs.ttf
goto end

:clean
if exist feat_all_composer.xml del feat_all_composer.xml
if exist feat_set_composer.xml del feat_set_composer.xml
if exist eggs_tt.ttf del eggs_tt.ttf
goto end

:usage
@echo usage:
@echo test_tt_w_comp pl - to test perl version
@echo OR
@echo test_tt_w_comp exe - to test exe version

:end
