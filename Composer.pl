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

my (%tags); #used only by below sub
sub Tag_get($$)
#get a tag for a given string
#TODO: implement this using a table lookup (probably using <DATA>)
#       to get more sensible tags. probably won't need second arg
{
	my ($str, $cnt) = @_;
	my ($tmp);

	if ($str eq "True") {return 't';}
	if ($str eq "False") {return 'f';}
	
	$tmp = substr($str, 0, $cnt);
	if ($cnt == 1)
		{$tmp = lc($tmp);}
	elsif ($cnt == 2)
		{$tmp = uc($tmp);}
	else {die("invalid second arg to Tag_get: $cnt\n");}
	
	while (defined($tags{$tmp}))
		{substr($tmp, -1, 1, chr(ord(substr($tmp, -1, 1)) + 1));}
	$tags{$tmp} = $str;
	
	return "$tmp";
}

sub Feats_get($\%)
#create the %feats structure based on the Feat table in the font
{
	my ($font_fn, $feats) = @_;
	my ($font, $Feat_tbl);

	$font = Font::TTF::Font->open($font_fn) or die "Can't open font";
	$Feat_tbl = $font->{'Feat'}->read;
	
	my ($feat, $feat_id, $set_id, $feat_nm, $set_nm, $feat_tag, $set_tag);
	foreach $feat (@{$Feat_tbl->{'features'}})
	{
		$feat_id = $feat->{'feature'};
		foreach $set_id (sort keys %{$feat->{'settings'}})
		{
			($feat_nm, $set_nm) = $Feat_tbl->settingName($feat_id, $set_id);
			#if ($opt_d) {print "Feats_get: feat_nm: $feat_nm set_nm: $set_nm\n";}
			
			if (not defined $feats->{$feat_id})
			{# this could go in the outer loop
			 #  but it is nice after the settingName call
				$feat_tag = Tag_get($feat_nm, 2);
				$feats->{$feat_id}{'name'} = $feat_nm;
				$feats->{$feat_id}{'tag'} = $feat_tag;
				$feats->{$feat_id}{'default'} = $set_id;
				if (not defined($feats->{' ids'}))
					{$feats->{' ids'} = [$feat_id];}
				else
					{push(@{$feats->{' ids'}}, $feat_id);}
			}
			
			$set_tag = Tag_get($set_nm, 1);
			$feats->{$feat_id}{'settings'}{$set_id}{'name'} = $set_nm;
			$feats->{$feat_id}{'settings'}{$set_id}{'tag'} = $set_tag;
			if (not defined($feats->{$feat_id}{'settings'}{' ids'}))
				{$feats->{$feat_id}{'settings'}{' ids'} = [$set_id];}
			else
				{push(@{$feats->{$feat_id}{'settings'}{' ids'}}, $set_id);}
		}
	}
	
	$font->release;
	
	if ($opt_d)
	{
		foreach $feat_id (@{$feats->{' ids'}})
		{
			my $feat_t = $feats->{$feat_id};
			my ($tag, $name, $default) = ($feat_t->{'tag'}, $feat_t->{'name'}, 
			                              $feat_t->{'default'});
			print "feature: $feat_id tag: $tag name: $name default: $default\n";
			foreach $set_id (@{$feats->{$feat_id}{'settings'}{' ids'}})
			{
				my $set_t = $feat_t->{'settings'}{$set_id};
				($tag, $name) = ($set_t->{'tag'}, $set_t->{'name'});
				print "  setting: $set_id tag: $tag name: $name\n";
			}
		}
	}
}

sub Gsi_xml_parse($\%\%)
#parse the GSI xml file to create the structures describing
# mapping to PS name for given USV and feature setting and
# mapping from feature settings to list of USVs affected
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
	my ($feat_all_fh, $feats, $usvs_for_featset, $ps_name_for_usv_feat) = @_;
}

sub Interactions_output($\%\%)
#output the <interactions> elements
{
	my ($feat_all_fh, $ps_name_for_usv_feat, $usvs_for_featset) = @_;
	
	print $feat_all_fh "\t<interactions>\n";



	print $feat_all_fh "\t</interactions>\n";
}

sub Aliases_output($)
#output the <aliases> elements
{
	my ($feat_all_fh) = @_;

	print $feat_all_fh <<END;
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

my (%feats, %ps_name_for_usv_feat, %usvs_for_featset, $feat_all_fh);
my ($font_fn, $gsi_fn, $feat_all_fn);

getopts('d'); #sets $opt_d & removes the switch from @ARGV

if (scalar @ARGV != 2)
	{Usage_print;}

($font_fn, $gsi_fn) = ($ARGV[0], $ARGV[1]);

Feats_get($font_fn, %feats);
Gsi_xml_parse($gsi_fn, %ps_name_for_usv_feat, %usvs_for_featset);

$feat_all_fn = $feat_all_base_fn; #todo adjust based on path to $font_fn
open $feat_all_fh, ">$feat_all_fn" or die("Could not open $feat_all_fn for writing\n");
print $feat_all_fh "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
print $feat_all_fh "<!DOCTYPE all_features SYSTEM \"feat_all.dtd\">\n";
print $feat_all_fh "<all_features version=\"1.0\">\n";

Features_output($feat_all_fh, %feats, %usvs_for_featset, %ps_name_for_usv_feat);
Interactions_output($feat_all_fh, %ps_name_for_usv_feat, %usvs_for_featset);
Aliases_output($feat_all_fh); 

print $feat_all_fh "</all_features>\n";
