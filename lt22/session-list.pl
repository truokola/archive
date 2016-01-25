#!/usr/bin/perl

use CGI qw(:standard);
use FindBin qw($RealBin);

require "$RealBin/common-funcs";

@editor = qw(nobody Gantmakher Thuneberg Pekola Rasmussen Hakonen);


my($papers) = {};
my($editor) = param("editor");
my($sort) = param("sort") || "id";
my(@listing) = ();
my(@list_caption) = ();

print header, start_html("Session listing");

if ($editor < 1 or $editor > $#editor) {
    print p, "No such editor.";
    print end_html;
    exit;
}
print "<H1>Session listing for ", $editor[$editor], "</H1>\n";


$papers = read_editor_data();

for my $id (keys %$papers) {
    next unless $papers->{$id}->{editor} == $editor;
    if($papers->{$id}->{withdrawn}) {
	push @withdrawn, $id;
    } elsif ($papers->{$id}->{reject}) {
	push @reject, $id;
    } elsif ($papers->{$id}->{invited}) {
	push @invited, $id;
    } elsif (not $papers->{$id}->{session}) {
	push @new, $id;
    } else {
	push @{$session{$papers->{$id}->{session}}}, $id;
    }
}

push @listing, \@new;
push @list_caption, "New abstracts";
for (sort {$a <=> $b || $a cmp $b} keys %session) {
    push @listing, $session{$_};
    push @list_caption, "Session $_";
}
push @listing, \@invited;
push @list_caption, "Invited papers";
push @listing, \@reject;
push @list_caption, "Rejected abstracts";
push @listing, \@withdrawn;
push @list_caption, "Withdrawn abstracts";

print <<EOT;
<P>You need to reload this page to see the changes you have made!
<P>To see the abstracts, click on the ID number.<BR>
You can sort the data according to any column by clicking on the
column title. 
<P>
<TABLE BORDER="1">
<TR>
<TH><A HREF="/cgi/session-list?editor=$editor&sort=id">ID</A></TH>
<TH><A HREF="/cgi/session-list?editor=$editor&sort=poster">Poster</A></TH>
<TH><A HREF="/cgi/session-list?editor=$editor&sort=pacs">PACS</A></TH>
<TH><A HREF="/cgi/session-list?editor=$editor&sort=speaker">Speaker</A></TH>
<TH><A HREF="/cgi/session-list?editor=$editor&sort=title">Title</A></TH>
<TH><A HREF="/cgi/session-list?editor=$editor&sort=notes">Notes</A></TH>
</TR>
EOT

for my $sess (0..$#listing) {
    print "<TR><TH COLSPAN=\"6\" ALIGN=\"LEFT\">$list_caption[$sess] (", 
    scalar @{$listing[$sess]}, ")</TH></TR>\n";
    for my $id (sort {
	$papers->{$a}->{$sort} <=> $papers->{$b}->{$sort}
	                       ||
	$papers->{$a}->{$sort} cmp $papers->{$b}->{$sort}
    } @{$listing[$sess]}) {
	print "<TR><TH><A HREF=\"/cgi/abs-edit?id=$id\">$id</A></TH>\n";
	print "<TD>$papers->{$id}->{poster}</TD>\n";
	print "<TD>$papers->{$id}->{pacs}</TD>\n";
	print "<TD>$papers->{$id}->{speaker}</TD>\n";
	print "<TD>$papers->{$id}->{title}</TD>\n";
	print "<TD>$papers->{$id}->{notes}</TD>\n";
	print "</TR>\n";
    }
}






print "</TABLE>\n", end_html;





