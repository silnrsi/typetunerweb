# Copyright (c) SIL International, 2007. All rights reserved.

#todo: consider affects of OS/2.update?
#todo: don't die on every error, try to keep going

use strict;
use warnings;

use Font::TTF::Font;
use XML::Parser::Expat;
use Getopt::Std;
use File::Temp qw(tempfile);
use Compress::Zlib;

#### global variables & constants ####

#$opt_d - debug output
#$opt_f - for add & extract subcommands, don't check whether proper element at start of file
#$opt_t - output feat_set.xml file with all settings at non-default values for testing TypeTuner
#$opt_n - string to use a suffix at end of font name instead of featset string
#$opt_o - name for output font file instead of generating by appending _tt
our($opt_d, $opt_f, $opt_t, $opt_n, $opt_o); #set by &getopts:
my $opt_str ='dftn:o:';

my $family_name_id = 1; #source for family name to modify
my $version_name_id = 5;
my $family_name_ids = [1, 3, 4, 6, 16, 18, 20]; #name ids where family might occur
my $version_name_ids = [3, 5];
my $feat_all_elem = "all_features";
my $feat_set_elem = "features_set";
my $table_nm = "Silt";

#### subroutines ####

sub Feat_All_parse($\%\%)
#parse $feat_all_fn to create the $feat_all and $feat_tag structures
#see "TypeTuner_notes.txt" for description of data structures and XML format
{
	my ($feat_all_fn, $feat_all, $feat_tag) = @_;
	my ($xml_parser, $tag, $tmp, $current, $last);
	
	$xml_parser = XML::Parser::Expat->new();
	
	$xml_parser->setHandlers('Start' => sub {
		my ($xml_parser, $elem, %attrs) = @_;
		if ($elem eq $feat_all_elem)
		{
			$feat_all->{'version'} = $attrs{'version'};
		}
		elsif ($elem eq $feat_set_elem)
		{
			die("$feat_set_elem XML file provided instead of $feat_all_elem XML file\n");
		}
		elsif ($elem eq 'features')
		{}
		elsif ($elem eq 'feature')
		{
			$tag = $attrs{'tag'};
			if (defined $feat_all->{'features'}{$tag} || length($tag) != 2 || $tag !~ /[A-Z]+/)
				{die("feature tags must be unique and consist of two uppercase letters: $tag\n");}
			
			$feat_all->{'features'}{$tag}{'name'} = $attrs{'name'};
			$feat_all->{'features'}{$tag}{'default'} = $attrs{'value'};
			
			if (not defined $feat_all->{'features'}{' tags'})
				{$feat_all->{'features'}{' tags'} = [];}
			push(@{$feat_all->{'features'}{' tags'}}, $tag);
			
			$feat_tag->{$attrs{'name'}} = $tag;

			$current = $feat_all->{'features'}{$tag}; #'values' to be added
		}
		elsif ($elem eq 'value')
		{
			$tag = $attrs{'tag'};
			if (defined $current->{'values'}{$tag} || length($tag) != 1 || $tag !~ /[a-z]+/)
				{die("for feature $current->{'name'}, value tags must be unique and consist of one lowercase letters: $tag\n");}
			
			$current->{'values'}{$tag}{'name'} = $attrs{'name'};
			
			if (not defined $current->{'values'}{' tags'})
				{$current->{'values'}{' tags'} = [];}
			push(@{$current->{'values'}{' tags'}}, $tag);

			if (defined $feat_tag->{$attrs{'name'}} 
					&& $feat_tag->{$attrs{'name'}} ne $tag)
				{die("value name: $attrs{'name'} mapped to a second different tag: $tag\n");}
			$feat_tag->{$attrs{'name'}} = $tag;

			$last = $current;
			$current = $current->{'values'}{$tag}; #'cmds' to be added
		}
		elsif ($elem eq 'interactions')
		{}
		elsif ($elem eq 'test')
		{
			$tmp = {'test' => $attrs{'select'}};
			if (not defined $feat_all->{'interactions'})
				{$feat_all->{'interactions'} = [];}
			push(@{$feat_all->{'interactions'}}, $tmp);
			$current = $feat_all->{'interactions'}[-1]; #'cmds' to be added
		}
		elsif ($elem eq 'cmd_blocks')
		{}
		elsif ($elem eq 'cmd_block')
		{
			$tmp = $attrs{'name'};
			$feat_all->{'cmd_blocks'}{$tmp} = {}; #'cmds' to be added
			$current = $feat_all->{'cmd_blocks'}{$tmp};
		}
		elsif ($elem eq 'cmd') #features, interactions, cmd_blocks
		{
			# $current is pointer to a hash
			$tmp = {'cmd' => $attrs{'name'}, 'args' => $attrs{'args'}};
			if (not defined $current->{'cmds'})
				{$current->{'cmds'} = [];} #array of refs to {cmd, args} or {cmd_block}
			push(@{$current->{'cmds'}}, $tmp);
		}
		elsif ($elem eq 'cmds') #features, interactions
		{
			# $current is pointer to a hash
			$tmp = {'cmd_block' => $attrs{'name'}};
			if (not defined $current->{'cmds'})
				{$current->{'cmds'} = [];} #array of refs to {cmd, args} or {cmd_block}
			push(@{$current->{'cmds'}}, $tmp);
		}
		elsif ($elem eq 'aliases')
		{}
		elsif ($elem eq 'alias')
		{
			$tmp = $attrs{'name'};
			$feat_all->{'aliases'}{$tmp} = $attrs{'value'};
		}
		else
		{}
	}, 'End' => sub {
		my ($xml_parser, $elem) = @_;
		if ($elem eq 'value')
		{
			$current = $last;
		}
		else
		{}
	}, 'Char' => sub {
		my ($xml_parser, $str) = @_;
		#die ("XML element content not allowed: $str\n");
	});

	$xml_parser->parsefile($feat_all_fn) or die "Can't read $feat_all_fn";
}

sub Feat_Set_write($\%)
#write the $feat_set_fn based on the $feat_all structure
{
	my ($feat_set_fn, $feat_all) = @_;
	my ($feats, $feat_tag, $feat_nm, $feat_val, $val_tag, $val_nm);
	
	open OUT_FILE, ">$feat_set_fn" or die("Could not open $feat_set_fn for writing\n");
	print OUT_FILE "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
	print OUT_FILE "<!DOCTYPE features_set SYSTEM \"feat_set.dtd\">\n";
	print OUT_FILE "<features_set version=\"$feat_all->{'version'}\">\n";
	
	$feats = $feat_all->{'features'};
	foreach $feat_tag (@{$feats->{' tags'}})
	{
		$feat_nm = $feats->{$feat_tag}{'name'};
		
		if (not $opt_t)
			{$feat_val = $feats->{$feat_tag}{'default'};}
		else #get non-default setting for binary or multi-valued feat
		{	foreach (@{$feats->{$feat_tag}{'values'}{' tags'}})
			{
				$feat_val = $feats->{$feat_tag}{'values'}{$_}{'name'};
				if ($feat_val ne $feats->{$feat_tag}{'default'}) 
					{last;}
			}
		}
		print OUT_FILE "\t<feature name=\"$feat_nm\" value=\"$feat_val\">\n";
		
		foreach $val_tag (@{$feats->{$feat_tag}{'values'}{' tags'}})
		{
			$val_nm = $feats->{$feat_tag}{'values'}{$val_tag}{'name'};
			print OUT_FILE "\t\t<value name=\"$val_nm\"/>\n";
		}
		print OUT_FILE "\t</feature>\n";
	}
	
	print OUT_FILE "</features_set>\n";
}

sub Feat_Set_parse($\%\$)
#parse the $feat_set_fn to create the $feat_set string
{
	my ($feat_set_fn, $feat_tag, $feat_set) = @_;
	
	my ($xml_parser, $tmp, $feature_tag, $value_tag, $feat_set_str);
	$feat_set_str = '';

	$xml_parser = XML::Parser::Expat->new();
	$xml_parser->setHandlers('Start' => sub {
		my ($xml_parser, $elem, %attrs) = @_;
		if ($elem eq 'feature')
		{   
			$tmp = $attrs{'name'};
			$feature_tag = $feat_tag->{$tmp} or die("feature name: $tmp is invalid\n");
			$tmp = $attrs{'value'};
			$value_tag = $feat_tag->{$tmp} or die("feature value: $tmp is invalid\n");
			$feat_set_str .= $feature_tag . $value_tag . ' ';
		}
		elsif ($elem eq $feat_all_elem)
		{
			die("$feat_all_elem XML file provided instead of $feat_set_elem XML file\n");
		}
		else
		{}
	}, 'End' => sub {
		my ($xml_parser, $elem) = @_;
		if ($elem eq '')
		{}
		else
		{}
	}, 'Char' => sub {
		my ($xml_parser, $str) = @_;
		#die ("XML element content not allowed: $str\n");
	});

	$xml_parser->parsefile($feat_set_fn) or die "Can't read $feat_set_fn";
	chop $feat_set_str; #remove final space
	$$feat_set = $feat_set_str;
}

#forward declaration so recursive call won't be flagged as an error
sub copy_cmds(\@\@\%);

sub copy_cmds(\@\@\%)
#copy second array to first array flattening cmd_blocks
#can be called recursively so cmd_blocks can contain cmd_blocks
{
	my ($commands, $cmds, $cmd_blocks) = @_;
	my ($cmd);
	foreach $cmd (@{$cmds}){
		if (defined $cmd->{'cmd_block'}) #flatten cmd_blocks
			{copy_cmds(@$commands, 
						@{$cmd_blocks->{$cmd->{'cmd_block'}}{'cmds'}}, 
						%$cmd_blocks);}
		else
			{push(@{$commands}, $cmd);}}
};

sub sort_tests($$)
#compare to <interaction> test attribute strings
#sort such that longer strings come first
{
	my ($a, $b) = @_;
	my ($a_len, $b_len) = (length($a), length($b));
	
	if ($a_len > $b_len)
		{return -1;}
	elsif ($a_len < $b_len)
		{return 1;}
	else #$a_len == $b_len
		{return ($a cmp $b);}
}

sub Feat_val_tags($)
#extract feature and value tags from a concatenated string containing them together
#returns the tags as a list
#referencing $1 after the regex crashes in the Perl debugger
#If this would work, I think the limits on feature & value tag length 
# would be eliminated
{
	my ($fv) = @_;
	
	#print "Feat_val_tags fv: '$fv'\n";
	if ($fv =~ /([A-Z]+)([a-z]+)/) #assumes feature is uc and setting is lc
		{return ($1, $2);}
	else
		{die("feature-value pair is corrupt: $fv\n");}
}

sub Feat_Set_cmds(\%$\@)
#generate a list of commands (cmd-args hashes) to process based on feature settings
#any cmd_block will be expanded to a list of commands
#first process interactions tests then feature value cmds
{
	my ($feat_all, $feat_set, $commands) = @_;
	
	my ($features, $interactions, $cmd_blocks);
	$features = $feat_all->{'features'};
	$interactions = $feat_all->{'interactions'};
	$cmd_blocks = $feat_all->{'cmd_blocks'};
	
	#create hash for working with sorted test attributes
	my ($interact, %test_str_to_ix, $ix);
	$ix = 0;
	foreach $interact (@{$interactions})
		{$test_str_to_ix{$interact->{'test'}} = $ix++;}

	#test feature settings against interaction tests
	#each successful test removes the feature setttings 
	# from consideration by tests with fewer conditions
	# but not from consideration by tests with the same number of conditions
	# this assumes tests with the same number of conditions affect mutually exclusive USVs
	# (if the USVs aren't mutually exclusive,
	#  a test with a higher number of conditions should exist)
	my ($test_str, @tests, $test, $test_passed);
	my ($feat_set_next, $feat_set_ct);
	$feat_set_next = $feat_set; #initialize here in case no interactions section
	foreach $test_str (sort sort_tests keys %test_str_to_ix)
	{
		@tests = split(/\s+/, $test_str);
		
		if (not defined($feat_set_ct))
		{#first test with highest number of conditions
			$feat_set_ct = scalar @tests;
		}
		if ($feat_set_ct > scalar @tests)
		{#change in number of test conditions
			$feat_set = $feat_set_next;
			$feat_set_ct = scalar @tests;
		}
		$test_passed = 1;
		foreach $test (@tests)
		{ #test if all feat-value settings in an interaction test are set
			if (not $feat_set =~ /$test/)
			{
				$test_passed = 0;
				last;
			}
		}
		if ($test_passed)
		{ #add to list of commands to process
			if ($opt_d) {print "test passed: $test_str\n";}
			my $cmds = $interactions->[$test_str_to_ix{$test_str}]->{'cmds'};
			copy_cmds(@$commands, @$cmds, %$cmd_blocks);

			foreach $test (@tests)
			{ #remove feature-value pairs that have been processed
				$feat_set_next =~ s/$test//;
			}
		}
		else
		{
			if ($opt_d) {print "test failed: $test_str\n";}
		}
	}
	
	#process remaining feat-value setting based on feature value cmds
	my (@feat_val, $feat, $val, $cmds);
	@feat_val = split(/\s+/, $feat_set_next); 
	if ($opt_d) {print "feat-sets applied: ";}
	foreach my $fv (@feat_val)
	{
		next if (not $fv);
		if ($opt_d) {print "$fv ";}
		$feat = substr($fv, 0, 2);
		$val = substr($fv, -1, 1);
		#($feat, $val) = Feat_val_tags($fv);
		$cmds = $features->{$feat}{'values'}{$val}{'cmds'};
		copy_cmds(@$commands, @$cmds, %$cmd_blocks);
	}
	if ($opt_d) {print "\n\n";}
};

sub Cmds_exec ($\@\%)
#execute commands (cmd-args hash) in commands array against the font
#the args string is split into one string for each arg
# Perl handles the conversion from string to number automatically 
# where numbers are needed as args in called sub
#args can be surrounded by braces, which means they are looked up in aliases
#args that contain spaces MUST be handled using an alias
{
	my ($font, $commands, $feat_all) = @_;
	my ($command, $cmd, $args, @args, $arg);
	
	foreach $command (@$commands)
	{
		($cmd, $args) = ($command->{'cmd'}, $command->{'args'});
		@args = split(/\s+/, $args);
		
		foreach $arg (@args)
		{ #handle args in braces
			if ($arg =~ /\{(.*)\}/)
			{
				$arg = $feat_all->{'aliases'}{$1}; #$arg is a ref so this changes @args
				if (not defined $arg)
					{die('invalid alias: $1\n');}
			}
		}
		
		if ($cmd eq 'null')
		{}
		elsif ($cmd eq 'gr_feat')
		{
			if (scalar @args != 2)
				{die ("invalid args for gr_feat cmd: @args\n");}
			Gr_feat($font, $args[0], $args[1]);
		}
		elsif ($cmd eq 'encode')
		{
			if (scalar @args != 2)
				{die ("invalid args for encode cmd: @args\n");}
			Encode($font, $args[0], $args[1]);
		}
		elsif ($cmd eq 'feat_add')
		{
			if (scalar @args != 5)
				{die ("invalid args for feat_add cmd: @args\n");}
			Feat_add($font, $args[0], $args[1], $args[2], $args[3], $args[4]);
		}
		elsif ($cmd eq 'feat_del')
		{
			if (scalar @args != 4)
				{die ("invalid args for feat_del cmd: @args\n");}
			Feat_del($font, $args[0], $args[1], $args[2], $args[3]);
		}
		elsif ($cmd eq 'lookup_add')
		{
			if (scalar @args != 3)
				{die ("invalid args for lookup_add cmd: @args\n");}
			Lookup_add($font, $args[0], $args[1], $args[2]);
		}
		elsif ($cmd eq 'lookup_del')
		{
			if (scalar @args != 3)
				{die ("invalid args for lookup_del cmd: @args\n");}
			Lookup_del($font, $args[0], $args[1], $args[2]);
		}
		elsif ($cmd eq 'line_gap')
		{
			if (scalar @args != 2)
				{die ("invalid args for line_gap cmd: @args\n");}
			Line_gap_mod($font, $args[0], $args[1]);
		}
		else
		{
			print "WARNING - unrecognized cmd: $cmd\n";
		}
	}
};

sub Font_ids_update($\%$)
#update various identifying information in the font based on feature settings
{
	my ($font, $feat_all, $feat_set, $time_cur) = @_;
	
	#eliminate default feature value settings
	my ($feats, @feat_val, $feat, $val, $feat_set_active);
	$feats = $feat_all->{'features'};
	$feat_set_active = '';
	
	@feat_val = split(/\s+/, $feat_set);
	foreach my $fv (@feat_val)
	{
		next if (not $fv);
		$feat = substr($fv, 0, 2);
		$val = substr($fv, -1, 1);
		#($feat, $val) = Feat_val_tags($fv);
		if ($feats->{$feat}{'default'} ne $feats->{$feat}{'values'}{$val}{'name'})
		{
			#$feat_set_active .= " " if $feat_set_active;
			$feat_set_active .= $fv;
		}
	}
	if ($opt_d) {print "Font_ids_update: feat_set_active = $feat_set_active\n";}
    
    #modify font name
	my ($family_nm_old, $family_nm_new, $version_str_old, $version_str_new);	
	$family_nm_old = Name_get($font, $family_name_id);
	if (length($feat_set_active) <= 6 || $opt_n)
	{
		$family_nm_new = $family_nm_old . ' ' . ($opt_n ? $opt_n : $feat_set_active);
		Name_mod($font, $family_name_ids, $family_nm_old, $family_nm_new);
	}
	else
	{
		$family_nm_new = $family_nm_old . ' ' . substr($feat_set_active, 0, 6) . 'XT';
		Name_mod($font, $family_name_ids, $family_nm_old, $family_nm_new);
	}
	
	#modify version
	$version_str_old = Name_get($font, $version_name_id);
	$version_str_new = $version_str_old . ' ; '. $feat_set_active;
	Name_mod($font, $version_name_ids, $version_str_old, $version_str_new);
	
	#modify modification date
	$font->{'head'}->read;
	if ($opt_d) {printf ("old date: %d  ", $font->{'head'}->getdate());}
	$time_cur = time();
	$font->{'head'}->setdate($time_cur);
	if ($opt_d) {printf ("new date: %d\n", $time_cur);}
}

sub Gr_feat($$$)
{
	my ($font, $gr_feat_id, $gr_set_id) = @_;
	my ($grfeat_tbl, $feature, $feat_found, $set_found);
	
	$grfeat_tbl = $font->{'Feat'}->read;
	#$grfeat_tbl->print;
	
	($feat_found, $set_found) = (0, 0);
	foreach $feature (@{$grfeat_tbl->{'features'}})
	{
		if ($feature->{'feature'} == $gr_feat_id)
		{
			$feat_found = 1;
			if (defined($feature->{'settings'}{$gr_set_id}))
			{
				if ($opt_d) {print "Gr_feat: feat_id: $gr_feat_id old_default: $feature->{'default'} new_default: $gr_set_id\n";}
				$set_found = 1;
				$feature->{'default'} = $gr_set_id;
			}
			last;
		}
	}

	if (not $feat_found)
		{die("feature id not found in TTF: feat_id: $gr_feat_id set_id: $gr_set_id\n");}
	if (not $set_found)
		{die("set id not availabe for feature in TTF: feat_id: $gr_feat_id set_id: $gr_set_id\n");}
}

sub Encode($$$)
#modify the cmap subtables to encode the glyph indicated by ps_nm at usv_str
{
	my ($font, $usv_str, $ps_nm) = @_;
	my ($post_tbl, $glyph_id);

	#lookup $ps_nm in the post table to get $glyph_id
	$post_tbl = $font->{'post'}->read;
	$glyph_id = $post_tbl->{'STRINGS'}{$ps_nm};
	if (not defined $glyph_id)
		{die("PostScript name $ps_nm is not defined in the font.")};
	
	#convert USV string (U+0105) to a number (0x0105)
	my ($usv);
	$usv = hex($usv_str);
		
	#loop thru cmap subtables
	my ($cmap_tbl, $cmap_ct, $i, $cmap_subtbl);
	$cmap_tbl = $font->{'cmap'}->read;
	$cmap_ct = $cmap_tbl->{'Num'};
	if ($opt_d) {printf("Encode: ps_nm: %s glyph_id: %d usv: 0x%04x cmap_ct: %d\n", $ps_nm, $glyph_id, $usv, $cmap_ct);}
	for ($i = 0; $i < $cmap_ct; ++$i)
	{
		#lookup $usv and point to $glyph_id 
		#print "Encode: remapping cmap $i\n";
		$cmap_subtbl = $cmap_tbl->{'Tables'}[$i];
		#allow creation of new USVs but protect subtables that can't handle large ones
		$cmap_subtbl->{'val'}{$usv} = $glyph_id unless $usv > 0xFFFF && $cmap_subtbl->{'Format'} < 8;
	}
	
	#handle $usv_str greater than current max char in OS/2
	my ($os2_tbl, $max_char);
	$os2_tbl = $font->{'OS/2'}->read;
	$max_char = $os2_tbl->{'usLastCharIndex'};
	if ($usv > $max_char)
	{
		$os2_tbl->{'usLastCharIndex'} = $usv;
		if ($opt_d) {print "Encode: OS/2 table max char adjusted to $usv\n";}
	}
	
	#todo: may need to handle Unicode range bits
}

sub Feat_add($$$$$$)
#adds the named feature to the list of features for the given script and lang
#at the given pos
#though order of features should not matter. (order in lookup table does matter.)
{
	my ($font, $tbl_type, $script, $lang, $feat, $pos) = @_;
	
	my ($feats);
	$feats = Feats_find($font, $tbl_type, $script, $lang); 
	if ($opt_d) {print "Feat_add $feat: orig feats = @$feats\n";}
	foreach ($feats)
		{if ($_ eq $feat)
			{die("Feat_add: feature already exists: tbl_type = $tbl_type script = $script lang = $lang feat = $feat\n");}}
	#push(@$feats, $feat); #add element to array
	splice(@$feats, $pos, 0, $feat);
	if ($opt_d) {print "Feat_add $feat: chng feats = @$feats\n";}
}

sub Feat_del($$$$$)
#deletes the named feature from the list of features for the given script and lang
{
	my ($font, $tbl_type, $script, $lang, $feat) = @_;
	
	my ($feats, $ct, $ix, $found);
	$feats = Feats_find($font, $tbl_type, $script, $lang);
	if ($opt_d) {print "Feat_del $feat: orig feats = @$feats\n";}
	$ct = scalar @$feats;
	$found = 0;
	for ($ix = 0; $ix < $ct; ++$ix)
	{
		if (@$feats[$ix] eq $feat)
		{
			splice(@$feats, $ix, 1); #remove element from array
			$found = 1;
			last;
		}
	}
	if (not $found)
		{die("Feat_del: feature not found: tbl_type = $tbl_type script = $script lang = $lang feat = $feat\n");}
	if ($opt_d) {print "Feat_del $feat: chng feats = @$feats\n";}
}

sub Feats_find($$$$)
#returns reference to array of feature names for a given script and lang
{
	my ($font, $tbl_type, $script, $lang) = @_;
	if ($tbl_type ne 'GSUB' and $tbl_type ne 'GPOS')
		{die("invalid table type: $tbl_type\n")};

	my($tbl, $feats, $reftag);
	$tbl = $font->{$tbl_type}->read;
	$reftag = $tbl->{'SCRIPTS'}{$script}{$lang}{' REFTAG'};
	if (not defined $reftag)
		{$feats = $tbl->{'SCRIPTS'}{$script}{$lang}{'FEATURES'};}
	else
		{$feats = $tbl->{'SCRIPTS'}{$script}{$reftag}{'FEATURES'};}
	if (not defined $feats)
		{die("Feats_find: could not find features: table = $tbl_type script = $script lang = $lang\n")};
	
	return $feats;
}

sub Lookup_add($$$$)
#adds the lookup index to the list of lookups for a given feature
#assumes the lookup indexes are sorted numerically
{
	my ($font, $tbl_type, $feat, $lookup) = @_;
	
	my ($lookups, $ct, $ix);
	$lookups = Lookups_find($font, $tbl_type, $feat);
	if ($opt_d) {print "Lookup_add $lookup: orig lookups = @$lookups\n";}
	$ct = scalar @$lookups;
	for ($ix = 0; $ix < $ct; $ix++)
	{
		if (@$lookups[$ix] < $lookup)
		{
			next;
		}
		elsif (@$lookups[$ix] == $lookup)
		{
			die("Lookup_add: lookup already exists: tbl_type = $tbl_type feat = $feat lookup = $lookup\n");
			next;
		}
		else
		{
			splice(@$lookups, $ix, 0, $lookup); #add element to array
			last;
		}
	}
	if ($ix == $ct) #$lookup is greater than all in @$lookups
	{
		push (@$lookups, $lookup)
	}
	if ($opt_d) {print "Lookup_add $lookup: chng lookups = @$lookups\n";}
}

sub Lookup_del($$$$)
#deletes the lookup index from the list of lookups for the given feature
{
	my ($font, $tbl_type, $feat, $lookup) = @_;
	
	my ($lookups, $ct, $ix, $found);
	$lookups = Lookups_find($font, $tbl_type, $feat);
	if ($opt_d) {print "Lookup_del $lookup: orig lookups = @$lookups\n";}
	$ct = scalar @$lookups;
	$found = 0;
	for ($ix = 0; $ix < $ct; $ix++)
	{
		if (@$lookups[$ix] == $lookup)
		{
			splice (@$lookups, $ix, 1); #remove element from array
			$found = 1;
			last;
		}
	}
	if (not $found)
		{die("Lookup_del: lookup not found: tbl_type = $tbl_type feat = $feat lookup = $lookup\n");}
	if ($opt_d) {print "Lookup_del $lookup: chng lookups = @$lookups\n";}
}

sub Lookups_find($$$)
#returns reference to array of lookup indexes for the given feature
{
	my ($font, $tbl_type, $feat) = @_;	
	if ($tbl_type ne 'GSUB' and $tbl_type ne 'GPOS')
		{die("invalid table type: $tbl_type\n")};
		
	my($tbl, $lookups);
	$tbl = $font->{$tbl_type}->read;
	$lookups = $tbl->{'FEATURES'}{$feat}{'LOOKUPS'};
	if (not defined $lookups)
		{die("could not find lookups: table = $tbl_type feature = $feat")};

	return $lookups;	
}

sub Line_gap_get($)
#returns the ascent and descent from the OS/2 table
#desc will be positive
{
	my ($font) = @_;
	
	my ($tbl, $asc, $dsc);
	$tbl = $font->{'OS/2'}->read;
	$asc = $tbl->{'usWinAscent'};
	$dsc = $tbl->{'usWinDescent'};
	
	return ($asc, $dsc);
}

sub Line_gap_mod($$$)
#set the various ascent and descent values in OS/2 and hhea tables
#descent should normally be positive
{
	my ($font, $asc, $dsc) = @_;

	my ($tbl);
	$tbl = $font->{'OS/2'}->read;
	if ($opt_d) {print "Line_gap_mod: orig asc = $tbl->{'usWinAscent'} dsc = $tbl->{'usWinAscent'}\n";}
	$tbl->{'sTypoAscender'} = $asc;
	$tbl->{'sTypoDescender'} = $dsc * -1;
	$tbl->{'usWinAscent'} = $asc;
	$tbl->{'usWinDescent'} = $dsc;
	if ($opt_d) {print "Line_gap_mod: chng asc = $tbl->{'usWinAscent'} dsc = $tbl->{'usWinAscent'}\n";}

	$tbl = $font->{'hhea'}->read;
	$tbl->{'Ascender'} = $asc;
	$tbl->{'Descender'} = $dsc * -1;
}

sub Name_get($$)
#returns the name for a given name id
{	
	my ($font, $name_id) = @_;
	
	my ($name_tbl, $name);
	$name_tbl = $font->{'name'}->read;
	$name = $name_tbl->find_name($name_id);
	if (not $name)
		{die("could not find name in font for id: $name_id\n")};
	
	return $name;
}

sub Name_mod($\@$$)
#modifies the name for a given name ids
{
	my ($font, $name_ids, $old_name, $new_name) = @_;
	my ($name_tbl, $nid, $pid, $eid, $lid, $name);
	
	$name_tbl = $font->{'name'}->read;
#    foreach $nid (0 .. $#{$name_tbl->{'strings'}})
	foreach $nid (@$name_ids)
	{
		foreach $pid (0 .. $#{$name_tbl->{'strings'}[$nid]})
		{
			foreach $eid (0 .. $#{$name_tbl->{'strings'}[$nid][$pid]})
			{
				foreach $lid (keys %{$name_tbl->{'strings'}[$nid][$pid][$eid]})
				{
					$name = $name_tbl->{'strings'}[$nid][$pid][$eid]{$lid};
					if ($name =~ s/$old_name/$new_name/)
					{
						$name_tbl->{'strings'}[$nid][$pid][$eid]{$lid} = $name;
						if ($opt_d) {print "Name_mod: name = $name nid = $nid pid = $pid eid = $eid lid = $lid\n";}
					}
				}
			}
		}
	}
}

sub Table_extract($$$)
#extract our table from the $font to the specified file name
#$feat_set_test insures that $feat_set_elem is at the start of the data to be extracted
{
	my ($font, $fn, $feat_set_test) = @_;
	
	open FEAT, ">$fn";
	binmode(FEAT);
	if (not defined $font->{$table_nm})
		{die("no $table_nm table in font\n");}
	else
	{
		$font->{$table_nm}->read;
    	my $tmp = Compress::Zlib::memGunzip($font->{$table_nm}{' dat'});
		if ($feat_set_test)
			{if (not $tmp =~ /$feat_set_elem/)
				{die("table $table_nm does not contain $feat_set_elem\n");}}
    	print FEAT $tmp;
		close FEAT;
	}
}

sub Table_add($$$)
#add our table to the $font from the specified file
#$feat_all_test insures that $feat_all_elem is at the start of the file
{
	my ($font, $fn, $feat_all_test) = @_;
	
	#read the whole feat_all XML file into memory
	my($feat_xml, $tmp);
	open FEAT, "<$fn" or die "Can't open XML file\n";
	binmode(FEAT);
	$tmp = read(FEAT, $feat_xml, 1000000) or die "Can't read XML file\n";
	if ($tmp == 1000000)
		{die("XML file is too big\n");}
	
	#die if $feat_all_fn does not start with <all_features>, override test with -f switch
	if ($feat_all_test)
		{if (not $feat_xml =~ /$feat_all_elem/)
			{die("XML file does not contain $feat_all_elem\n");}}
	
	#compress the XML before putting in the font table
    $tmp = Compress::Zlib::memGzip($feat_xml);
    
	#add our XML table $table_nm to the ttf
	#the instance variables were taken from where Font.pm creates its Tables
	$font->{$table_nm} = Font::TTF::Table->new(PARENT  => $font,
		                                    NAME    => "$table_nm",
		                                    INFILE  => 0,
		                                    OFFSET  => 0,
		                                    LENGTH  => 0,
		                                    CSUM    => 0);  
    $font->{$table_nm}{' dat'} = $tmp;
}

sub Usage_print()
{
	print <<END;
Copyright (c) SIL International, 2007. All rights reserved.
usage: 
	TypeTuner <ttf> <xml> (calls createset)
	TypeTuner <xml> <ttf> (calls applyset)
	
	or TypeTuner [<switches>] <command> [files, ...]
	
commands:
	createset font.ttf feat_set.xml 
	createset feat_all.xml feat_set.xml
	
	applyset     feat_set.xml font.ttf
	applyset_xml feat_all.xml feat_set.xml font.ttf
	
	extract font.ttf feat_set.xml
	add     feat_all.xml font.ttf
	delete  font.ttf

switches:
	-n	specify font name suffix
	-o	specify output font.ttf file name
END
	exit();
};

#### main processing ####

sub cmd_line_exec() #for UltraEdit function list
{}

my ($font, %feat_all, $feat_set, %feat_tag, @commands);
my ($feat_all_fn, $feat_set_fn, $font_fn, $font_out_fn);

getopts($opt_str); #sets $opt_?'s and removes the switches from @ARGV

if (scalar @ARGV == 0)
	{Usage_print;}

my ($cmd);
$cmd = $ARGV[0];
if (not $cmd =~ /createset|applyset|applyset_xml|delete|extract|add/)
{ #if no subcommands are given, determine action by file types
	if (scalar @ARGV == 2)
	{
		my ($ext1, $ext2);
		($ext1, $ext2) = (lc(substr($ARGV[0],-3,3)), lc(substr($ARGV[1],-3,3)));   
		if ($ext1 eq 'xml' && $ext2 eq 'ttf')
		{
			$cmd = 'applyset';
			unshift (@ARGV, 'applyset')
		}
		elsif ($ext1 eq 'ttf' && $ext2 eq 'xml')
		{
			$cmd = 'createset';
			unshift (@ARGV, 'createset')
		}
		else
			{Usage_print;}
	}
}

if ($cmd eq 'createset')
{ #create feat_set from feat_all either embedded in font or in separate XML file
	if (scalar @ARGV != 3)
		{Usage_print;}
		
	if ($opt_d) {print "creating feat_set XML file from font\n";}		
	my ($fn, $ext, $flag, $fh);
	$fn = $ARGV[1];
	$ext = lc(substr($ARGV[1], -3, 3));
	$flag = 0;
	
	if ($ext eq 'ttf') #set $feat_all_fn
	{ #extract XML from font into a temp file 
		$font = Font::TTF::Font->open($fn) or die "Can't open font";
		
		$flag = 1;
		($fh, $feat_all_fn) = tempfile();
		if ($opt_d) {print "feat_all_fn: $feat_all_fn\n"}
		$fh->close;
		#$feat_all_fn = substr($fn, 0, -4) . "_feat_all.xml";
		Table_extract($font, $feat_all_fn, 0);
	}
	elsif ($ext eq 'xml')
	{
		$feat_all_fn = $fn
	}
	else
		{Usage_print;}
	
	$feat_set_fn = $ARGV[2];	
	Feat_All_parse($feat_all_fn, %feat_all, %feat_tag);
	Feat_Set_write($feat_set_fn, %feat_all);
	
	if ($flag)
		{unlink($feat_all_fn);}
}
elsif ($cmd eq 'applyset' || $cmd eq 'applyset_xml')
{ #apply feat_set to font based on feat_all either embedded in font or in separate XML file
	if (scalar @ARGV != 3 && scalar @ARGV != 4)
		{Usage_print;}
	
	if ($opt_d) {print "applying feat_set XML file to font\n";}		

	my ($flag) = 0;
	if ($cmd eq 'applyset')
	{
		($feat_set_fn, $font_fn) = ($ARGV[1], $ARGV[2]);
		my ($fh);
		
		#extract XML from font into a temp file
		$font = Font::TTF::Font->open($font_fn) or die "Can't open font";
		
		$flag = 1;
		($fh, $feat_all_fn) = tempfile();
		if ($opt_d) {print "feat_all_fn: $feat_all_fn\n"}
		$fh->close;
		#$feat_all_fn = substr($font_fn, 0, -4) . "_feat_all.xml";
		Table_extract($font, $feat_all_fn, 0);
	} else #applyset_xml
	{
		($feat_all_fn, $feat_set_fn, $font_fn) = ($ARGV[1], $ARGV[2], $ARGV[3]);
	}
	
	Feat_All_parse($feat_all_fn, %feat_all, %feat_tag);
	Feat_Set_parse($feat_set_fn, %feat_tag, $feat_set);
	if ($opt_d) {print "feat_set = $feat_set\n";}
	Feat_Set_cmds(%feat_all, $feat_set, @commands);
	if ($opt_d) {print "commands: \n"; foreach (@commands) {print "$_->{'cmd'}: $_->{'args'}\n"}; print "\n";}
	$font = Font::TTF::Font->open($font_fn) or die "Can't open font";
	Cmds_exec($font, @commands, %feat_all);
	Font_ids_update($font, %feat_all, $feat_set);
	
	#delete feat_all and embed feat_set file in font
	if (defined $font->{$table_nm})
	{
		delete $font->{$table_nm};
	}
	Table_add($font, $feat_set_fn, 0);
	
	$font_out_fn = $opt_o ? $opt_o : substr($font_fn, 0, -4) . '_tt.ttf';
	$font->out($font_out_fn);
	$font->release;
	
	if ($flag)
		{unlink($feat_all_fn);}
}
elsif ($cmd eq 'add')
{ #add feat_all XML (or feat_set XML with -f option) to font
	if (scalar @ARGV != 3)
		{Usage_print;}
	
	if ($opt_d) {print "adding $table_nm table to font\n";}		
    ($feat_all_fn, $font_fn) = ($ARGV[1], $ARGV[2]);
    my ($feat_all_test);

	$font = Font::TTF::Font->open($font_fn) or die "Can't open font\n";
	if (not defined $opt_f)
		{$feat_all_test = 1;}
	else
		{$feat_all_test = 0;}
	Table_add($font, $feat_all_fn, $feat_all_test);	

	$font_out_fn = $opt_o ? $opt_o : substr($font_fn, 0, -4) . '_tt.ttf';
	$font->out($font_out_fn);
	$font->release;
}
elsif ($cmd eq 'extract')
{ #write feat_all or feat_set XML embedded in font to an XML file
	if (scalar @ARGV != 3)
		{Usage_print;}
	if ($opt_d) {print "extracting $table_nm table from font\n";}		
	
	my ($feat_fn, $feat_set_test);
	($font_fn, $feat_fn) = ($ARGV[1], $ARGV[2]);

	$font = Font::TTF::Font->open($font_fn) or die "Can't open font";
	if (not defined $opt_f)
		{$feat_set_test = 1;}
	else
		{$feat_set_test = 0;}
	Table_extract($font, $feat_fn, $feat_set_test);
}
elsif ($cmd eq 'delete')
{ #delete feat_all or feat_set XML from a font
	if (scalar @ARGV != 2)
		{Usage_print;}

	if ($opt_d) {print "deleting $table_nm table from font\n";}		
	$font_fn = $ARGV[1];
	
	$font = Font::TTF::Font->open($font_fn) or die "Can't open font";
	
	#delete our XML table $table_nm from the ttf
	if (not defined $font->{$table_nm})
		{print "no $table_nm table in font\n";}
	else 
		{delete $font->{$table_nm};}
		
	$font_out_fn = $opt_o ? $opt_o : substr($font_fn, 0, -4) . '_tt.ttf';
	$font->out($font_out_fn);
	$font->release;
}
else
{
	Usage_print;
}

exit;

#### Test code ####

#$font = Font::TTF::Font->open("C:\\Src\\TweakOT\\DoulosSILR.ttf") or die "Can't open font";

#$feat_all_fn = "C:\\Src\\TweakOT\\feat_all.xml";
#$feat_set_fn = "C:\\Src\\TweakOT\\feat_set.xml";

#Feat_All_parse($feat_all_fn, %feat_all, %feat_tag);
#print "feat_all = ", %feat_all, "\n";
#print "feat_tag = ", %feat_tag, "\n";
#Feat_Set_write($feat_set_fn, %feat_all);
#Feat_Set_parse($feat_set_fn, %feat_tag, $feat_set);
#print "feat_set = $feat_set\n";
#Feat_Set_cmds(%feat_all, $feat_set, @commands);
#print "commands: \n"; foreach (@commands) {print "$_->{'cmd'}: $_->{'args'}\n"}; print "\n";
#Cmds_exec($font, @commands, %feat_all);
#Font_ids_update($font, %feat_all, $feat_set);

#Encode($font, "0105", "aogonek.RetroHookStyle");

#Feat_del($font, 'GSUB', 'latn', 'dflt', 'ccmp');
#Feat_add($font, 'GSUB', 'latn', 'dflt', 'ccmp _1', 0);
#Feat_del($font, 'GSUB', 'latn', 'IPA ', 'ccmp');
#Feat_add($font, 'GSUB', 'latn', 'IPA ', 'ccmp _1', 0);
#Feat_del($font, 'GSUB', 'cyrl', 'DEFAULT', 'ccmp');
#Feat_add($font, 'GSUB', 'cyrl', 'DEFAULT', 'ccmp _1', 0);

#Lookup_add($font, 'GSUB', 'ccmp', 4);
#Lookup_add($font, 'GSUB', 'ccmp', 5);
#Lookup_del($font, 'GSUB', 'ccmp', 12);
#Lookup_add($font, 'GSUB', 'ccmp', 12);
#Lookup_add($font, 'GSUB', 'ccmp', 13);

#Line_gap_mod ($font, 2500, 875);

#my ($family_old, $family_new);
#$family_old = Name_get($font, $family_name_id);
#$family_new = $family_old . " new";
#Name_mod($font, $family_name_ids, $family_old, $family_new);

#$font->out("C:\\Src\\TweakOT\\DoulosSILR_mod.ttf");
