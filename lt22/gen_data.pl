#!/usr/bin/perl -w

use FindBin qw($RealBin);
require "$RealBin/common-funcs";


@ids = dir_listing($docdir);
 
for my $id (@ids) {
    next unless $id =~ /^\d+$/;
    my($abs) = abstract_data($id);
    $abs->{PACS}[0][0] =~ /^\s*(\S+?)(?:,|;|\s|$)/;
    my($pacs) = $1;
    my($editor) = pacs_to_editor($pacs);
    save_editor_data($id, {editor => $editor,
			   title => $abs->{Title}[0][0],
			   speaker => $abs->{Speaker}[0][2] . ", " .
			   $abs->{Speaker}[0][1],
			   pacs => $pacs,
			   invited => is_marked_invited($id),
			   abssub => ((stat("$docdir/$id/pass"))[9])});

}


