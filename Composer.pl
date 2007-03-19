# Copyright (c) SIL International, 2007. All rights reserved.

#TODO: handle variant glyphs without $feat but with var_uid & ps_name stored too?
#TODO: handle double encoded glyphs (deprecated PUA)

use strict;
use warnings;

use Font::TTF::Font;
use XML::Parser::Expat;
use Getopt::Std;

#### global variables & constants ####

our($opt_d); #set by &getopts:

my $feat_all_base_fn = 'feat_all_test.xml';
my $feat_all_elem = "all_features";

#### subroutines ####

sub Feats_get($\%)
#create the %feats structure based on the Feat table in the font
{
	my ($font_fn, $feats) = @_;
	my ($font, $Feat_tbl, $name_tbl);

	$font = Font::TTF::Font->open($font_fn) or die "Can't open font";
	$Feat_tbl = $font->{'Feat'}->read;
	
	
	$font->release;
}

sub Gsi_xml_parse($\%\%)
#parse the GSI xml file to create the structures describing
# mapping to PS name for given USV and feature setting and
# mapping from feature settings to list of USVs effected
{
	my ($gsi_fn, $ps_name_for_usv_feat, $usvs_for_featset) = @_;
	my ($xml_parser);

	$xml_parser = XML::Parser::Expat->new();
	$xml_parser->setHandlers('Start' => sub {
		my ($xml_parser, $tag, %attrs) = @_;
		if ($tag eq '')
		{
		}
		elsif ($tag eq '')
		{
		}
		else
		{
		}
	}, 'End' => sub {
		my ($xml_parser, $tag) = @_;
		if ($tag eq '')
		{
		}
		elsif ($tag eq '')
		{
		}
		else
		{
		}
	}, 'Char' => sub {
		my ($xml_parser, $str) = @_;
		#die ("XML element content not allowed: $str\n");
	});

	$xml_parser->parsefile($gsi_fn) or die "Can't read $gsi_fn";
}

sub Features_output($\%\%\%)
#output the <feature>s elements
{
	my ($feat_all_f, $feats, $usvs_for_featset, $ps_name_for_usv_feat) = @_;
}

sub Interactions_output($\%\%)
#output the <interactions> elements
{
	my ($feat_all_f, $ps_name_for_usv_feat, $usvs_for_featset) = @_;
	
	print $feat_all_f "\t<interactions>\n";



	print $feat_all_f "\t</interactions>\n";
}

sub Aliases_output($)
#output the <aliases> elements
{
	my ($feat_all_f) = @_;

	print $feat_all_f <<END;
	<aliases>
		<alias name="IPA" value="IPA "/>
		<alias name="ROM" value="ROM "/>
		<alias name="ccmp_latin" value="ccmp"/>
		<alias name="ccmp_romanian" value="ccmp _0"/>
		<alias name="ccmp_vietnamese" value="ccmp _1"/>
		<alias name="viet_decomp" value="4"/>
		<alias name="viet_precomp" value="5"/>
		<alias name="rom_decomp" value="6"/>
		<alias name="rom_precomp" value="7"/>
	</aliases>
END
}

sub Usage_print()
{
	print <<END;
Copyright (c) SIL International, 2007. All rights reserved.
usage: 
	Composer <ttf> <xml>
END
	exit();
};

#### main processing ####

sub cmd_line_exec() #for UltraEdit function list
{}

my (%feats, %ps_name_for_usv_feat, %usvs_for_featset, $feat_all_f);
my ($font_fn, $gsi_fn, $feat_all_fn);

getopts('d'); #sets $opt_d & removes the switch from @ARGV

if (scalar @ARGV != 2)
	{Usage_print;}

($font_fn, $gsi_fn) = ($ARGV[0], $ARGV[1]);

Feats_get($font_fn, %feats);
Gsi_xml_parse($gsi_fn, %ps_name_for_usv_feat, %usvs_for_featset);

$feat_all_fn = $feat_all_base_fn; #todo adjust based on path to $font_fn
open $feat_all_f, ">$feat_all_fn" or die("Could not open $feat_all_fn for writing\n");
print $feat_all_f "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
print $feat_all_f "<!DOCTYPE all_features SYSTEM \"feat_all.dtd\">\n";
print $feat_all_f "<all_features version=\"1.0\">\n";

Features_output($feat_all_f, %feats, %usvs_for_featset, %ps_name_for_usv_feat);
Interactions_output($feat_all_f, %ps_name_for_usv_feat, %usvs_for_featset);
Aliases_output($feat_all_f); 

print $feat_all_f "</all_features>\n";
