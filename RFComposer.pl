# © SIL International 2007. All rights reserved.
# Please do not redistribute.

#Script to create a template for the TypeTuner feat_all.xml file for our Roman fonts.
# I should have written this in Python. I could have parsed the features.gdh file myself
# instead of using Font::TTF to get the info from the font.

use strict;
use warnings;

use Font::TTF::Font;
use XML::Parser::Expat;
use Getopt::Std;

#### global variables & constants ####

#$opt_d - debug output
#$opt_g - output only graphite cmds
#$opt_q - output no graphite cmds
#$opt_t - output <interaction> encode cmds w/o choices for PS name for testing TypeTuner
#$opt_l - list features and settings to a file to help create %nm_to_tag map
our($opt_d, $opt_g, $opt_q, $opt_t, $opt_l); #set by &getopts:
my $opt_str = 'dgqtl';
my $featset_list_fn = 'featset_list.txt';

my $feat_all_base_fn = 'feat_all_composer.xml';
my $feat_all_elem = "all_features";

#all the ids must be 4 digits
my $vietnamese_style_diacs_feat = '1029';
my $romanian_style_diacs_feat = '1041';

#map feature settings to PS names using regex matching
#only need mappings for feature settings that interact
#mappings that are missing below will be output as error messages
#the (?! ... ) reg ex below is a negative look ahead match
# the error message can be processed to add to the mappings
# *** Be careful to not discard tags needed by fonts other than the one being worked on
my %featset_to_suffix = (
	'BarBwl-T' => '\.BarBowl', 
	'Caron-T' => '\.Caron', 
	'CyShha-T' => '\.UCStyle', 
	'CyrE-T' => '\.MongolStyle', 
	'Lit-T' => '(\.SngBowl|\.SngStory)', 
	'ModAp-Lg' => '\.Lrg', 
	'Ognk-Strt' => '\.RetroHookStyle', 
	'OpnO-TopSrf' => '\.TopSerif', 
	'Ou-Opn' => '\.OpenTop', 
	'RONdiacs-T' => '\.CommaStyle', 
	'SlntItlc-T' => '(\.SlantItalic|\.2StorySlantItalic)', 
	'SmCp-T' => '\.SC',
	'SmPHk-RtHk' => '\.BowlHook', 
	'VHk-Crvd' => '(uni01B2|028B)(?!\.StraightLftHighHook|\.StraightLft)',  
	'VHk-StrtLftLowHk' => '\.StraightLft', 
	'VHk-StrtLftHk' => '\.StraightLftHighHook', 
	'VIEdiacs-T' => '\.VN',
	'DepPUA-41' => '\.Dep41', 
	'DepPUA-50' => '\.Dep50', 
	'DepPUA-51' => '\.Dep51', 
	'BrdgDiacs-T' => '(\.UU|\.UL|\.LL)',
	'Eng-LgDsc' => '[eE]ng(?!\.UCStyle|\.BaselineHook|\.Kom)', 
	'Eng-LgBsln' => '\.BaselineHook', 
	'Eng-CapN' => '\.UCStyle', 
	'Eng-LgShrtStm' => '\.Kom',
);

#generated using the -l switch 
# then copying & pasting the file produced into this file.
# *** Be sure to compare this list to the generated one so as to not lose some tags
#     ie if working on Doulos don't lose the Andika ones.
# used calls to &Tag_get to create initially then commented them out
# and now use &Tag_lookup calls to maintain
my %nm_to_tag = (
	'Tone numbers' => 'TnNmbr',
	'False' => 'F',
	'True' => 'T',
	'Hide tone contour staves' => 'TnStvsHd',
	'9-level pitches' => 'NineLvl',
	'Ligated' => 'Lgt',
	'Show tramlines' => 'TrmLn',
	'Non-ligated' => 'NoLgt',
	'Show tramlines, non-ligated' => 'TrmLnNoLgt',
	'Vietnamese-style diacritics' => 'VIEdiacs',
	'Romanian-style diacritics' => 'RONdiacs',
	'Chinantec tones' => 'CHZtn',
	'Bridging diacritics' => 'BrdgDiacs',
	'Barred-bowl forms' => 'BarBwl',
	'Literacy alternates' => 'Lit',
	'Slant italic specials' => 'SlntItlc',
	'Uppercase Eng alternates' => 'Eng',
	'Large eng with descender' => 'LgDsc',
	'Large eng on baseline' => 'LgBsln',
	'Capital N with tail' => 'CapN',
	'Large eng with short stem' => 'LgShrtStm',
	'Rams horn alternates' => 'RmHrn',
	'Small bowl' => 'Sm',
	'Large bowl' => 'Lrg',
	'Small gamma' => 'Gma',
	'Ogonek alternate' => 'Ognk',
	'Curved' => 'Crv',
	'Straight' => 'Strt',
	'Capital B-hook alternate' => 'LrgBHk',
	'Capital H-stroke alternate' => 'LgHStrk',
	'Horizontal stroke' => 'Hrz',
	'Vertical stroke' => 'Vrt',
	'J-stroke hook alternate' => 'JStrk',
	'No serif' => 'NoSrf',
	'Top serif' => 'TopSrf',
	'Capital N-left-hook alternate' => 'LgNLftHk',
	'Uppercase style' => 'Uc',
	'Lowercase style' => 'Lc',
	'Open-O alternate' => 'OpnO',
	'Bottom serif' => 'BtmSrf',
	'Small p-hook alternate' => 'SmPHk',
	'Left hook' => 'LftHk',
	'Right hook' => 'RtHk',
	'Capital R-tail alternate' => 'LgRTl',
	'Capital T-hook alternate' => 'LgTHk',
	'V-hook alternates' => 'VHk',
	'Curved' => 'Crvd', 
	'Straight left' => 'StrtLftLowHk',
	'Straight left high hook' => 'StrtLftHk',
	'Capital Y-hook alternate' => 'LgYHk',
	'Small ezh-curl alternate' => 'SmEzhCrl',
	'Capital Ezh alternates' => 'LgEzh',
	'Normal' => 'Nrml',
	'Reversed sigma' => 'RvSgma',
	'OU alternates' => 'Ou',
	'Closed' => 'Clsd',
	'Open' => 'Opn',
	'Mongolian-style Cyrillic E' => 'CyrE',
	'Modifier apostrophe alternates' => 'ModAp',
	'Small' => 'Sm',
	'Large' => 'Lg',
	'Modifier colon alternate' => 'ModCol',
	'Tight' => 'Tght',
	'Wide' => 'Wd',
	'Non-European caron alternates' => 'Caron',
	'Combining breve Cyrillic form' => 'CmbBrvCyr',
	'Cyrillic shha alternate' => 'CyShha',
	'Empty set alternates' => 'EmpSet',
	'Circle' => 'Crcl',
	'Zero' => 'Zro',
	'Small Caps' => 'SmCp',
	'Show deprecated PUA' => 'DepPUA',
	'None' => 'none',
	'Through Unicode 4.0' => '40',
	'Through Unicode 4.1' => '41',
	'Through Unicode 5.0' => '50',
	'Through Unicode 5.1' => '51',
	'Show invisible characters' => 'ShwInv',
	'Digit Zero with slash' => 'Dig0',
	'Digit One without base' => 'Dig1',
	'Digit Four with open top' => 'Dig4',
	'Digit Six and Nine alternates' => 'Dig69',
	'Digit Seven with bar' => 'Dig7',
	'Small i-tail alternate' => 'SmITail',
	'Small j-serif alternate' => 'SmJSerif',
	'Small l-tail alternate' => 'SmLTail',
	'Capital Q alternate' => 'CapQ',
	'Small q-tail alternate' => 'SmQTail',
	'Small t-tail alternate' => 'SmTTail',
	'Small y-tail alternate' => 'SmYTail',
	'Diacritic selection' => 'DiacSlct',
	'Line spacing' => 'LnSpc',
	'Loose' => 'Ls',
	'Imported' => 'Im',
);

#### subroutines ####

my (%tags, $prev_feat_tag); #used only by two below sub
sub Tag_get($$)
#get a tag for a given string
#second arg indicates a feature (2) or a setting (1)
#assumes feature tags are created before setting tags
{
	my ($str, $cnt) = @_;
	my ($tmp);

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
		if ($tmp eq '9-') {$tmp = 'NI'} #kludge for '9-level pitches' feature
		$tmp = uc($tmp);
		while (defined($tags{$tmp}))
			{substr($tmp, -1, 1, chr(ord(substr($tmp, -1, 1)) + 1));} #changes AA to AB
		$tags{$tmp} = {'str' => $str}; #might as well store something useful
		$prev_feat_tag = $tmp;
	}
	else {die("invalid second arg to Tag_get: $cnt\n");}
	
	return $tmp;
}

sub Tag_lookup($\%)
#lookup name in name-to-tag map and return tag
#generate a new tag if name isn't in map
{
	my ($name, $nm_to_tag) = @_;
	if (defined $nm_to_tag->{$name})
	{
		$tags{$nm_to_tag->{$name}} = {'str' => $name}; #insures Tag_get tags are unique
		return $nm_to_tag->{$name};
	}
	else
	{
		print "*** new name found so generating a tag - name:$name\n";
		return Tag_get($name, 2); #always get two-letter tags
	}
}

sub Feats_get($\%)
#create the %feats structure based on the Feat table in the font
{
	my ($font_fn, $feats) = @_;
	my ($font, $GrFeat_tbl);

	$font = Font::TTF::Font->open($font_fn) or die "Can't open font";
	$GrFeat_tbl = $font->{'Feat'}->read;
	#$GrFeat_tbl->print;
	
	my ($feat, $feat_id, $set_id, $feat_nm, $set_nm, $feat_tag, $set_tag);
	foreach $feat (@{$GrFeat_tbl->{'features'}})
	{
		$feat_id = $feat->{'feature'};
		foreach $set_id (sort keys %{$feat->{'settings'}})
		{
			if ($feat_id == 1) {next;} #skip over weird last feature in Feat table
			($feat_nm, $set_nm) = $GrFeat_tbl->settingName($feat_id, $set_id);
			
			if (not defined $feats->{$feat_id})
			{# this could go in the outer loop
			 #  but it is nice after the settingName call
				$feat_tag = Tag_lookup($feat_nm, %nm_to_tag);
				$feats->{$feat_id}{'name'} = $feat_nm;
				$feats->{$feat_id}{'tag'} = $feat_tag;
				$feats->{$feat_id}{'default'} = $feat->{'default'};
				if (not defined($feats->{' ids'}))
					{$feats->{' ids'} = [];}
				push(@{$feats->{' ids'}}, $feat_id);
			}
			
			$set_tag = Tag_lookup($set_nm, %nm_to_tag);
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

sub Combos_get(@)
#input is an array of elements
#enumerate all combinations of the elements (with no repetition of an element in a combination)
#return an array of references to arrays where each array enumerates a combination
# eg [1,2,3] -> [[1],[2],[3],[1,2],[1,3],[2,3],[1,2,3]]
#the algorithm works by creating single combos from the input array
# then combining the first combo with each element of the input array skipping over the first
# then combining the second combo with each element of the input skipping over the first & second
# and repeating until all pair combos have been found
#then the same thing is done to combine all pair combos with elements of the input array to create triplets
#the index of the last input element to be added to a combination is kept to avoid creating combos
# that already exist
#then the same thing is done with all triplets to generate quads, and so on
{
	my (@element) = (@_);
	my ($u, $v, $w, $i, @combos, $combo_ix); 
	
	#each @combo element will be a ref to an array of refs to hashes
	# the hashes will contain a ref to 1) an array that contains a combination 
	# and 2) an ix that gives the index in the input array 
	# that was most recently added to the combination
	
	#initialize the first @combo element 
	$u = [];
	$i = 0;
	foreach (@element) {push(@$u, {'@' => [$_], 'ix' => $i++})};
	push (@combos, $u);
	$combo_ix = 1;
	
	#create all combinations with no input element duplicated
	while ($combo_ix < scalar @element)
	{
		$u = $combos[$combo_ix - 1];
		$w = [];
		my $h;
		foreach $h (@$u)
		{
			for ($i = $h->{'ix'} + 1; $i < scalar @element; $i++)
			{
				$v = {'@' => [@{$h->{'@'}}], 'ix' => $h->{'ix'}}; #don't really need ix
				push(@{$v->{'@'}}, $element[$i]);
				$v->{'ix'} = $i;
				push(@$w, $v);
			}
		}
		push(@combos, $w);
		$combo_ix++;
	}
	
	#flatten out @combo to only contain refs to arrays
	# (ie throw out the 'ix' element and the now unneeded hash)
	$w = [];
	foreach $u (@combos) { foreach (@$u) {push(@$w, $_->{'@'})} };
	return @$w;
}

sub Combos_filtered_get(@)
#input is an array of feature settings
#enumerate all combinations of the settings
#filter out combinations that contain multiple settings of the same feature
# (multi-valued feature settings are mutually exclusive)
#return an array of references to arrays where each array enumerates feature settings interactions
{
	my (@combos, $combo, @filtered);
	
	@combos = Combos_get(@_);
	foreach (@combos)
	{
		my @combo = @$_;
		my $valid = 1;	
		my $ct = scalar @combo;
		for (my $i = 0; ($i < $ct) && $valid; $i++)
		{
			my $feat_i = $combo[$i];
			$feat_i =~ s/(.*)-.*/$1/;
			for (my $j = $i + 1; ($j < $ct) && $valid; $j++)
			{
				my $feat_j = $combo[$j];
				$feat_j =~ s/(.*)-.*/$1/;
				if ($feat_i eq $feat_j)
				{
					$valid = 0;
				}
			}
		}
		if ($valid)
			{push(@filtered, $_);}
	}
	return @filtered;
}

sub Featset_combos_get($@)
#inputs are a new feature setting and an array of previous feature settings
#enumerate all valid combinations of the new setting with the previous ones
#return an array of references to arrays where each array enumerates a combination
{
	my ($feat_add, @feats) = @_;
	my (@combo, @feats_combo, $c);

	@combo = Combos_filtered_get((@feats, $feat_add));
	#skip over combinations containing one element or 
	# which don't contain the feature being added
	foreach $c (@combo)
		{if ((scalar @$c != 1) && (@$c[-1] eq $feat_add))
			{push(@feats_combo, join(' ', sort(@$c)));}}
	return @feats_combo;
}

#This code is now obsolete. I've left it here now for reference.
#sub Featset_combos_get($@)
##return an array of strings where each string indicates feature interactions
## handles multi-valued features whose settings should not interact
## mv = multi-valued feature. bv = binary-valued feature
## 		properly handle a bv setting interacting with mv settings
##		the bv setting should interact with each mv setting
##		but the mv settings should NOT interact with each other
##		currently the bv & mv features don't interact so this case isn't handled
#{
#	my ($feat_add, @feats) = @_;
#	my (@feats_combo);
#	
#	#prevent the various settings for a mv feature from interacting
#	foreach (@feats)
#		{if (substr($feat_add, 0, 2) eq substr($_, 0, 2))
#			{return @feats_combo;}} #@feats_combo is empty
#	
#	if (scalar @feats == 1)
#	{
#		push(@feats_combo, join(' ', sort($feats[0], $feat_add)));
#	}
#	elsif (scalar @feats == 2)
#	{
#		push (@feats_combo, join(' ', sort($feats[0], $feat_add)));
#		push (@feats_combo, join(' ', sort($feats[1], $feat_add)));
#		#push (@feats_combo, join(' ', sort($feats[0], $feats[1]))); should already be handled
#		push (@feats_combo, join(' ', sort($feats[0], $feats[1], $feat_add)));
#	}
#	else
#	{
#		die("too many features interacting: $feat_add, @feats\n");
#	}
#	
#	return @feats_combo;
#}

sub Gsi_xml_parse($\%\%\%)
#parse the GSI xml file to create the structures describing
# mapping to PS name for given USV and feature setting and
# mapping from feature settings to list of USVs affected
#
# The DepPUA features don't interact with any other features because:
# The var_uid for *.Dep?? glyphs holds the PUA codepoint 
# (though the glyphs are double encoded in FL and named based on official USV).
# Because of this, interaction with other features is masked 
# since that is tracked using USVs in the MGI.
# The official USV for the deprecated glyphs could somehow be used 
# so these glyphs can be offered as choices in cmd elements.
# Note that the var_uid with the deprecated USV is needed for the DepPUA feature 
# (and font testing), so that they can be re-encoded properly (and rendered in testing).
# In the current scheme, this means any re-encoding specified by other feature settings 
# will be overridden by a .Dep?? glyph, 
# which should be OK since we don't want to create inverted glyphs for all features
# that effect deprecated USVs.
{
	my ($gsi_fn, $feats, $usv_feat_to_ps_name, $featset_to_usvs) = @_;
	
	my ($xml_parser, $active, $ps_name, $feat_found, $var_uid_capture, $var_uid);
	$xml_parser = XML::Parser::Expat->new();
	$xml_parser->setHandlers('Start' => sub {
		my ($xml_parser, $tag, %attrs) = @_;
		if ($tag eq 'glyph')
		{
			if ($attrs{'active'} eq '0')
				{$active = 0;}
			else
				{$active = 1;}
		}
		#filter out inactive glyphs
		if (not $active) {return;}
		if ($tag eq 'ps_name')
		{
			$ps_name = $attrs{'value'};
			$feat_found = 0;
		}
		elsif ($tag eq 'var_uid')
		{
			$var_uid_capture = 1;
		}
		elsif ($tag eq 'feature')
		{
			if (not defined($ps_name)) {die("no PS name for feature: $attrs{'category'}\n")};
			if (not defined($var_uid)) 
			{#glyphs w/o var_uid's can't be offered as choices in encode cmds
			 #should be: 1) variant for a ligature, 2) default glyph for a multivalued feature,
			 # 3) variant that is encoded --
			 # 3 - should be fixed up by Special_glyphs_handle()
			 # 2 - these probably should also be fixed up in Special_glyphs_handle()
			 # 1 - there's no way to handle this by re-encoding the cmap, so can't do anything
				if ($opt_d) {print "no var_uid for ps_name: $ps_name feat: $attrs{'category'}\n";}
				return;
			}; 
			my $usv = substr($var_uid, 2);
			
			my $feat = $attrs{'category'};
			my $set;
			if (defined ($attrs{'value'}))
				{$set = $attrs{'value'};}
			else #for binary valued features the GSI indicates 
				  #when they should be set the opposite of the default
				  #this will fail if setting ids 0 & 1 aren't used for binary features
				{$set = $feats->{$feat}{'default'} ? 0 : 1;}
			my $feat_tag = $feats->{$feat}{'tag'}; 
			my $set_tag = $feats->{$feat}{'settings'}{$set}{'tag'};
			if (!$feat_tag || !$set_tag)
				{die("feature or setting in GSI missing from font Feat table: $feat set: $set\n");}
			my $featset = "$feat_tag-$set_tag";
			
			if (not defined ($featset_to_usvs->{$featset}))
				{$featset_to_usvs->{$featset} = [];}
			if (scalar (grep {$_ eq $usv} @{$featset_to_usvs->{$featset}}) == 0)
				{push(@{$featset_to_usvs->{$featset}}, $usv);}
			
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
					if (scalar (grep {$_ eq $usv} @{$featset_to_usvs->{$featset}}) == 0)
						{push(@{$featset_to_usvs->{$featset}}, $usv);}
				}
			}
			
			if (not defined($usv_feat_to_ps_name->{$usv}{$featset}))
				{$usv_feat_to_ps_name->{$usv}{$featset} = [];}
			push(@{$usv_feat_to_ps_name->{$usv}{$featset}}, $ps_name);
			$feat_found = 1;
		}
		else
		{}
	}, 'End' => sub {
		my ($xml_parser, $tag) = @_;
		if ($tag eq 'glyph')
		{
			if (!$feat_found && defined($var_uid))
			{ #use 'unk' featset to store info on variant glyphs w/o features
				my $usv = substr($var_uid, 2);
				if (not defined($usv_feat_to_ps_name->{$usv}{'unk'}))
					{$usv_feat_to_ps_name->{$usv}{'unk'} = []}
				push(@{$usv_feat_to_ps_name->{$usv}{'unk'}}, $ps_name);
			} 
			$ps_name = undef;
			$var_uid = undef;
		}
		elsif ($tag eq 'ps_name')
		{}
		elsif ($tag eq 'var_uid')
		{
			$var_uid_capture = 0;
		}
		elsif ($tag eq 'feature')
		{}
		else
		{}
	}, 'Char' => sub {
		my ($xml_parser, $str) = @_;
		if ($var_uid_capture)
			{if (not defined($var_uid))
				{$var_uid = $str;}
			else
				{$var_uid .= $str;}
			}
	});

	$xml_parser->parsefile($gsi_fn) or die "Can't read $gsi_fn";
	
	if ($opt_d)
	{
		print "usvs with variant glyphs: ";
		foreach (sort keys %$usv_feat_to_ps_name) {print "$_ "}; print "\n";
		print "featsets with variant glyphs: ";
		foreach (sort keys %$featset_to_usvs) {print "($_)"}; print "\n";
	}
}

sub Special_glyphs_handle($\%\%\%)
#add variant glyph info which isn't indicated in the GSI data to various hashes 
# this allows the glyph to offered as a choice in the cmd elements
{
	my ($gsi_supp_fn, $feats, $usv_feat_to_ps_name, $featset_to_usvs) = @_;
	
	#add uni01B7.RevSigmaStyle as a variant for U+01B7 for feature Capital Ezh alternates (1042)
	# this is a variant glyph that is also encoded in the PUA (F217)
	# so there is no <var_uid> in the GSI data for it
	# the below code doesn't handle the case where 01B7 has more than one variant, so die if that occurs
	if (defined $usv_feat_to_ps_name->{'01B7'}) {die "status of 01B7 has changed\n";}
	my $feat_tag = $feats->{'1042'}{'tag'};
	my $set_id = $feats->{'1042'}{'settings'}{' ids'}[1];
	my $set_tag = $feats->{'1042'}{'settings'}{$set_id}{'tag'};
	my $featset = "$feat_tag-$set_tag";
	if (not defined $featset_to_usvs->{$featset})
		{$featset_to_usvs->{$featset} = [];}
	push(@{$featset_to_usvs->{$featset}}, '01B7');
	$usv_feat_to_ps_name->{'01B7'}{$featset} = ['uni01B7.RevSigmaStyle'];

	#small cap support - handle lower case eng interacting with eng alternate feature
	if ($gsi_supp_fn)
		{Gsi_xml_parse($gsi_supp_fn, %$feats, %$usv_feat_to_ps_name, %$featset_to_usvs);}
}

sub Dblenc_get($\%)
#parse the DblEnc.txt file which indicates deprecated PUA chars and their official USVs
{
	my ($dblenc_fn, $dblenc_usv) = @_;
	
	open FH, "<$dblenc_fn" or die("Could not open $dblenc_fn for reading\n");
	while (<FH>)
	{
		chomp;
		my @fields = split(/,/, $_);
		if (scalar @fields != 3) {die("file $dblenc_fn has corrupt line: $_\n");}
		my ($primary_usv, $deprecated_usv) = map {substr($_, 2)} ($fields[2], $fields[1]);
		$dblenc_usv->{$primary_usv} = $deprecated_usv;
	}
	close FH;
	
	if ($opt_d)
	{
		print "double encoded usvs: ";
		foreach (sort values %$dblenc_usv) {print "$_ ";}; print "\n";
	}
}

sub Suffixes_get(\@)
#get all the PS name suffixes for an array of feature settings
#return an empty array if any feature setting doesn't have a suffix
{
	my ($featsets) = @_;
	my @suffixes;
	foreach my $featset (@$featsets)
	{
		if (defined($featset_to_suffix{$featset}))
		{
			push(@suffixes, $featset_to_suffix{$featset});
		}
		else
		{
			print "*** no suffix found for $featset\n";
			@suffixes = ();
			return @suffixes;
		}
	}
	return @suffixes;
}

sub Suffixes_match_name(\@$)
#test if a PS name matches all of the suffixes in an array
# and that there aren't any extra suffixes in the PS name
#(the suffixes are now reg exs and represent feature setings)
# a regex for a multi-value default glyph might match but have no suffix
# eg (uni01B2|028B)(?!\.StraightLftHighHook|\.StraightLft)
#the current approach still assumes that extra suffixes in the PS name are sufficient 
# to eliminate glyphs that should only be used if more feature settings are active
#returns true if the suffix array is empty
{
	my ($suffixes, $name) = @_;
	
	return 1 if (scalar @$suffixes == 0);
	
	my @t = split(/\./, $name);
	my $name_suffix_ct = scalar @t - 1;
	if ($name_suffix_ct > scalar @$suffixes)
		{return 0;} 
	my $suffix_match_ct = 0;
	foreach my $suffix (@$suffixes)
		{if ($name =~ /$suffix/) {$suffix_match_ct++;}}
	if ($suffix_match_ct == scalar @$suffixes)
		{return 1;}
	else
		{return 0;}
}

sub PSName_select(\@$)
#choose the first name in a space delimited string that matches the feature settings
#return origial names if no match found
{
	my ($featsets, $choices) = @_;
	
	my @suffixes = Suffixes_get(@$featsets);
	
	foreach my $choice (split(/\s/, $choices))
	{
		if (Suffixes_match_name(@suffixes, $choice))
			{return $choice;}
	}

	return $choices;
}

sub Features_output($\%\%\%\%)
#output the <feature>s elements
#all value elements contain at least a gr_feat cmd or a cmd="null" (if a default)
#output all of these even though a USV effected by both a binary-valued feature 
# and a multi-valued feature will always be handled by an interactions element
# the mv feature always has a setting, even if it's the default.
{
	my ($feat_all_fh, $feats, $featset_to_usvs, $usv_feat_to_ps_name, $dblenc_usv) = @_;
	my $fh = $feat_all_fh;
	my ($feat_id, $set_id);
	
	foreach $feat_id (@{$feats->{' ids'}})
	{
		my $feat = $feats->{$feat_id};
		my ($feat_nm, $feat_tag) = ($feat->{'name'}, $feat->{'tag'});
		my $feat_def_id = $feat->{'default'};
		my $feat_def_nm = $feat->{'settings'}{$feat_def_id}{'name'};
		
		#start feature element
		print $fh "\t<feature name=\"$feat_nm\" value=\"$feat_def_nm\" tag=\"$feat_tag\">\n";
		
		foreach $set_id (@{$feat->{'settings'}{' ids'}})
		{
			my $set = $feat->{'settings'}{$set_id};
			my ($set_nm, $set_tag) = ($set->{'name'}, $set->{'tag'});
			
			#start value element
			print $fh "\t\t<value name=\"$set_nm\" tag=\"$set_tag\">\n";
			
			#cmd elements
			
			if ($opt_g and $opt_q)
			{#null cmd if nothing to output
				print $fh "\t\t\t<cmd name=\"null\" args=\"null\"/>\n";
				goto cmd_end;
			}
			
			if ($set_id eq $feat_def_id)
			{#default feature and setting
				print $fh "\t\t\t<cmd name=\"null\" args=\"null\"/>\n";
				goto cmd_end;
			}
			
			my $flag = 0;
			
			### gr_feat cmd
			unless ($opt_q)
			{
				print $fh "\t\t\t<cmd name=\"gr_feat\" args=\"$feat_id $set_id\"/>\n";
				$flag = 1;
			}
			
			#### OT cmds that manipulate the script, language, feature, or lookup structures
			if ($vietnamese_style_diacs_feat =~ /$feat_id/ and not $opt_g)
			{#hard-coded
				print $fh "\t\t\t<cmd name=\"lookup_add\" args=\"GSUB {ccmp_latin} {viet_decomp}\"/>\n";
				print $fh "\t\t\t<cmd name=\"lookup_add\" args=\"GSUB {ccmp_latin} {viet_precomp}\"/>\n";
				#see comment on VIt and ROt in Interactions_output()
				#print $fh "\t\t\t<cmd name=\"feat_del\" args=\"GSUB latn {IPA} {ccmp_latin}\"/>\n";
				#print $fh "\t\t\t<cmd name=\"feat_add\" args=\"GSUB latn {IPA} {ccmp_vietnamese} 0\"/>\n";
				$flag = 1;
			}
			if ($romanian_style_diacs_feat =~ /$feat_id/ and not $opt_g)
			{#hard-coded
				print $fh "\t\t\t<cmd name=\"lookup_add\" args=\"GSUB {ccmp_latin} {rom_decomp}\"/>\n";
				print $fh "\t\t\t<cmd name=\"lookup_add\" args=\"GSUB {ccmp_latin} {rom_precomp}\"/>\n";
				$flag = 1;
			}
			
			#### encode cmds
			# this code is similar to Test_output
			my $featset = "$feat_tag-$set_tag";
			if (defined($featset_to_usvs->{$featset}) and not $opt_g)
			{#write one cmd for each variant glyph associated with this feature setting
				my @usvs = @{$featset_to_usvs->{$featset}};
				my ($usv, $ps_name);
				foreach $usv (@usvs)
				{
					my @ps_names = @{$usv_feat_to_ps_name->{$usv}{$featset}};
					my $choices .= join(' ', @ps_names);
					
					if (scalar @ps_names > 1)
					{
						my @featsets = ($featset);
						$choices = PSName_select(@featsets, $choices);
					}
					
					if ($opt_t) #output legal args for testing TypeTuner
						{my @c = split(/\s/, $choices); $choices = $c[0];}
						
					if (index($choices, ' ') != -1)
						{print $fh "\t\t\t<!-- edit below line(s) -->\n";}
						
					print $fh "\t\t\t<cmd name=\"encode\" args=\"$usv $choices\"/>\n";
					if (defined $dblenc_usv->{$usv})
						{print $fh "\t\t\t<cmd name=\"encode\" args=\"$dblenc_usv->{$usv} $choices\"/>\n";}
				}
				$flag = 1;
			}
			
			if (not $flag)
			{
				print $fh "\t\t\t<cmd name name=\"null\" args=\"null\"/>\n";
			};
			
			cmd_end:
			#end value element
			print $fh "\t\t</value>\n";
		}
		
		#end feature element
		print $fh "\t</feature>\n";
	}
	
	### output line spacing feature
	unless ($opt_g)
	{
		my $line_gap_tag = Tag_lookup('Line spacing', %nm_to_tag);
		my $tight_tag = Tag_lookup('Tight', %nm_to_tag);
		my $normal_tag = Tag_lookup('Normal', %nm_to_tag);
		my $loose_tag = Tag_lookup('Loose', %nm_to_tag);
		my $imported_tag = Tag_lookup('Imported', %nm_to_tag);
		if (not $opt_t)
		{ #be careful of tabs in section below for proper output
			print $fh <<END
	<feature name="Line spacing" value="Normal" tag="$line_gap_tag">
		<!-- edit the below lines to provide the correct line metrics -->
		<!-- Doulos -->
		<value name="Normal" tag="$normal_tag">
			<cmd name="null" args="2324 810"/>
		</value>
		<value name="Tight" tag="$tight_tag">
			<cmd name="line_metrics" args="1420 442 307 1825 443 1825 443 87"/>
		</value>
		<value name="Loose" tag="$loose_tag">
			<cmd name="line_gap" args="2800 1100"/>
		</value>
		<!-- Charis -->
		<value name="Normal" tag="$normal_tag">
			<cmd name="null" args="2450 900"/>
		</value>
		<value name="Tight" tag="$tight_tag">
			<cmd name="line_gap" args="1950 500"/>
		</value>
		<value name="Loose" tag="$loose_tag">
			<cmd name="line_gap" args="2900 1200"/>
		</value>
		<!-- Gentium -->
		<value name="Normal" tag="$normal_tag">
			<cmd name="null" args="2050 900"/>
		</value>
		<value name="Tight" tag="$tight_tag">
			<cmd name="line_gap" args="1750 550"/>
		</value>
		<value name="Loose" tag="$loose_tag">
			<cmd name="line_gap" args="2450 1200"/>
		</value>
		<!-- Andika -->
		<value name="Normal" tag="$normal_tag">
			<cmd name="null" args="2500 800"/>
		</value>
		<value name="Tight" tag="$tight_tag">
			<cmd name="line_gap" args="2100 550"/>
		</value>
		<value name="Loose" tag="$loose_tag">
			<cmd name="line_gap" args="2900 1100"/>
		</value>
		<value name="Imported" tag="$imported_tag">
			<cmd name="line_metrics_scaled" args="null"/>
		</value>
	</feature>
END
		}
		else
		{ #be careful of tabs in section below for proper output
			print $fh <<END
	<feature name="Line spacing" value="Normal" tag="$line_gap_tag">
		<!-- Doulos -->
		<value name="Normal" tag="$normal_tag">
			<cmd name="null" args="2324 810"/>
		</value>
		<value name="Tight" tag="$tight_tag">
			<cmd name="line_metrics" args="1420 442 307 1825 443 1825 443 87"/>
		</value>
		<value name="Loose" tag="$loose_tag">
			<cmd name="line_gap" args="2800 1100"/>
		</value>
		<value name="Imported" tag="$imported_tag">
			<cmd name="line_metrics_scaled" args="null"/>
		</value>
	</feature>
END
		}
	}
}

sub Test_output($$\%\%\%\%)
#output the <cmd> elements inside of a <test> element 
# for one set of feature interactions
{
	my ($feat_all_fh, $featset, $used_usvs, $featset_to_usvs, $usv_feat_to_ps_name, $dblenc_usv) = @_;
	my(@usvs, $usv, @feats, $feat);
	my $fh = $feat_all_fh;
	
	# this code is similar to Features_output
	@usvs = @{$featset_to_usvs->{$featset}};
	@feats = split(/\s/, $featset);
	foreach $usv (@usvs)
	{
		if (defined($used_usvs->{$usv})) {next;}
		
		#create string with all relevant ps_names separated by spaces
		my $choices = '';
		foreach $feat (@feats)
		{
			my @ps_names = @{$usv_feat_to_ps_name->{$usv}{$feat}};
			$choices .= join(' ', @ps_names) . ' ';
		}
		if (scalar @feats > 1)
		{   
			#offer variants without feature info in the GSI as choices
			if (defined($usv_feat_to_ps_name->{$usv}{'unk'}))
			{
				my @ps_names = @{$usv_feat_to_ps_name->{$usv}{'unk'}};
				$choices .= join(' ', @ps_names) . ' ';
			}
		}
		chop($choices);
		$choices = PSName_select(@feats, $choices);
		
		if ($opt_t) #output legal args for testing TypeTuner
			{my @c = split(/\s/, $choices); $choices = $c[0];}
			
		if (index($choices, ' ') != -1)
			{print $fh "\t\t\t<!-- edit below line(s) -->\n";}
			
		print $fh "\t\t\t<cmd name=\"encode\" args=\"$usv $choices\"/>\n";
		if (defined $dblenc_usv->{$usv})
			{print $fh "\t\t\t<cmd name=\"encode\" args=\"$dblenc_usv->{$usv} $choices\"/>\n";}
		$used_usvs->{$usv} = 1;
	}
}

sub sort_tests($$)
#compare to <interaction> test attribute strings
#sort such that strings with more featsets come first
{
	#scalar split(/\s/, $a) causes many error msgs
	my ($a, $b) = @_;
	my @t = split(/\s/, $a);
	my $a_ct = scalar @t;
	@t = split(/\s/, $b);
	my $b_ct = scalar @t;
	
	if ($a_ct > $b_ct)
		{return -1;}
	elsif ($a_ct < $b_ct)
		{return 1;}
	else #$a_ct == $b_ct
		{return ($a cmp $b);}
}

sub Tests_output($$\%\%\%\%)
#output all the the <cmd> elements inside of a <test> element
# handling all combinations of feature interactions
{
	my ($feat_all_fh, $featset, $used_usvs, $featset_to_usvs, $usv_feat_to_ps_name, $dblenc_usv) = @_;

	my @feats = split(/\s/, $featset);
	my @combos = Combos_get(@feats);
	foreach (@combos) {$_ = join(' ', @$_)};
	#sort these so glyph choices can be given for interacting features
	# before outputing encodings for a single feature
	my $test; 
	foreach $test (sort sort_tests @combos)
	{
		Test_output($feat_all_fh, $test, %$used_usvs, 
						%$featset_to_usvs, %$usv_feat_to_ps_name, %$dblenc_usv);
	}
}

sub Feats_to_ids($$\%)
#obtain feature & setting ids based on tags
{
	my  ($feat_tag, $set_tag, $feats) = @_;
	
	foreach my $fid (@{$feats->{' ids'}})
	{
		if ($feats->{$fid}{'tag'} eq $feat_tag)
		{
			foreach my $sid (@{$feats->{$fid}{'settings'}{' ids'}})
			{
				if ($feats->{$fid}{'settings'}{$sid}{'tag'} eq $set_tag)
				{
					return ($fid, $sid);
				}
			}	
		}
	}
	die("Ids for feature and setting couldn't be found: $feat_tag $set_tag\n");
}

sub Interactions_output($\%\%\%\%)
#output the <interactions> elements
{
	my ($feat_all_fh, $featset_to_usvs, $usv_feat_to_ps_name, $feats, $dblenc_usv) = @_;
	my $fh = $feat_all_fh;
	
	#start interactions element
	print $feat_all_fh "\t<interactions>\n";

	my $viet_featset = "None";
	if (defined $feats->{vietnamese_style_diacs_feat})
		{$viet_featset = "$feats->{'1029'}{'tag'}-$feats->{'1029'}{'settings'}{'1'}{'tag'}"};
	my $rmnian_featset = "None";
	if (defined $feats->{romanian_style_diacs_feat})
		{$rmnian_featset = "$feats->{'1041'}{'tag'}-$feats->{'1041'}{'settings'}{'1'}{'tag'}"};
	my $featset;
	foreach $featset (sort sort_tests keys %$featset_to_usvs)
	{
		my @featsets = split(/\s/, $featset);
		if (scalar @featsets == 1) {next;} #handled with <feature> elements
		
		#start test element
		print $fh "\t\t<test select=\"$featset\">\n";
		
		#null cmd if nothing to output
		if ($opt_g and $opt_q)
			{print $fh "\t\t\t<cmd name=\"null\" args=\"null\"/>\n";}
			
		unless ($opt_q)
		{
			foreach my $feat (@featsets)
			{#gr_feat cmds
				my ($feat_tag, $set_tag) = ($feat =~ /(.*)-(.*)/);
				my ($feat_id, $set_id) = Feats_to_ids($feat_tag, $set_tag, %$feats);
				print $fh "\t\t\t<cmd name=\"gr_feat\" args=\"$feat_id $set_id\"/>\n";
			}
		}
		
		#I think that VIt and ROt should be handled the same way
		#Using feat_del & feat_add for both VIt and ROt has problems 
		# if both VIt and ROt are on since the second one processed can't delete ccmp_latin
		# because the first one will have already deleted it
		#Using a test select="VIt ROt" to solve this problem would create two features with 
		# the same OT name (ccmp) and redundant lookups
		#Using the lookup_add approach doesn't require testing for both VIt and ROt
		# and avoids the above problem
		
		if ($featset =~ /$viet_featset/ and not $opt_g)
		{#hard-coded
			print $fh "\t\t\t<cmd name=\"lookup_add\" args=\"GSUB {ccmp_latin} {viet_decomp}\"/>\n";
			print $fh "\t\t\t<cmd name=\"lookup_add\" args=\"GSUB {ccmp_latin} {viet_precomp}\"/>\n";
			
			#see above comment
			#print $fh "\t\t\t<cmd name=\"feat_del\" args=\"GSUB latn {IPA} {ccmp_latin}\"/>\n";
			#print $fh "\t\t\t<cmd name=\"feat_add\" args=\"GSUB latn {IPA} {ccmp_vietnamese} 0\"/>\n";
		}
		if ($featset =~ /$rmnian_featset/ and not $opt_g)
		{#hard-coded
			print $fh "\t\t\t<cmd name=\"lookup_add\" args=\"GSUB {ccmp_latin} {rom_decomp}\"/>\n";
			print $fh "\t\t\t<cmd name=\"lookup_add\" args=\"GSUB {ccmp_latin} {rom_precomp}\"/>\n";
		}
		
		#encode cmds for all affected usvs
		my %used_usvs;
		Tests_output($feat_all_fh, $featset, %used_usvs, 
					%$featset_to_usvs, %$usv_feat_to_ps_name, %$dblenc_usv) unless $opt_g;
		
		#end test element
		print $fh "\t\t</test>\n";
	}

	#end interactions element
	print $feat_all_fh "\t</interactions>\n";
}

sub Aliases_output($)
#output the <aliases> elements
{
	my ($feat_all_fh) = @_;

	#<alias name="IPA" value="IPA "/> move up from below so not output to file
	print $feat_all_fh <<END;
	<aliases>
		<alias name="IPA" value="IPPH"/>
		<alias name="VIT" value="VIT "/>
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
(c) SIL International 2007. All rights reserved.
usage: 
	RFComposer <switches> <font.ttf> <gsi.xml> <dblenc.txt> [<gsi_supp_fn.xml>]
	switches:
		-g - output no OpenType cmds (Graphite only)
		-q - output no Graphite cmds (OpenType only)
		-d - debug output
		-t - output a file that needs no editing 
			(for testing TypeTuner)
			
	output is to feat_all_composer.xml
END
	exit();
};

#### main processing ####

sub cmd_line_exec() #for UltraEdit function list
{}

my (%feats, %usv_feat_to_ps_name, %featset_to_usvs, %dblenc_usv, $feat_all_fh);
my ($font_fn, $gsi_fn, $dblenc_fn, $gsi_supp_fn, $feat_all_fn);

getopts($opt_str); #sets $opt?'s & removes the switch from @ARGV

#build a file containing a hash of feature & setting names to tags
# to paste into this program for specifying tags
if ($opt_l)
{
	my ($font_fn) = ($ARGV[0]);

	Feats_get($font_fn, %feats);
	
	open FILE, ">$featset_list_fn";
	print FILE 'my %nm_to_tag = (';
	print FILE "\n";
	
	my %tags;
	foreach my $feat_id (@{$feats{' ids'}})
	{
		my $feat_t = $feats{$feat_id};
		my ($tag, $name, $default) = ($feat_t->{'tag'}, $feat_t->{'name'}, 
									  $feat_t->{'default'});
		if (not defined $tags{$name})
			{print FILE "\t'$name' => '$tag',\n"; $tags{$name} = $tag;}
		foreach my $set_id (@{$feats{$feat_id}{'settings'}{' ids'}})
		{
			my $set_t = $feat_t->{'settings'}{$set_id};
			($tag, $name) = ($set_t->{'tag'}, $set_t->{'name'});
			if (not defined $tags{$name})
				{print FILE "\t'$name' => '$tag',\n"; $tags{$name} = $tag;}
		}
	}
	
	#my $line_gap_tag = Tag_get('Line spacing', 2);
	#print FILE "\t'Line spacing' => '$line_gap_tag',\n";
	
	foreach my $s ('Line spacing', 'Tight', 'Normal', 'Loose', 'Imported')
	{
		if (not defined $tags{$s})
		{
			my $tag = Tag_lookup($s, %nm_to_tag);
			print FILE "\t'$s' => '$tag',\n";
			$tags{$s} = $tag;
		}
	}
	
	print FILE ");\n";
	exit;	
}

if (scalar @ARGV == 3)
	{($font_fn, $gsi_fn, $dblenc_fn) = ($ARGV[0], $ARGV[1], $ARGV[2]); $gsi_supp_fn = undef;}
elsif (scalar @ARGV == 4)
	{($font_fn, $gsi_fn, $dblenc_fn, $gsi_supp_fn) = ($ARGV[0], $ARGV[1], $ARGV[2], $ARGV[3]);}
else
	{Usage_print;}

Feats_get($font_fn, %feats);
Gsi_xml_parse($gsi_fn, %feats, %usv_feat_to_ps_name, %featset_to_usvs);
Special_glyphs_handle($gsi_supp_fn, %feats, %usv_feat_to_ps_name, %featset_to_usvs);
Dblenc_get($dblenc_fn, %dblenc_usv);

$feat_all_fn = $feat_all_base_fn;
open $feat_all_fh, ">$feat_all_fn" or die("Could not open $feat_all_fn for writing\n");
print $feat_all_fh "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
print $feat_all_fh "<!DOCTYPE all_features SYSTEM \"feat_all.dtd\">\n";
print $feat_all_fh "<all_features version=\"1.0\">\n";

Features_output($feat_all_fh, %feats, %featset_to_usvs, %usv_feat_to_ps_name, %dblenc_usv);
Interactions_output($feat_all_fh, %featset_to_usvs, %usv_feat_to_ps_name, %feats, %dblenc_usv);
unless ($opt_g)
{
	Aliases_output($feat_all_fh);
}

print $feat_all_fh "</all_features>\n";

exit;
