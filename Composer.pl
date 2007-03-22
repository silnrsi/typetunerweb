# Copyright (c) SIL International, 2007. All rights reserved.

#Script to create a template for the TypeTuner feat_all.xml file for our Roman fonts.

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

my (%tags, $prev_feat_tag); #used only by below sub
sub Tag_get($$)
#get a tag for a given string
#second arg indicates a feature (2) or a setting (1)
#assumes feature tags are created before setting tags
#TODO: implement this using a table lookup (probably using <DATA>)
#       to get more sensible tags. probably won't need second arg
{
	my ($str, $cnt) = @_;
	my ($tmp);

	#if ($str eq "True") {return 't';}
	#if ($str eq "False") {return 'f';}
	
	$tmp = $str;
	$tmp =~ s/\s//;
	$tmp = substr($tmp, 0, $cnt);
	
	if ($cnt == 1)
	{#setting tags
		$tmp = lc($tmp);
		while (defined($tags{$prev_feat_tag}{'settings'}{$tmp}))
			{substr($tmp, -1, 1, chr(ord(substr($tmp, -1, 1)) + 1));} #changes A to B
		$tags{$prev_feat_tag}{'settings'}{$tmp} = $str;
	}
	elsif ($cnt == 2)
	{#feature tags
		$tmp = uc($tmp);
		while (defined($tags{$tmp}))
			{substr($tmp, -1, 1, chr(ord(substr($tmp, -1, 1)) + 1));} #changes AA to AB
		$tags{$tmp} = {'str' => $str}; #might as well store something useful
		$prev_feat_tag = $tmp;
	}
	else {die("invalid second arg to Tag_get: $cnt\n");}
	
	return $tmp;
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
			
			($feat_id, $set_id) = ("$feat_id", "$set_id");
			if (not defined $feats->{$feat_id})
			{# this could go in the outer loop
			 #  but it is nice after the settingName call
				$feat_tag = Tag_get($feat_nm, 2);
				$feats->{$feat_id}{'name'} = $feat_nm;
				$feats->{$feat_id}{'tag'} = $feat_tag;
				$feats->{$feat_id}{'default'} = $set_id;
				if (not defined($feats->{' ids'}))
					{$feats->{' ids'} = [];}
				push(@{$feats->{' ids'}}, $feat_id);
			}
			
			$set_tag = Tag_get($set_nm, 1);
			$feats->{$feat_id}{'settings'}{$set_id}{'name'} = $set_nm;
			$feats->{$feat_id}{'settings'}{$set_id}{'tag'} = $set_tag;
			if (not defined($feats->{$feat_id}{'settings'}{' ids'}))
				{$feats->{$feat_id}{'settings'}{' ids'} = [];}
			push(@{$feats->{$feat_id}{'settings'}{' ids'}}, $set_id);
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

sub Featset_combos_get($@)
#return an array of strings where each string indicates feature interactions
# handles multi-valued features which don't interact
# TODO: properly handle a binary-valued feature interacting with a multi-valued feature
#        currently combos are only calculated using the first multi-value found
{
	my ($feat_add, @feats) = @_;
	my (@feats_combo);
	
	#only allow one multi-valued featset to interact
	foreach (@feats)
		{if (substr($feat_add, 0, 2) eq substr($_, 0, 2))
			{return @feats_combo;}} #@feats_combo is empty
	
#	see todo above
#	my ($multi_found, $bin_found) = (0, 0);
#	foreach (@feats, $feat_add)
#	{#this does not work, need better test to determine if a multi or binary value
#		my $set = substr($_, -1, 1);
#		if ($set ne 't' && $set ne 'f')
#			{$multi_found = 1;}
#		else
#			{$bin_found = 1;}
#	}
#	if ($multi_found && $bin_found)
#		{die "error: multi-valued an binary-valued features interact: $feat_add, @feats\n";}
#	if ($multi_found)
#		{@feats_combo = (undef);return @feats_combo;}

	if (scalar @feats == 1)
	{
		push(@feats_combo, join(' ', sort($feats[0], $feat_add)));
	}
	elsif (scalar @feats == 2)
	{
		push (@feats_combo, join(' ', sort($feats[0], $feat_add)));
		push (@feats_combo, join(' ', sort($feats[1], $feat_add)));
		#push (@feats_combo, join(' ', sort($feats[0], $feats[1]))); should already be handled
		push (@feats_combo, join(' ', sort($feats[0], $feats[1], $feat_add)));
	}
	else
	{
		die("too many features interacting: $feat_add, @feats\n");
	}
	
	return @feats_combo;
}

sub Gsi_xml_parse($\%\%\%)
#parse the GSI xml file to create the structures describing
# mapping to PS name for given USV and feature setting and
# mapping from feature settings to list of USVs affected
{
	my ($gsi_fn, $feats, $usv_feat_to_ps_name, $featset_to_usvs) = @_;
	my ($xml_parser, $ps_name, $var_uid_capture, $var_uid, $feat_found);

	$xml_parser = XML::Parser::Expat->new();
	$xml_parser->setHandlers('Start' => sub {
		my ($xml_parser, $tag, %attrs) = @_;
		if ($tag eq 'ps_name')
		{
			$ps_name = $attrs{'value'};
			$feat_found = 0;
		}
		elsif ($tag eq 'var_uid')
		{
			$var_uid = undef;
			$var_uid_capture = 1;
		}
		elsif ($tag eq 'feature')
		{
			if (not defined($var_uid)) {die("not USV for feature: $attrs{'category'}")};
			my $usv = substr($var_uid, 2);
			
			my $feat = $attrs{'category'};
			my $set;
			if (defined ($attrs{'value'}))
				{$set = $attrs{'value'};}
			else
				{$set = '1';}
			my $featset = $feats->{$feat}{'tag'} . $feats->{$feat}{'settings'}{$set}{'tag'};
			
			if (not defined ($featset_to_usvs->{$featset}))
				{$featset_to_usvs->{$featset} = [];}
			push(@{$featset_to_usvs->{$featset}}, $usv);
			
			#handle interacting features
			my @prev_feats;
			foreach (keys %{$usv_feat_to_ps_name->{$usv}})
				{if ($_ ne 'unk') {push(@prev_feats, $_);}} #nothing interacts with unk features
			if (scalar @prev_feats)
			{
				my @featset_combos = Featset_combos_get($featset, @prev_feats);
				foreach $featset (@featset_combos)
				{
					if (not defined($featset_to_usvs->{$featset}))
						{$featset_to_usvs->{$featset} = [];}
					push(@{$featset_to_usvs->{$featset}}, $usv);
				}
			}
			
			$usv_feat_to_ps_name->{$usv}{$featset} = $ps_name;
			$feat_found = 1;
		}
		else
		{}
	}, 'End' => sub {
		my ($xml_parser, $tag) = @_;
		if ($tag eq 'ps_name')
		{
			if (!$feat_found && defined($var_uid))
			{ #use 'unk' featset to store info on variant glyphs w/o features
				my $usv = substr($var_uid, 2);
				if (not defined($usv_feat_to_ps_name->{$usv}{'unk'}))
					{$usv_feat_to_ps_name->{$usv}{'unk'} = []}
				push(@{$usv_feat_to_ps_name->{$usv}{'unk'}}, $ps_name);
			} 
			$ps_name = undef;
		}
		elsif ($tag eq 'var_uid')
		{
			$var_uid_capture = 0;
		}
		else
		{}
	}, 'Char' => sub {
		my ($xml_parser, $str) = @_;
		if ($var_uid_capture)
			{$var_uid .= $str;}
	});

	$xml_parser->parsefile($gsi_fn) or die "Can't read $gsi_fn";
	
	if ($opt_d)
	{
		foreach (sort keys %$usv_feat_to_ps_name) {print "$_ "}; print "\n";
		foreach (sort keys %$featset_to_usvs) {print "($_)"}; print "\n";
	}
}

sub Features_output($\%\%\%)
#output the <feature>s elements
{
	my ($feat_all_fh, $feats, $featset_to_usvs, $usv_feat_to_ps_name) = @_;
}

sub Interactions_output($\%\%)
#output the <interactions> elements
{
	my ($feat_all_fh, $usv_feat_to_ps_name, $featset_to_usvs) = @_;
	
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

my (%feats, %usv_feat_to_ps_name, %featset_to_usvs, $feat_all_fh);
my ($font_fn, $gsi_fn, $feat_all_fn);

getopts('d'); #sets $opt_d & removes the switch from @ARGV

if (scalar @ARGV != 2)
	{Usage_print;}

($font_fn, $gsi_fn) = ($ARGV[0], $ARGV[1]);

Feats_get($font_fn, %feats);
Gsi_xml_parse($gsi_fn, %feats, %usv_feat_to_ps_name, %featset_to_usvs);

$feat_all_fn = $feat_all_base_fn; #todo adjust based on path to $font_fn
open $feat_all_fh, ">$feat_all_fn" or die("Could not open $feat_all_fn for writing\n");
print $feat_all_fh "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
print $feat_all_fh "<!DOCTYPE all_features SYSTEM \"feat_all.dtd\">\n";
print $feat_all_fh "<all_features version=\"1.0\">\n";

Features_output($feat_all_fh, %feats, %featset_to_usvs, %usv_feat_to_ps_name);
Interactions_output($feat_all_fh, %usv_feat_to_ps_name, %featset_to_usvs);
Aliases_output($feat_all_fh); 

print $feat_all_fh "</all_features>\n";
