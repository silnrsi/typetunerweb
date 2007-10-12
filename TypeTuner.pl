# © SIL International 2007. All rights reserved.
# Please do not redistribute.

use TypeTuner;

if (scalar @ARGV != 0)
	{TypeTuner::cmd_line_exec(@ARGV); exit();}

#start the GUI if there are no command line arguments
use Gtk2 '-init';
use Gtk2::GladeXML;

$gladexml = Gtk2::GladeXML->new('typetuner.glade');
$gladexml->signal_autoconnect_from_package('main');
$closebtn = $gladexml->get_widget('Close'); 
Gtk2->main();

sub on_main_delete_event
{
	#return 0;
	Gtk2->main_quit();
}

#This sub isn't connected, but it was mentioned in the Glade doc
sub gtk_main_quit
{
	Gtk2->main_quit();
}

sub on_b_Close_clicked
{
	TypeTuner::cmd_line_exec('-d', 'applyset_xml', 'feat_all.xml', 'feat_set.xml', 'zork.ttf');
}
