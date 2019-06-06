#!/usr/bin/perl

use strict;  
use Cwd qw(cwd);

#
# Customize these settings as needed for the host system
#
my $baseDir = cwd;
my $typeTunerDir = "$baseDir/TypeTuner";
my $tunableFontsDir = "$typeTunerDir/tunable-fonts";
my $logDir = '/var/log';
my $tmpDir = '/tmp';

my $title = 'TypeTuner Web';
my $defaultFamilyRE = qr/^Charis/o;
my $permittedHelpSites = qr'^(software|scripts)\.sil\.org/'oi;

my $cgiPathName = $0;     			# $0 will be something like '/Volumes/Data/Web/NRSI/scripts.sil.org/cms/ttw/fonts2go.cgi'
$cgiPathName =~ s!^.*(?=/ttw/)!!;	# something like '/ttw/fonts2go.cgi'

my $logFileName = $logDir . $cgiPathName;
$logFileName =~ s/\.[^.]*$//;
$logFileName .= '.log';				# something like '/var/log/ttw/fonts2go.log'

# This function can be changed to modify font file names in a way consistent
# with vendor preferences. Note that $suffix may be empty, but if
# provided it comes from either:
#   The suffix field provided by the user.
#   The package name given in the URL
# but in any case it will have had whitespace removed.

sub fontFileName
{
	# SIL's convention e.g. CharisSILLiteracy-Regular.ttf, but we should handle other things.
	my ($oldFileName, $suffix) = @_;
	$suffix = "TT" unless $suffix;
	if ($oldFileName =~ /^(.+)-([^-]+)\.([ot]tf)$/io)
	{
		# New SIL convention:
		return "$1$suffix-$2.$3";
	}
	elsif ($oldFileName =~ /^(.+)\.([^.]+)$/o)
	{
		# General whatever.ext
		return "$1$suffix.$2";
	}
	else
	{
		return "$oldFileName$suffix";
	}
}

# Similar to above, this function can be changed to modify the directory name
# (and ultimately the name of the downloaded zip file) into which the tuned
# fonts are placed.

sub fontDirName
{
	# Per SIL convention we insert the suffix in front of the version if present, e.g:
	#		CharisSIL -> CharisSIL-Suffix
	#		CharisSIL-1.408 -> CharisSIL-Suffix-1.408
	#
	my ($familytag, $suffix) = @_;
	$suffix = "TT" unless $suffix;
	my $dir = $familytag;
	$dir =~ s/(-[0-9\.]+)?$/$suffix$1/;
	return $dir;
}
	
# Below are literals to override style info -- these are set to match scripts.sil.org as of Jan 2011

my $dtd = "-//W3C//DTD HTML 4.01 Transitional//EN";

my $css = "../cms/sites/nrsi/themes/default/_css/default.css";

my $style_verbatim = <<'EOF' ;

<!--

A.GlobalNavLink, A.GlobalNavLink:visited {
	color: #FFFF00;
	font-size: smaller;
	font-weight: bold;
}

-->

EOF

my $preamble = <<'EOF' ;

<table width="100%" height="100%" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td style="background: #0068a6; padding-left:20; padding-top:10; white-space:nowrap;" width="110" valign="top">
		<p><a href="http://www.sil.org/"><img src="../cms/sites/nrsi/themes/default/_media/SIL_Logo_TM_Blue_2014.png" width="85" height="95" border="0"></a><br><br></p>
    	<p class="Cat1"><a class="Cat1" href="../cms/scripts/page.php?site_id=nrsi&cat_id=Home">Home</a></p>
<p class="Cat1"><a class="Cat1" href="../cms/scripts/page.php?site_id=nrsi&cat_id=ContactUs">Contact Us</a></p>
<p class="Cat1"><a class="Cat1" href="../cms/scripts/page.php?site_id=nrsi&cat_id=General">General</a></p>
<p class="Cat2"><a class="Cat2" href="../cms/scripts/page.php?site_id=nrsi&cat_id=Babel">Initiative B@bel</a></p>
<p class="Cat2"><a class="Cat2" href="../cms/scripts/page.php?site_id=nrsi&cat_id=WSI_Guidelines">WSI Guidelines</a></p>
<p class="Cat1"><a class="Cat1" href="../cms/scripts/page.php?site_id=nrsi&cat_id=Encoding">Encoding</a></p>
<p class="Cat2"><a class="Cat2" href="../cms/scripts/page.php?site_id=nrsi&cat_id=EncodingPrinciples">Principles</a></p>
<p class="Cat2"><a class="Cat2" href="../cms/scripts/page.php?site_id=nrsi&cat_id=Unicode">Unicode</a></p>
<p class="Cat3"><a class="Cat3" href="../cms/scripts/page.php?site_id=nrsi&cat_id=UnicodeTraining">Training</a></p>
<p class="Cat3"><a class="Cat3" href="../cms/scripts/page.php?site_id=nrsi&cat_id=UnicodeTutorials">Tutorials</a></p>
<p class="Cat3"><a class="Cat3" href="../cms/scripts/page.php?site_id=nrsi&cat_id=UnicodePUA">PUA</a></p>
<p class="Cat2"><a class="Cat2" href="../cms/scripts/page.php?site_id=nrsi&cat_id=Conversion">Conversion</a></p>
<p class="Cat3"><a class="Cat3" href="../cms/scripts/page.php?site_id=nrsi&cat_id=EncConvRes">Resources</a></p>
<p class="Cat3"><a class="Cat3" href="../cms/scripts/page.php?site_id=nrsi&cat_id=ConversionUtilities">Utilities</a></p>
<p class="Cat4"><a class="Cat4" href="../cms/scripts/page.php?site_id=nrsi&cat_id=TECkit">TECkit</a></p>
<p class="Cat3"><a class="Cat3" href="../cms/scripts/page.php?site_id=nrsi&cat_id=ConversionMaps">Maps</a></p>
<p class="Cat2"><a class="Cat2" href="../cms/scripts/page.php?site_id=nrsi&cat_id=EncodingResources">Resources</a></p>
<p class="Cat1"><a class="Cat1" href="../cms/scripts/page.php?site_id=nrsi&cat_id=Input">Input</a></p>
<p class="Cat2"><a class="Cat2" href="../cms/scripts/page.php?site_id=nrsi&cat_id=InputPrinciples">Principles</a></p>
<p class="Cat2"><a class="Cat2" href="../cms/scripts/page.php?site_id=nrsi&cat_id=InputUtilities">Utilities</a></p>
<p class="Cat2"><a class="Cat2" href="../cms/scripts/page.php?site_id=nrsi&cat_id=InputTutorials">Tutorials</a></p>
<p class="Cat2"><a class="Cat2" href="../cms/scripts/page.php?site_id=nrsi&cat_id=InputResources">Resources</a></p>
<p class="Cat1"><a class="Cat1" href="../cms/scripts/page.php?site_id=nrsi&cat_id=TypeDesign">Type Design</a></p>
<p class="Cat2"><a class="Cat2" href="../cms/scripts/page.php?site_id=nrsi&cat_id=TypeDesignPrinciples">Principles</a></p>
<p class="Cat2"><a class="Cat2" href="../cms/scripts/page.php?site_id=nrsi&cat_id=FontDesignTools">Design Tools</a></p>
<p class="Cat2"><a class="Cat2" href="../cms/scripts/page.php?site_id=nrsi&cat_id=FontFormats">Formats</a></p>
<p class="Cat2"><a class="Cat2" href="../cms/scripts/page.php?site_id=nrsi&cat_id=TypeDesignResources">Resources</a></p>
<p class="Cat3"><a class="Cat3" href="../cms/scripts/page.php?site_id=nrsi&cat_id=FontDownloads">Font Downloads</a></p>
<p class="Cat3"><a class="Cat3" href="../cms/scripts/page.php?site_id=nrsi&cat_id=FontDownloadsGentium">Gentium</a></p>
<p class="Cat3"><a class="Cat3" href="../cms/scripts/page.php?site_id=nrsi&cat_id=FontDownloadsDoulos">Doulos</a></p>
<p class="Cat3"><a class="Cat3" href="../cms/scripts/page.php?site_id=nrsi&cat_id=FontDownloadsIPA">IPA</a></p>
<p class="Cat1"><a class="Cat1" href="../cms/scripts/page.php?site_id=nrsi&cat_id=Rendering">Rendering</a></p>
<p class="Cat2"><a class="Cat2" href="../cms/scripts/page.php?site_id=nrsi&cat_id=RenderingPrinciples">Principles</a></p>
<p class="Cat2"><a class="Cat2" href="../cms/scripts/page.php?site_id=nrsi&cat_id=RenderingTechnologies">Technologies</a></p>
<p class="Cat3"><a class="Cat3" href="../cms/scripts/page.php?site_id=nrsi&cat_id=RenderingOpenType">OpenType</a></p>
<p class="Cat3"><a class="Cat3" href="../cms/scripts/page.php?site_id=nrsi&cat_id=RenderingGraphite">Graphite</a></p>
<p class="Cat2"><a class="Cat2" href="../cms/scripts/page.php?site_id=nrsi&cat_id=RenderingResources">Resources</a></p>
<p class="Cat3"><a class="Cat3" href="../cms/scripts/page.php?site_id=nrsi&cat_id=FontFAQ">Font FAQ</a></p>
<p class="Cat1"><a class="Cat1" href="../cms/scripts/page.php?site_id=nrsi&cat_id=Links">Links</a></p>
<p class="Cat1"><a class="Cat1" href="../cms/scripts/page.php?site_id=nrsi&cat_id=Glossary">Glossary</a></p>

    	<br>
	</td>

    <td valign="top" style="padding:0" xwidth="650">
		<div style="background: #6699CC url(../cms/sites/nrsi/themes/default/_media/home_banner_gradient.gif) no-repeat right; padding:0 0 0 25; height:36px; margin:0; color:#FFFFFF;">
			<p style="font-family:Times New Roman; font-size:25px; color:#FFFFFF; padding:10 0 0 0; margin:0 0 0 0">NRSI: Computers & Writing Systems</p>
		</div>
		<div style="padding:0 0 0 0; background-color:#000000; color:#FFFFFF">
			<table width='100%'>
				<tr>
					<td style="padding: 0 0 0 25px"><a class="GlobalNavLink" href="http://www.sil.org/">SIL HOME</a>
							| <a class="GlobalNavLink" href="http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&cat_id=ContactUs">CONTACT US</a>
					</td>
					<td align='right'>
						<p><!-- RegionBegin: region_type='SearchForm' id='e3c92b87' --><form action='../cms/scripts/page.php?site_id=nrsi' method='POST' name='search_form'><input style='font-size:9' maxlength='200' name='search_query' size='30' value=''/> <input style='font-size:9' type='submit' value='Search'/></form><!-- RegionEnd: region_type='SearchForm' id='e3c92b87' --></p>
					</td>
				</tr>
			</table>
		</div>

		<div style="padding:0 25 25 25">
			<p class='CategoryPath'>You are here: <a class='CategoryPath' href='http://scripts.sil.org/ttw/fonts2go.cgi'>TypeTuner Web</a><br>
			Short URL: <a href='http://scripts.sil.org/ttw/fonts2go.cgi'>http://scripts.sil.org/ttw/fonts2go.cgi</a></p>

<!-- Begin TypeTuner Info -->

EOF

my $postamble = <<'EOF' ;

<!-- End TypeTuner Info -->
			
			<p><small>© 2008-2011 <a href='http://www.sil.org/' target='_blank'>SIL International</a>, all rights reserved, unless otherwise noted elsewhere on this page.<br>
			Provided by SIL's Non-Roman Script Initiative. Contact us at <a href='mailto:nrsi@sil.org'>nrsi@sil.org</a>.</small></p>
		</div>
    </td>

</table>
EOF
# '

##########################################
#                                        #
# no user serviceable parts below here   #
#                                        #
##########################################

use CGI qw/:all :push :multipart/;
use CGI::Carp qw/warningsToBrowser fatalsToBrowser/;
use Fcntl qw/:flock :seek/;
use File::Temp qw/tempdir tempfile/;
use File::Spec;
use File::Path;
use File::Basename;
use XML::Parser::Expat;
# use Data::Dumper;

# Help foil denial-of-service attacks:
$CGI::POST_MAX = 100 x 1024;	# Set max size of POST.    TODO: This limit needs to be increased when we allow file uploads.
$CGI::DISABLE_UPLOADS = 1;  	# TODO: delete this line when we have support for font/settings uploads.

# Some assumptions made in this code:
#
# Font files are either .ttf or .otf

my $cgi = new CGI;

my $feat_set_orig = 'feat_set_orig.xml';
my $feat_set_tuned = 'feat_set_tuned.xml';

# Dev-mode: if the URL includes the "dev" parameter then 
# font families that contain a ".test" file will be included in the UI

my ($devmode);
$devmode = defined($cgi->param('dev')) || $cgiPathName !~ /fonts2go/oi;

# Create a tempfile used for debugging output. This file will be unlinked
# just before the script exits. Thus if the script exits prematurely, the
# tempfile remains. To add to this file, use appendtemp() function.
my ($tmpf, $tmpfilename) = tempfile( "ttwXXXXX", DIR => $tmpDir, SUFFIX => '.txt');
print $tmpf "Starting $cgiPathName" . ($devmode ? ' (in devmode)' : '') . "\n";
close $tmpf;


my ($availableFamilies, %uiFamilies, $defaultFamily);
opendir(DIR, "$tunableFontsDir") || my_die ("Cannot opendir tunableFontsDir: $!\n");
foreach my $dir (sort readdir(DIR)) {
	next if $dir =~ m/^\./ || !(-d "$tunableFontsDir/$dir");     # || ($dir =~ /test|alpha/oi && $cgiPathName =~ /fonts2go/oi);
	$dir =~ m/^(.*?)(?:\s+([0-9\.]+))?$/;		# parse family name and, if present, version
	my ($family, $ver) = ($1,$2);
	$family =~ s/[^-A-Za-z_]//g;
	my $familytag = $family;
	$familytag .= "-$ver" if $ver;		# e.g.:  CharisSIL-4.108
	# NB: familytag should not have spaces, but subdirectory name may have them.
	# Save mapping of familytag -> folder name for all available families:
	$availableFamilies->{$familytag} = $dir ;
	next if (exists $uiFamilies{$family} && $uiFamilies{$family} gt $familytag) 
		or -f "$tunableFontsDir/$dir/.hide"
		or (-f "$tunableFontsDir/$dir/.test" && !$devmode);
	# Keep a mapping of family -> familytag of the families we present in the UI, i.e., just the most recent non-hidden version.
	$uiFamilies{$family} = $familytag;
	$defaultFamily = $familytag if $dir =~ $defaultFamilyRE; 
}
closedir(DIR);

# Secure the environment:
$ENV{'PATH'} = '/bin:/usr/bin';
delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};

my $featurelist;	# var to accumulate list of user-selected font features (for log file)

# These are global because they are referenced by XML parser:
my %omittedfeatures = ();	# Hash of feature names that are to be completely omitted from the form
my %omittedvalues = ();		# Hash of features (names and values) that are to be omitted from the form.

######################################################################

if ($cgi->param('pkg')) {
	#
	# Process hardcoded URL to get a specific package, e.g.
	#    fonts2go.cgi?pkg=Literacy&family=Charis
	#    fonts2go.cgi?pkg=Literacy&family=Charis&ver=4.106
	#
	my $familytag = getFamilytag();
	my $fontdir = "$tunableFontsDir/$availableFamilies->{$familytag}";
	invalid_parameter("No packages available for font family \"$availableFamilies->{$familytag}\".") 
		unless -d "$fontdir/.packages";
	
	my $pkg_re = qr/[^-A-Za-z_]/o;
	my $pkg = checkparam('pkg', $pkg_re);
	appendtemp("Starting direct download: family = $familytag pkg = $pkg");
	
	# Note: Settings file names can have spaces, e.g. "Literacy Compact", 
	# but for convenience on the URL the 'pkg' parameter has no spaces.
	# So we have to find the config file that matches the pkg being requested.
	opendir(DIR, "$fontdir/.packages") || my_die ("Cannot opendir \"$fontdir/.packages\": $!\n");
	my $settingsFile = '';
	foreach (sort readdir(DIR)) {
		next unless -f "$fontdir/.packages/$_";
		my $s = $_;
		$s =~ s/$pkg_re//g;
		if ($s eq $pkg) {
			$settingsFile = $_;
			last;
		}
	}
	closedir(DIR);
	appendtemp("settingsFile = \"$settingsFile\"");
	invalid_parameter("pkg=$pkg") unless $pkg && $settingsFile;
	
	my $suffixOpt = "-n \"$settingsFile\"";
	my $file_name = fontDirName($familytag, $pkg);
	
	my $tempDir = tempdir("ttwXXXXX", DIR => $tmpDir);
	appendtemp("tempdir = $tempDir");

	my $tunedDir = "$tempDir/$file_name";
	appendtemp("tunedDir = $tunedDir");
	mkdir "$tunedDir";

	# link in the settings file for this package
	link("$fontdir/.packages/$settingsFile", "$tunedDir/$feat_set_tuned") or my_die ("Unable to link settings file: $!\n");
	
	# Ok, write to logfile and build the fonts:
	appendlog($familytag, "pkg $pkg = $settingsFile");
	appendtemp("log file written");
	buildfonts ($tempDir, $tunedDir, $file_name, $familytag, $fontdir, $pkg, $suffixOpt);

	# Done!
	appendtemp("finished direct download");
	rmtree($tempDir);
	unlink "$tmpfilename";
	exit;}

	
######################################################################

if ($cgi->param('Select features')) {
	#
	# present form to select font features
	#
	my $familytag = getFamilytag();
	my $fontdir = "$tunableFontsDir/$availableFamilies->{$familytag}";
	my $help='';

	appendtemp("Starting 'Select features': familytag = $familytag");
	
	my $ttf = ttflist($fontdir);		# Complete checking of 'family' param and retrieve one font from family to get feature info
	my $tempDir = tempdir("ttwXXXXX", DIR => $tmpDir);
	my $res = run_cmd("(cd $typeTunerDir; perl typetuner.pl -x $tempDir/$feat_set_orig \"$fontdir/$ttf\")");
	my_die ("$res\n") if $res;
	
	print
		header(-charset => 'utf-8'),
		start_html(
				-dtd => $dtd,
				-title => $title,
				-meta => { keywords => "typetuner sil"},
				-style => { -src => $css, 
									-verbatim => $style_verbatim },
				'--style' => "padding:0; margin:0"),
		$preamble,
	
		h1("Welcome to $title!<br>", span({-class => 'item_subtitle'}, p("Type that's tuned to suit your taste"))),
		hr,
	
		start_form(
				-method		=> 'post',
				-action		=> "$cgiPathName",
				-enctype	=> 'multipart/form-data',
				-charset	=> 'UTF-8' );
	
	if (-f "$fontdir/.help_url")
	{
		# retrieve help url from .help_url file
		open (FH, "< $fontdir/.help_url");
		$help = <FH>;
		close (FH);
	}
	if (-f "$fontdir/.ttwrc")
	{
		# Retrieve info from .ttwrc file
		open (FH, "< $fontdir/.ttwrc");
		while (<FH>)
		{
			s/^\s*#.*$//;			# Trim comments
			next unless /^\s*([^=]+?)\s*=\s*(.+?)\s*$/;  # Must match "keyword=value" but allow whitespace around keyword and within value
			my ($kw, $val) = (lc($1), $2);
			if ($kw eq 'helpurl')
			{
				$help = $val;
			}
			elsif ($kw eq 'omittedfeature')
			{
				$omittedfeatures{$val} = 1;
			}
			elsif ($kw eq 'omittedvalue')
			{
				if ($val =~ /^([^:]+?)\s*:\s*(.+)$/)	# Must match "feature:value" but allow whitespace
				{
					$omittedvalues{$1}{$2} = 1;
				}
			}
		}
		close (FH);
	}
	
	if ($help ne '')
	{
		# For security, make sure the help URL is http, https, or ftp, and on a permitted server
		my $myhelp = $help;
		$myhelp =~ s'((?<=/)\.\./)|\s''g;   #' # remove "../" or whitespace 
		my ($helpProtocol, $helpAddress) = split('://', $myhelp, 2);
		if ($helpProtocol =~ /^(https?|ftp)$/ && $helpAddress =~ $permittedHelpSites)
		{
			# Help URL looks OK
			$help = "(for help see " . a({href=>$myhelp, target=>"_blank"},"$availableFamilies->{$familytag} font features") . ")";
		}
	}	
	
	print
		p(strong("Tunable feature settings in $availableFamilies->{$familytag}"), $help);
	
			

if (0)   # 'Load settings' not yet implemented
{
	print
		p('Existing font:', filefield(-name => 'load_settings'), submit('Load settings'));
}
	my $parser = new XML::Parser::Expat;
	$parser->setHandlers(
		'Start' => \&sh_form,
		'End'   => \&eh_form);
	open FH, "< $tempDir/$feat_set_orig" or my_die ("cannot open feature_set_org: $!\n");
	$parser->parse(*FH);
	close(FH);
	
	print
		hr,
		strong(['Font name suffix']),
		' (auto-generated if blank): ',
		textfield('suffix', '', 50, 80);
	
	print
		hidden('family', $familytag),
		hidden('dev', $devmode);
	
	print
		hr,
		submit('Get tuned font'),
		submit('Go back'),
		end_form,
		$postamble,
		end_html;

	appendtemp("finished 'Select features'");
	rmtree($tempDir);
	unlink "$tmpfilename";
	exit;

}

######################################################################

elsif ($cgi->param('Get tuned font')) {
	#
	# run TypeTuner and deliver the resulting font(s)
	#
	my $familytag = getFamilytag();
	my $fontdir = "$tunableFontsDir/$availableFamilies->{$familytag}";
	my $suffix = checkparam('suffix', qr/[^-A-Za-z_ ]/o);		# de-taint suffix
	my $suffixOpt = '';
	
	appendtemp("Starting 'Get tuned font': familytag = $familytag, suffix = $suffix");
	
	my $ttf = ttflist($fontdir);		# Complete checking of 'family' param and retrieve one font from family to get feature info
	
	my $tempDir = tempdir("ttwXXXXX", DIR => $tmpDir);
	appendtemp("tempdir = $tempDir");
	
	my $res = run_cmd("(cd $typeTunerDir; perl typetuner.pl -x $tempDir/$feat_set_orig \"$fontdir/$ttf\")");
	my_die ("$res\n") if $res;
	
	my $file_name;
	if ($suffix ne '') {
		$suffixOpt = "-n \"$suffix\"";
		$suffix =~ s/\s//g;
		$file_name = fontDirName($familytag, $suffix);
	}
	else {
		$file_name = fontDirName($familytag);
	}
	my $tunedDir = "$tempDir/$file_name";
	mkdir "$tunedDir";
	appendtemp("tunedDir = $tunedDir");
	
	# create the customized settings file
	open(SETTINGS, "> $tunedDir/$feat_set_tuned");
	my $parser = new XML::Parser::Expat;
	$parser->setHandlers(
		'Start' => \&sh_proc,
		'End'   => \&eh_proc);
	open(FH, "< $tempDir/$feat_set_orig") or my_die ("cannot open feature_set_org: $!\n");
	$parser->parse(*FH);
	close(FH);
	close(SETTINGS);
	
	# Ok, write to logfile and build the fonts:
	appendlog($familytag, $featurelist);
	appendtemp("log file written");
	buildfonts ($tempDir, $tunedDir, $file_name, $familytag, $fontdir, $suffix, $suffixOpt);

	# Done!
	appendtemp("finished 'Get tuned font'");
	rmtree($tempDir);
	unlink "$tmpfilename";
	exit;
}


######################################################################

else {
	#
	# Initial page: present welcome screen, font family choice
	#

	appendtemp('Starting Welcome');

	print
		header(-charset => 'utf-8'),
		start_html(	
				-dtd => $dtd,
				-title => $title,
				-meta => { keywords => "typetuner sil"},
				-style => { -src => $css, 
									-verbatim => $style_verbatim },
				'--style' => "padding:0; margin:0"),
		$preamble,
		h1("Welcome to $title!<br>", span({-class => 'item_subtitle'}, p("Type that's tuned to suit your taste"))),
		p('This service allows you to download customized versions of our fonts.
		First, choose a typeface family; then you can select various alternate glyphs
		and other optional features to be the defaults in your new font.'),
		hr,
	
		start_form(
				-method		=> 'post',
				-action		=> "$cgiPathName",
				-enctype	=> 'multipart/form-data',
				-charset	=> 'UTF-8' );
	
	print
		table({-border => '0'},
			Tr([
				td([
					strong(['Font family']),
					popup_menu(
						-name => 'family',
						-values => [ sort values %uiFamilies ],
						-default => $defaultFamily,
						-labels => $availableFamilies
					)
				])
			])
		);
		
	print
		hr,
		submit('Select features'),
		defaults('Reset'),
		end_form,
		$postamble,
		end_html;
	
	appendtemp("finished Welcome");
	unlink "$tmpfilename";
	exit;
}


sub buildfonts{
	# run typetuner on all fonts in the family
	
	my ($tempDir, $tunedDir, $file_name, $familytag, $fontdir, $suffix, $suffixOpt) = @_;
	
	my ($res, $buffer);
	
	my @ttfs = ttflist($fontdir);		# get list of fonts.
	
	foreach (@ttfs) {
		my $tuned = "$tunedDir/" . fontFileName($_, $suffix);
		$res = run_cmd("(cd $typeTunerDir; perl typetuner.pl $suffixOpt -o \"$tuned\" applyset $tunedDir/$feat_set_tuned \"$fontdir/$_\")");
		if ($res)
		{
			print header(-charset => 'UTF-8'),
				start_html({-leftmargin => '18px', -title => $title}),
				p("Unexpected error from SIL Typetuner when processing font '$_':"),
			    pre("$res"),
			    p("Please click your browser's Back button, check your feature settings and try again."),
			    p("Be aware that feature settings that require an ", em("input"), " font will not work with $title"),
			    end_html;
			rmtree($tempDir);
			unlink $tmpfilename;
			exit; 
		}
	}
	
	# Include any other files (e.g., license), but replace some keywords 
	my @t = localtime();
	my $isodate = sprintf ("%04d-%02d-%02d", $t[5]+1900, $t[4]+1, $t[3]);
	my $date = sprintf("%02d %s %04d", $t[3], (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec))[$t[4]], $t[5] + 1900);

	my @jobs = ( '.' );

	while ($#jobs >= 0)
	{
		my $subdir = shift @jobs;
		appendtemp ("starting subdir: '$subdir'");
		unless (-d $subdir)
		{
			mkdir("$tunedDir/$subdir") or my_die ("Cannot mkdir '$tunedDir/$subdir': $!\n");
		}
		opendir(DIR, "$fontdir/$subdir") or my_die ("Cannot opendir '$fontdir/$subdir': $!\n");
		foreach (sort readdir(DIR)) {
			next if m/^\./ || m/\.ttf$/;  # Skip .ttf files and any . files.
			if (m/^(.*)_tt(\..*)+$/i)
			{
				# Fix up %DATE% in any file that ends in _tt, _tt.txt, etc. 
				my $outfile = "$tunedDir/$subdir/$1$2";
				appendtemp ("processing '$_' -> '$subdir/$outfile'");
				local $/;
				open (FH, "<:raw", "$fontdir/$subdir/$_") or my_die ("cannot open '$fontdir/$subdir/$_' for reading: !$\n");
				my $s = <FH>;	# Slurp entire file
				close (FH);
				use bytes;
				$s =~ s/%DATE%/$date/g;
				$s =~ s/%ISODATE%/$isodate/g;
				no bytes;
				open (FH, ">:raw", $outfile) || my_die ("Cannot open '$outfile' for writing: $!\n");
				print FH $s;
				close (FH);
			}
			elsif (-d "$fontdir/$subdir/$_")
			{
				# subfolder -- schedule it for a later time.
				appendtemp ("saving directory '$subdir/$_' for later");
				push @jobs, "$subdir/$_";
			}
			else
			{
				# anything else is just linked in.
				appendtemp ("linking '$_'");
				link "$fontdir/$subdir/$_", "$tunedDir/$subdir/$_";
			}
		}
		closedir(DIR);	
	}
	
	# create the zip archive
	appendtemp ("creating '$file_name.zip'");
	$res = run_cmd("(cd $tempDir; zip -r $file_name.zip $file_name >> $tmpfilename)");
	my_die ("$res\n") if $res;


  if (0) {
  	# Jonathan apparently tried this to do the download but didn't use it, for unknown reasons
		$| = 1;
		print multipart_init();
	
		#print header(-charset => 'UTF-8');
	
		print multipart_start();
		print
			start_html({-leftmargin => '18px', -title => $title}),
		
			h2({-style => 'margin-bottom: 3px'}, "Thanks for using $title!"),
			hr,
			
			start_form(
					-method		=> 'post',
					-action		=> "$cgiPathName",
					-enctype	=> 'multipart/form-data',
					-charset	=> 'UTF-8' ),
	
			defaults('Start again'),
			end_form,
	
			end_html;
		print multipart_end();
	
		print multipart_start(-type => 'application/zip');
	#	print header(-attachment => "$file_name.zip");
		open(ZIP, "< $tempDir/$file_name.zip");
		while (read(ZIP, $buffer, 1024)) {
		   print $buffer;
		}
		close(ZIP);
		
		print multipart_final();
  }
  else 
  {
  	# Instead, this is what does the download:
  	
		print header({-type => 'application/zip', -attachment => "$file_name.zip"});
		open(ZIP, "< $tempDir/$file_name.zip");
		while (read(ZIP, $buffer, 1024)) {
		   print $buffer;
		}
		close(ZIP);

  }
}

my ($featureName, $defValue, $values);

sub sh_form
{
	my ($p, $el, %atts) = @_;

	if ($el eq 'features_set') {
		print $cgi->start_table({-border => '0'});
	}
	
	elsif ($el eq 'feature') {
		$featureName = $atts{'name'};
		$defValue = $atts{'value'};
		$values = [];
	}
	
	elsif ($el eq 'value') {
		push @$values, $atts{'name'} unless $omittedvalues{$featureName}{$atts{'name'}};
	}
}

sub eh_form
{
	my ($p, $el) = @_;

	if ($el eq 'features_set') {
		print $cgi->end_table();
	}

	elsif ($el eq 'feature') {
		print Tr({-valign => 'CENTER'},
			[
				td([
					$featureName,
					popup_menu(
						-name => $featureName,
						-values => $values,
						-default => $defValue
					)
				])
			]
		) unless $omittedfeatures{$featureName};
	}
}

sub sh_proc
{
	my ($p, $el, %atts) = @_;

	if ($el eq 'features_set') {
		print SETTINGS <<__EOT__;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE features_set SYSTEM "feat_set.dtd">
<features_set version="1.0">
__EOT__
	}

	elsif ($el eq 'feature') {
		my $featureName = $atts{'name'};
		my $oldvalue = $atts{'value'};
		my $newvalue = defined $cgi->param($featureName) ? $cgi->param($featureName) : $atts{'value'};
		print SETTINGS "\t<feature name=\"$featureName\" value=\"$newvalue\">\n";
		if ($newvalue ne $oldvalue) {
			$featurelist .= $featureName . (lc($newvalue) eq 'true' ? '; ' : " = $newvalue; ") ;
		}
	}

	elsif ($el eq 'value') {
		print SETTINGS "\t\t<value name=\"$atts{'name'}\"/>\n";
	}
}

sub eh_proc
{
	my ($p, $el) = @_;

	if ($el eq 'features_set') {
		print SETTINGS "</features_set>\n";
	}

	elsif ($el eq 'feature') {
		print SETTINGS "\t</feature>\n";
	}
}

# Retrieve 'family' and 'ver' varibles from CGI; detaint them and
# determine the familytag value to be used. 

sub getFamilytag
{
	my $ver = checkparam('ver', qr/[^0-9.]/o);
	my $familytag = ($ver ? checkparam('family', qr/[^-A-Za-z_]/o) . "-$ver" : checkparam('family', qr/[^-A-Za-z_0-9\.]/o));
	
	return $familytag if exists $availableFamilies->{$familytag};	# found it right off the bat.
	
	return $uiFamilies{$familytag} if exists $uiFamilies{$familytag};	# If just missing the version, it should show up in this list.

	# search through available familys for one that matches what we have so far
	my $re = qr/^$familytag/i;
	foreach my $k (keys(%{$availableFamilies}))
	{
		return $k if $k =~ $re;
	}

	invalid_parameter("tag=$familytag\n");	
}
	
sub checkparam
{
	# verify and de-taint a cgi parameter value
	my $value = $cgi->param(shift);
	my $re = shift;
	$value =~ s/$re//g;					# Keep only what caller wants
	$value =~ s/ +/ /;					# compress spaces
	$value =~ /^ *(.*?) *$/;		# de-taint and trim leading/trailing whitespace
	return substr($1, 0, 50);		# limit length.
}
	

sub ttflist
{
	# return the first (in scalar context) or complete list (in list context) of the
	# font files within a given family.
	my $fontdir = shift;
	opendir(DIR, "$fontdir") || invalid_parameter ("Invalid directory \"$fontdir\"");
	my @ttfs =  (sort grep { /\.[ot]tf$/oi } readdir(DIR));
	closedir(DIR);	
	unless (scalar(@ttfs))
	{ invalid_parameter ("Invalid directory \"$fontdir\"");}
	return (wantarray ? @ttfs : $ttfs[0]);
}

sub appendlog
{
	# Append timestamp, user details, and message to our logfile
	my $logmsg = join(' ', @_);
	my @t = localtime();
	my $logdir = dirname($logFileName);
	mkpath($logdir) unless -d $logdir;
	warn "Can't create log directory $logdir: !$\n" unless -d $logdir;
	unless (open(LOG, ">>$logFileName"))
	{
		warn("Couldn't open '$logFileName': $!\n");
		return;
	}
	flock(LOG, LOCK_EX); # set an exclusive lock -- may wait
	seek(LOG, 0, SEEK_END); # once we have the lock, then re-seek the end of file
	printf LOG "%04d-%02d-%02d %02d:%02d:%02d", $t[5]+1900, $t[4]+1, $t[3], $t[2], $t[1], $t[0];
	print LOG " $ENV{'SERVER_NAME'} to $ENV{'REMOTE_ADDR'}: $logmsg\n";
	close(LOG);
}

sub appendtemp
{
	# Append a message to our temporary file (for debugging)
	my $logmsg = join(' ', @_);
	
	unless (open(TMP, ">>$tmpfilename"))
	{
		warn("Couldn't open '$tmpfilename': $!\n");
		return;
	}
	print TMP "$logmsg\n";
	close(TMP);
}

sub run_cmd
{
	# Wrapper around system() that does error checking.
	# Return undef if command completes without error.
	# Otherwise returns a string with error info, including any STDERR output
	
	my $cmd = shift;
	
	my ($tmpf, $tmpfilename) = tempfile( "sysXXXXX", DIR => $tmpDir, SUFFIX => '.txt');
	
	my $res;
	system("$cmd 2> $tmpfilename");
	
	# Error checking, basically from perlfunc:
	
	if ($? == -1) {
        $res = "External program failed to execute: $!";
    }
    elsif ($? & 127) {
        $res = sprintf ("External program died with signal %d, %s coredump", ($? & 127),  ($? & 128) ? 'with' : 'without');
    }
    elsif ($? >> 8)
    {
    	$res = sprintf("External program exited with return code %d\n", $? >> 8);
    	# Recover STDERR:
    	local $/;    
    	$res .= <$tmpf>;
    }
    close $tmpf;
    unlink $tmpfilename;
    return $res;
}
 
sub invalid_parameter {
	my ($msg, $tempDir, $flag) = @_;
	print
		header(-status => '404 Not found'),
		start_html('Problems'),
		h2('Invalid parameter'),
		p($msg),
		end_html;
	unlink "$tmpfilename" unless $flag;
	rmtree($tempDir) if defined $tempDir && -d $tempDir;
	exit;
}	

sub my_die {
	appendtemp @_;
	die @_;
}
