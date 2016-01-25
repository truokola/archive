#!/usr/bin/perl

use POSIX;
use CGI::Carp;
use CGI qw(:standard);
use FindBin qw($RealBin);
use File::Path;
require "$RealBin/common-funcs";


my @session_letters = qw(K L M N P Q R S T U V W);
@halls = ("", "E", "A", "B", "C", "D");
my @days = (5, 6, 7, 9, 10);
@dates = ("Thursday, August 5",
	  "Friday, August 6",
	  "Saturday, August 7",
	  "Monday, August 9",
	  "Tuesday, August 10",
	  "Wednesday, August 11");

@section = ("",
	    "Quantum Gases, Fluids and Solids",
	    "Superconductivity",
	    "Magnetism and Lattice Properties",
	    "Quantum Electron Transport",
	    "Applications, Materials and Techniques");


print header;
my $id;
if (defined param("id")) {
    param("id") =~ /(\d+)/;
    $id = $1 || 0;
} else {
    $id = undef;
}

if    (param("list"))                 { show_list() }
elsif (defined param("day"))          { show_day() }
elsif (defined $id)                   {
    $id =~ s/\D//g;
    if ($id != 0)                     { show_main() }
    else                              { show_top() }                     
}
else                                  { show_select() }

print "\n", end_html;
exit;


sub show_list {
    my $papers = {};
    my $editor = param("list");
    my $sort = param("sort") || "id";
    my @listing = ();
    my @list_caption = ();

    if ($editor < 1 or $editor > $#section) {
	print start_html("Abstract viewer error"), p, "No such section.", end_html;
	exit;
    }
    print start_html({BGCOLOR => "white",
		      title => "Abstract viewer: $section[$editor]"}),
    h1("Posters for ", $section[$editor]), "\n";

    $papers = read_editor_data();

    for my $id (keys %$papers) {
	my $p = $papers->{$id};
	next if ($p->{invited} || $p->{withdrawn} ||
		 $p->{editor} != $editor || !$p->{acc});
	push @posters, $id;
    }

    print p, "<TABLE BORDER=\"1\">\n",
    Tr(th(Speaker) . th(Title)); 
    for my $id (sort {
	$papers->{$a}->{speaker} cmp $papers->{$b}->{speaker}
    } @posters) {
	print Tr(td($papers->{$id}->{speaker}) .
		 td(a({href => script_name . "?id=$id"}, $papers->{$id}->{title})));
    }
    print "</TABLE>";
}

sub show_day {
    my $day = param("day");
    $day = {5 => 0, 6 => 1, 7 => 2, 9 => 3, 10 => 4}->{$day} if $day > 4;
    if (!$dates[$day]) {
	print p, "Sorry, that's not a conference day!";
	return;
    }

    print start_html({BGCOLOR => "white",
		      title => "LT22 Poster sessions: $dates[$day]"});
    my $papers = read_editor_data();
    my ($editor_session, $session_title, $chairs) = session_data();
    my @session = ();

    for my $id (keys %$papers) {
	my $p = $papers->{$id};
	next if ($p->{invited} || $p->{withdrawn} || $p->{reject});
	my ($day_code, $sect) =
	    @{$$editor_session{$p->{editor} . $p->{session}}};
	
	next if ($day_code != $day || !defined $day_code);
	push @{$session[$sect]}, $id;
    }

    my $list = "";
    print "<H1>$dates[$day]</H1>\n\n";
    print "<P>Please note that these arrangements are <EM>tentative!</EM><UL>\n";
    for my $sect (0..$#session) {
	next if $#{$session[$sect]} == -1;
	$list .= "<H2><A NAME=\"$session_letters[$sect]\">Session " .
	$days[$day] . $session_letters[$sect] . ": " .
	$$session_title[$day][$sect] . "</A></H2>\n\n" .
        "<P><STRONG>Chairman:</STRONG> " . $$chairs[$day][$sect] ."\n\n<DL>";
	print "<LI><A HREF=\"#", $session_letters[$sect], "\">Session ",
	$days[$day], $session_letters[$sect], ": ",
	$$session_title[$day][$sect], "</A></LI>\n";
	for my $id (sort
		    {$papers->{$a}->{poster} <=> $papers->{$b}->{poster}}
		    @{$session[$sect]}) {
	    $list .= "<DT><STRONG>" . $papers->{$id}->{speaker} .
	    "</STRONG></DT>:<DD>" .
	    a({href => script_name . "?id=$id"},
	      clean_html($papers->{$id}->{title})) . "</DD>\n";
	}
	$list .= "</DL>\n";
    }
    print "</UL>\n<P><A HREF=\"/index.html\">Back to index</A>\n\n", $list;
}

sub session_data {
    my %editor_session = {};
    my @session_title = ();
    my @chairmen = ();
    open DATA, "$logdir/poster_sessions";
    while (<DATA>) {
	chomp;
	my ($editor, $code, $day, $sect, $title, $chair) = split /\t+/;
	$editor_session{$editor . $code} = [$day, $sect];
	$session_title[$day][$sect] = $title;
	$chairmen[$day][$sect] = $chair;
    }
    close DATA;
    return \%editor_session, \@session_title, \@chairmen;
}


sub show_main {
    my($fieldref) = {};
    my($dataref) = {};
    -d "$docdir/$id" or my_error($id);
    print start_html({BGCOLOR => "white",
		      title=>"LT22 Abstract $id_prefix$id"});

    my ($title, $time, $venue) = presentation($id);
    print strong($title), br, $time, br, $venue, br, hr;

    if (param("g")) {
	print p, img({src => "/cgi/download/$id.jpg"}), hr,
	p, "View a ", a({href => script_name . "?id=$id"},
				  "text version"), " of the abstract.\n";
    } else {
	print html_abstract($id), hr,
	p, "View  a ", a({href => script_name . "?id=$id&g=1"},
				  "graphical version"), " of the abstract.\n";
    }

    print p, "Download manuscript: ";
    my $papdir = last_pap_dir($id);
    my $size = $papdir && (stat "$papdir/pap-$id.tex")[7];
    print "<A HREF=\"/cgi/download/$id.tex\">" if $size;
    print "TeX";
    print "</A>" if $size;
    print " (", ($size ? int ($size/1024 + .5) . " kB" : "n/a"), ") or ";
    my $ps = "/lt22/ps/$id.ps";
    $size = (stat $ps)[7];
    print "<A HREF=\"/cgi/download/$id.ps\">" if $size;
    print "PostScript";
    print "</A>" if $size;
    print " (", ($size ? int ($size/1024 + .5) . " kB" : "n/a"), ") or ";
    my $pdf = "/lt22/pdf/$id.pdf";
    $size = (stat $pdf)[7];
    print "<A HREF=\"/cgi/download/$id.pdf\">" if $size;
    print "PDF";
    print "</A>" if $size;
    print " (", ($size ? int ($size/1024 + .5) . " kB" : "n/a"), ")", br
	"To view the manuscript, you can use ", 
	"<A HREF=\"http://www.adobe.com/prodindex/acrobat/readstep.html\">",
	"Acrobat Reader</A> for PDF and ",
	"<A HREF=\"http://www.cs.wisc.edu/~ghost/\">",
	"Ghostview</A> for PostScript.";
#    print p, hr, a({href => script_name}, "Abstract index");
    
}


sub presentation {
    my $id = shift;
    my $abs = read_editor_data($id)->{$id};
    if ($abs->{invited}) {
	require "$RealBin/session";
	my ($sp,undef) = speakers();
	for my $sect (0..$#{$sp}) {
	    for my $sess (0..$#{$$sp[$sect]}) {
		for my $talk (@{$$sp[$sect][$sess]}) {
		    next unless $talk->{paper} == $id;
		    my $day = $talk->{day};
		    my $type = $talk->{type};
		    my $session = "";
		    return if $type < 2;
		    $para = {0 => "a", 1 => "b"}->
		    {$sessions[$sect][$sess]{pos}};
		    my ($end_h, $end_m) = addtime($talk->{hour},
						  $talk->{min}, $talk->{len});
		    return (a({href => "/invited.html"}, 
			      "Session $days[$day]$para$halls[$sect]" . ": " .
			      $sessions[$sect][$sess]{name}),
			    $dates[$day] . " at " . 
			    sprintf("%02d:%02d - %02d:%02d", 
				    $talk->{hour}, $talk->{min},
				    $end_h, $end_m),
			    "HUT main building, lecture hall $halls[$sect]");
		}
	    }
	}
    } else {
	my ($sessions, $titles) = session_data();
	my ($day, $sect) = @{$sessions->{$abs->{editor}.$abs->{session}}};
	return unless defined $day;
	return (a({href => script_name .
		       "?day=$day#$session_letters[$sect]"},
		  "Session " . $days[$day] . $session_letters[$sect] . ": " .
		$$titles[$day][$sect]),
		$dates[$day] . " at 16:00 - 19:00",
		"Otahalli sports hall, poster section " .
		$session_letters[$sect]);
    }
}



sub show_top {
    print start_html("LT22 Abstracts"), start_form, "Id number ",
    textfield("id"), " (e.g. S12154)", p,
    submit("Show"), end_form, hr;
}


sub show_select {
    print start_html({BGCOLOR => "white", title => "LT22 Abstract Index"}),
    h1("Abstract index");    
    print p, "You can ", a({href => script_name() . "?id="},
			  "view individual abstracts"),
    " by submission id",
    p, "or", p, "see the current ",
    a({href => "/invited.html"}, "oral programme"), p, "or", p,
    "see a list of all posters for section\n<UL>";
    for my $idx (1..$#section) {
	print li(a({href => script_name() . "?list=$idx"},
		   $section[$idx])), "\n";
    }
    print "</UL>";
#########    print p, a({href => "/cgi/find"}, "Search abstracts"), p;
}

sub my_error {
    my($id) = @_;
    print p;
    if($id != 0) {
	if (-d "$docdir/$id-W")    { 
	    print "Paper $id_prefix$id has been withdrawn.";
	}
        elsif (! -d "$docdir/$id") {
	    print "Unknown paper $id_prefix$id.";
	}
	else {
	    print "Something wrong with paper $id_prefix$id.",
	    "I'll mail the webmaster.";
	    send_email("", "webmaster", "FAIL with $id", "");
	    confess $@;
	}
    } else { print "Say what?" }
    print end_html;
    exit;
}

