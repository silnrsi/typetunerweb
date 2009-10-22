#!/usr/bin/perl

use strict;  

#
# Customize these settings as needed for the host system
#
my $typeTunerDir = '/Volumes/Data/Web/NRSI/scripts.sil.org/cms/ttw/TypeTuner';
my $tunableFontsDir = "$typeTunerDir/tunable-fonts";

my $cgiPathName = $0;     # $0 will be something like /Volumes/Data/Web/NRSI/scripts.sil.org/cms/ttw/fonts2go.cgi
$cgiPathName =~ s!^.*(?=/ttw/)!!;
my $title = 'TypeTuner Web';
my $defaultFamily = 'CharisSIL';

# no user serviceable parts under here

use CGI qw/:all :push :multipart/;
use File::Temp qw/tempdir/;
use File::Spec;
use XML::Parser::Expat;
use Time::localtime;

my $cgi = new CGI;

my $tempDir = undef;
my $feat_set_orig = 'feat_set_orig.xml';
my $feat_set_tuned = 'feat_set_tuned.xml';

my $isodate = sprintf ("%04d-%02d-%02d", localtime->year() + 1900, localtime->mon(), localtime->mday);
my $date = sprintf("%02d %s %04d", localtime->mday, (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec))[localtime->mon()], localtime->year() + 1900);

my $dbgFileName;
sub debug
{
	# Used to output text to debug logfile (e.g., 'fonts2go.dbg')
	unless (defined ($dbgFileName))
	{
		$dbgFileName = $0;
		$dbgFileName =~ s/cgi$/dbg/;
	}
	open (DBG, ">> $dbgFileName");
	print DBG join(' ', @_);
	close (DBG);
}
	
my $availableFamilies;
opendir(DIR, "$tunableFontsDir") || die "Cannot opendir \"$tunableFontsDir\": $!";
foreach (sort readdir(DIR)) {
	next if m/^\./;
	my $tag = $_;
	$tag =~ s/[^-A-Za-z_0-9]//g;
	$availableFamilies->{$tag} = $_;
}
closedir(DIR);

if ($cgi->param('Select family')) {
	#
	# present form to select font features
	#
	my $family = $cgi->param('family');
	my $tempDir = tempdir();
	my $help;
	
	my @ttfs = split(/\n/, `ls "$tunableFontsDir/$availableFamilies->{$family}"/*.ttf`);
	system("(cd $typeTunerDir; perl TypeTuner.pl -x $tempDir/$family-$feat_set_orig \"$ttfs[0]\")");
	
	print
		header(-charset => 'UTF-8'),
		start_html({-leftmargin => '18px', -title => $title}),
	
		h2({-style => 'margin-bottom: 3px'}, "Welcome to $title!"),
		p({-style => 'margin-top: 0px'}, em("type that's tuned to suit your taste")),
		hr,
	
		start_form(
				-method		=> 'post',
				-action		=> "$cgiPathName",
				-enctype	=> 'multipart/form-data',
				-charset	=> 'UTF-8' );
	
	if (-f "$tunableFontsDir/$availableFamilies->{$family}/.help_url")
	{
		# retrieve help url from .help_url file
		open (FH, "< $tunableFontsDir/$availableFamilies->{$family}/.help_url");
		my $helpURL = <FH>;
		close (FH);
		# For security, make sure the help URL is http, https, or ftp, and on the same server as our CGI script
		$helpURL =~ s/\s+$//;
		my ($helpProtocol, $helpAddress) = split('://', $helpURL, 2);
		my $base = url(-base=>1);
		my ($baseProtcol, $baseAddress) = split('://', $base), 2 ;
		if ($helpProtocol =~ /http|ftp/ && substr($helpAddress, 0, length($baseAddress)) eq $baseAddress)
		{
			# Help URL looks OK
			$help = "(see " . a({href=>$helpURL, target=>"_blank"},"here") . " for help with font features)";
		}
	}
	print
		p(strong("Tunable feature settings in $availableFamilies->{$family}"), $help);
	
			

if (0)   # 'Load settings' not yet implemented
{
	print
		p('Existing font:', filefield(-name => 'load_settings'), submit('Load settings'));
}	
	my $parser = new XML::Parser::Expat;
	$parser->setHandlers(
		'Start' => \&sh_form,
		'End'   => \&eh_form);
	open FH, "< $tempDir/$family-$feat_set_orig" or die $!;
	$parser->parse(*FH);
	close(FH);
	
	print
		hr,
		strong(['Font name suffix']),
		' (auto-generated if blank): ',
		textfield('suffix', '', 50, 80);
	
	print
		hidden('family', $family),
		hidden('temp_dir', $tempDir);

	print
		hr,
		submit('Get tuned font'),
		submit('Go back'),
		end_form,
		end_html;

	exit;
}

elsif ($cgi->param('Get tuned font')) {
	#
	# run TypeTuner and deliver the resulting font(s)
	#
	my $tempDir = $cgi->param('temp_dir');
	my $family = $cgi->param('family');
	my $suffix = $cgi->param('suffix');
	my $suffixOpt = '';
	my $buffer;
	
	my $file_name = $family;
	if ($suffix ne '') {
		$file_name .= "-$suffix";
		$suffixOpt = "-n $suffix";
	}
	else {
		$file_name .= '-tuned';
	}
	$file_name =~ s/[^-A-Za-z_0-9]//g;
	my $tunedDir = "$tempDir/$file_name";
	mkdir "$tunedDir";
	
	# create the customized settings file
	open(SETTINGS, "> $tunedDir/$family-$feat_set_tuned");
	my $parser = new XML::Parser::Expat;
	$parser->setHandlers(
		'Start' => \&sh_proc,
		'End'   => \&eh_proc);
	open(FH, "< $tempDir/$family-$feat_set_orig") or die $!;
	$parser->parse(*FH);
	close(FH);
	close(SETTINGS);
	
	# run typetuner on all fonts in the family
	my $ttfs = `ls "$tunableFontsDir/$availableFamilies->{$family}"/*.ttf`;
	
	foreach (split(/\n/, $ttfs)) {
		my $tuned = $_;
		$tuned =~ s!^.*/!$tunedDir/!;
		if ($suffix eq '') {
			$tuned =~ s/\.ttf$/-TT.ttf/;
		}
		else {
			$tuned =~ s/\.ttf$/-$suffix.ttf/;
		}
		system("(cd $typeTunerDir; perl TypeTuner.pl $suffixOpt -o $tuned applyset $tunedDir/$family-$feat_set_tuned \"$_\")");
	}
	
	# Include any other files (e.g., license)
	opendir(DIR, "$tunableFontsDir/$availableFamilies->{$family}") || die "Cannot opendir \"$tunableFontsDir/$availableFamilies->{$family}\": $!";
	foreach (sort readdir(DIR)) {
		next if m/^\./ || m/\.ttf$/;  # Skip .ttf files and any . files.
		if (m/^(.*)_tt(\..*)+$/i)
		{
			# Fix up %DATE% in any file that ends in _tt, _tt.txt, etc. 
			my $outfile = "$tunedDir/$1$2";
			local $/;
			open (FH, "<:raw", "$tunableFontsDir/$availableFamilies->{$family}/$_") or die ("can't open '$tunableFontsDir/$availableFamilies->{$family}/$_' for reading: !$\n");
			my $s = <FH>;	# Slurp entire file
			close (FH);
			use bytes;
			$s =~ s/%DATE%/$date/g;
			$s =~ s/%ISODATE%/$isodate/g;
			no bytes;
			open (FH, ">:raw", $outfile) || die ("Can't open '$outfile' for writing: $!\n");
			print FH $s;
			close (FH);
		}
		else
		{
			# anything else is just linked in.
			link "$tunableFontsDir/$availableFamilies->{$family}/$_", "$tunedDir/$_";
		}
	}
	closedir(DIR);	
	
	# create the zip archive
	my $devnull = File::Spec->devnull();
	system("(cd $tempDir; zip -q $file_name.zip $file_name/* 2>&1 > $devnull)");

  if (0) {
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
	system("rm -rf $tempDir");
	
	print multipart_final();
  }
  else {
	print header({-type => 'application/zip', -attachment => "$file_name.zip"});
	open(ZIP, "< $tempDir/$file_name.zip");
	while (read(ZIP, $buffer, 1024)) {
	   print $buffer;
	}
	close(ZIP);
	system("rm -rf $tempDir");
  }

	exit;
}

else {
	#
	# Initial page: present welcome screen, font family choice
	#
	my $tempDir = $cgi->param('temp_dir');
	if ($tempDir ne '') {
		system("rm -rf $tempDir");
	}

	print
		header(-charset => 'UTF-8'),
		start_html({-leftmargin => '18px', -title => $title}),
	
		h2({-style => 'margin-bottom: 3px'}, "Welcome to $title!"),
		p({-style => 'margin-top: 0px'}, em("type that's tuned to suit your taste")),
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
						-values => [ sort keys %$availableFamilies ],
						-default => $defaultFamily,
						-labels => $availableFamilies
					)
				])
			])
		);
		
	print
		hr,
		submit('Select family'),
		defaults('Reset'),
		end_form,
		end_html;
	
	exit;
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
		push @$values, $atts{'name'};
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
		);
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
		my $value = $cgi->param($featureName);
		print SETTINGS "\t<feature name=\"$featureName\" value=\"$value\">\n";
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

