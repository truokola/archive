#!/usr/bin/perl

use POSIX;
use CGI::Carp;
use CGI qw(:standard);
use FindBin qw($RealBin);
use File::Path;
use Text::Wrap qw(fill $columns);

$columns = 72;

require "$RealBin/common-funcs";


@editor = qw(noboby Thuneberg Gantmakher Rasmussen Pekola Hakonen);
@editor_full = ('', 'Erkki Thuneberg', 'Vsevolod Gantmakher', 
		'Finn Rasmussen', 'Jukka Pekola', 'Pertti Hakonen');
@editor_email = ("", "ethuneb\@cc.hut.fi", "gantm\@boojum.hut.fi",
		 "finnberg\@mail.fys.ku.dk",
		 "jukka.pekola\@phys.jyu.fi", "pjh\@boojum.hut.fi");

print header, start_html({BGCOLOR => "white", title=>"LT22 Session Editor"});
my $id  = param("id");

if    (param("list"))                   { show_list() }
elsif (param("news"))                   { show_news() }
elsif (param("refselect"))              { show_reflist() }
elsif (defined $id)                     {
    $id =~ s/\D//g;
    if ($id != 0) {
	if (param("Print"))             { print_doc() }
	elsif (param("Submit"))         { save_text() }
	elsif (param("Send"))           { send_msg() }
	elsif (param("Save"))           { save_referee() }
	elsif (param("Save report"))    { save_report() }

	if (param("Update"))            { show_update() }
	elsif (param("Edit"))           { show_edit() }
	elsif (param("Show message"))   { show_email() }
	elsif (param("Show letter"))    { show_reflett() }
	elsif (param("Referee report")) { show_report() }
	else                            { show_main() }
    }
    else                                { show_top() }
}
else                                    { show_select() }

print "\n", end_html;
exit;

sub show_list {
    my $papers = {};
    my $editor = param("list");
    my $sort = param("sort") || "id";
    my @listing = ();
    my @list_caption = ();

    if ($editor < 1 or $editor > $#editor) {
	print p, "No such editor.", end_html;
	exit;
    }
    print h1("Session listing for ", $editor[$editor]), "\n";

    $papers = read_editor_data();

    for my $id (keys %$papers) {
	next unless $papers->{$id}->{editor} == $editor;
	if($papers->{$id}->{withdrawn}) {
	    push @withdrawn, $id;
	} elsif ($papers->{$id}->{reject}) {
	    push @reject, $id;
	} elsif ($papers->{$id}->{invited}) {
	    push @invited, $id;
	} elsif ($papers->{$id}->{oral}) {
	    push @oral, $id;
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
    push @listing, \@oral;
    push @list_caption, "Oral suggestions";
    push @listing, \@invited;
    push @list_caption, "Invited papers";
    push @listing, \@reject;
    push @list_caption, "Rejected abstracts";
    push @listing, \@withdrawn;
    push @list_caption, "Withdrawn abstracts";

    print p, 
    "You need to reload this page to see the changes you have made!\n",
    p, "To see the abstracts, click on the ID number.", br,
    "You can sort the data according to any column by clicking on the ",
    "column title.", br,
    "M = Manuscript submitted",br,
    a({href => "/cgi/search"}, "Search abstracts");
    print p, strong("NEW! "), a({href => "/cgi/sort/$editor"}, "Sorting system")
	if ($editor == 2 || $editor == 3);
    print p, "<TABLE BORDER=\"1\">\n"; 
    my @column_capts = qw(ID Poster M PACS Speaker Title Notes);
    print "<TR>\n";
    for (@column_capts) {
	print th(a({href => script_name() . "?list=$editor&sort=" .
			lc($_)}, $_)), "\n";
    }
    print "</TR>\n";
    shift @column_capts;

    for my $sess (0..$#listing) {
	print "<TR><TH COLSPAN=\"6\" ALIGN=\"LEFT\">$list_caption[$sess] (", 
	scalar @{$listing[$sess]}, ")</TH></TR>\n";
	for my $id (sort {
	    $papers->{$a}->{$sort} <=> $papers->{$b}->{$sort}
	                           ||
	    $papers->{$a}->{$sort} cmp $papers->{$b}->{$sort}
	} @{$listing[$sess]}) {
	    print "<TR>", th(a({href => script_name . "?id=$id"}, $id)), "\n";
	    for my $col (@column_capts) {
		if ($col eq "M") {
		    print td($papers->{$id}->{papsub} ? "M" : "");
		} else {
		    print td($papers->{$id}->{lc($col)}), "\n";
		}
	    }
	    print "</TR>\n";
	}
    }
    print "</TABLE>";
}

sub show_news {
    my $papers = {};
    my $editor = param("news");
    my $pap_start_time = 930000000;
    my $start_time = 925516800;
    my %abs = ();
    my %pap = ();

    save_editor_data(param("id"), {param("type") . "seen" => time()}) if
	param("id");

    if ($editor < 1 or $editor > $#editor) {
	print p, "No such editor.", end_html;
	exit;
    }
    print h1("New and updated contributions for ",
	     $editor[$editor]), "\n",
    p, "Click on the ID to see the abstract, and the \"X\" to remove ",
    "the entry from this list.";

    $papers = read_editor_data();

    for my $id (keys %$papers) {
	my $p = $papers->{$id};
	next if ($p->{editor} != $editor || $p->{withdrawn});
	my $abs_seen = $p->{absseen} || $start_time;
	my $pap_seen = $p->{papseen} || $pap_start_time;;
	my $last_abs = $p->{absre} || $p->{abssub};
	my $last_pap = $p->{papsub};
	$abs{$id} = $last_abs if ($last_abs >= $abs_seen);
	$pap{$id} = $last_pap if ($last_pap && $last_pap >= $pap_seen);
    }
    

    print h3("Abstracts"), p, table({border => 1});
    for my $id (sort {$abs{$b} <=> $abs{$a}} keys %abs) {
	my $date = nice_date($abs{$id});
	$date =~ s/\s+/&nbsp;/g;
	print Tr(td($date) . td(a({href=>script_name . "?id=$id"}, $id)) .
		 td(a({href=>script_name .
			   "?news=$editor&id=$id&type=abs"}, "X")) .
		 td($papers->{$id}->{speaker}) .
		 td($papers->{$id}->{title}));
    }
    print "</TABLE>";

    print h3("Manuscripts"), p, table({border => 1});
    for my $id (sort {$pap{$b} <=> $pap{$a}} keys %pap) {
	my $date = nice_date($pap{$id});
	$date =~ s/\s+/&nbsp;/g;
	print Tr(td($date) . td(a({href=>script_name . "?id=$id"}, $id)) .
		 td(a({href=>script_name .
			   "?news=$editor&id=$id&type=pap"}, "X")) .
		 td($papers->{$id}->{speaker}) .
		 td($papers->{$id}->{title}));
    }
    print "</TABLE>";
}


sub show_reflist {

    if (param("Save")) {
	my %add = ();
	for my $field (param()) {
	    next unless $field =~ /^new_/;
	    my $key = $';
	    my %old = ();
	    my %new = ();
	    my %all = ();
	    for (split /\D+/, param("old_".$key)) { $old{$_}++; $all{$_}++; }
	    for (split /\D+/, param("new_".$key)) { $new{$_}++; $all{$_}++; }
	    for my $id (keys %all) {
		next if (($old{$id} && $new{$id}) || !$id);
		save_editor_data($id, {ref => ""}) if $old{$id};
		$add{$id} = $key if $new{$id};
	    }
	}
	for my $id (keys %add) { save_editor_data($id, {ref => $add{$id}}) }
    }

    my $letter = lc(param("refselect")) || "a";
    my $ref_data = referee_data();
    my %assigned = ();
    print h1("Referee Selection"), p;
    for ("A".."Z") {
	print a({href => script_name . "?refselect=$_"}, $_), " ";
    }

    print start_form, submit("Save"), hidden("refselect", $letter),
    " Save before changing to a different letter!", table,
    Tr(th({-align => "left"}, "Referee"),
       th({-align => "left"}, "Paper numbers"));
    my $paps = read_editor_data();

    for my $id (keys %$paps) {
	my $ref = $paps->{$id}->{ref} || next;
	push @{$assigned{$ref}}, $id;
    }

    for my $ref (sort
		 {lc($ref_data->{$a}->{last}) cmp lc($ref_data->{$b}->{last})}
		 keys %$ref_data) {
	next unless $ref =~ /^$letter/;
	my $p = $ref_data->{$ref};
	print Tr, td, $p->{last}, ", ", $p->{first}, " &lt;",
	$p->{email}, "&gt;",
	hidden({-name => "old_".$ref,
		-value => join(",", @{$assigned{$ref}}),
		-override => 1}),
	"</TD><TD>",
	textfield({-name => "new_".$ref,
		   -value => join(", ", @{$assigned{$ref}}),
		   -size => 40, -override => 1}), "</TD></TR>\n";
    }

    print "</TABLE>", end_form;
}


sub referee_data {
    my %referee = {};
    open DATA, "$logdir/referees";
    while (<DATA>) {
	chomp;
	my ($last, $first, $country, $email) = split /\t+/;
	my $key = lc($last."_".$first);
	$referee{$key}->{last}  = $last;
	$referee{$key}->{first} = $first;
	$referee{$key}->{email} = $email;
    }
    close DATA;
    return \%referee;
}


sub print_doc {
    if ($ENV{'REMOTE_ADDR'} =~ /^130\.233\.172/) {
	if (param("Print") =~ /abs/i) { # print abstract
	    my($abs_file) = last_abs_file($id, "dvi") or my_error($id);
	    system("dvips", "-Pglyph", $abs_file);
	    param("notes", param("notes") . " [pr abs]");
	    save_editor_data($id, {notes => param("notes")});
	} else { # print manuscript
	    my($papfile) = "/lt22/ps/$id.ps";
	    my_error($id) if not -f $papfile;
	    system("lpr", "-Pglyph", $papfile);
	    param("notes", param("notes") . " [pr pap]");
	    save_editor_data($id, {notes => param("notes")});
	}
    } else {
	print p, "Sorry, printing allowed only in the HUT Low Temp Lab.",
	end_html;
	exit;
    }
}

sub save_text {
    my $id = param("id");
    my $savedir = "$indir/$$";
    my $type = param("abstext") ? "abs" : "pap";
    rmtree $savedir, 0, 0;
    mkpath $savedir, 0, 0755;
    open(TEX, ">$savedir/editor_submit.tex") || confess;
    print TEX param($type . "text");
    close(TEX);
    my($result, $data) = tex_it($id, $type);
    if ($result) {
	print p, "Error:", pre($data), end_html;
	exit;
    } else {
	check_in($id, $type);
	if ($type eq "abs") { save_abstract_data($id, "editor-re") }
	else {
	    make_ps($id);
	    save_editor_data($id, {"paplog_".time() => "edit"});
	}
    }
}


sub send_msg {
    my $to = param("to");
    my $from = param("from") || "";
    my $subject = param("subject");
    my $msg = param("msg");
    my $savedata = {};
    my $action = param("mail_type");

    if ($action) {
	param("notes", param("notes") . " [$action]");
	$savedata = {notes => param("notes")};
	$$savedata{acc} = time if $action =~ /^acc/;
    } else {
	$savedata->{"paplog_".time()} = "lett1 " . $to;
    }

    save_editor_data($id, $savedata);
    if(fork() == 0) {
	open STDERR, "/dev/null";
	open STDOUT, "/dev/null";
	send_email($from, $to, $subject, $msg);
	exit;
    }

}

sub save_referee {
    my $ref_data = referee_data();
    my $last  = flatten_name(param("ref_last"));
    my $first = flatten_name(param("ref_first"));
    my $email = param("ref_email");
    my $code = lc($last."_".$first);
    if ($last) {
	append_referee_data($last, $first, $email) if
	    (!$ref_data->{$code} ||
	     ($email && $email ne $ref_data->{$code}->{email}));
	save_editor_data($id, {ref => $code});
    } else {
	save_editor_data($id, {ref => ""});
    }
}

sub append_referee_data {
    my ($last, $first, $email) = @_;
    lockfile("referee", "lock");
    open DATA, ">>$logdir/referees";
    print DATA $last, "\t", $first, "\t", "X", "\t", $email, "\n";
    close DATA;
    lockfile("referee", "unlock");
}

sub save_report {
    open REP, ">$docdir/$id/report";
    print REP param("report");
    close REP;
    save_editor_data($id, {"paplog_".time() => "rep"});
}

sub show_update {
    my(%save_data) = ();
    $save_data{session} = param("session");
    $save_data{oral} = param("oral");
    $save_data{notes} = param("notes");
    $save_data{poster} = param("poster");
    $save_data{reject} = param("reject");
    my($new_editor) = param("editor");
    my($old_editor) = param("old_editor");
    print p, "Paper ", param("id"), " updated.\n",p;
    if($new_editor ne $old_editor) {
	print "Transferred to ", $editor[$new_editor], ".<BR>\n";
	$save_data{session} = "";
	$save_data{poster} = "";
	$save_data{oral} = "";
	$save_data{reject} = "";
	$save_data{notes} .= " [from $editor[$old_editor]]";
	$save_data{editor} = $new_editor;
    } elsif ($save_data{reject}) {
        print "Contribution rejected.";
    } else  {
	print "Session: ", param("session"), "<BR>";
	print "Poster: ", param("poster"), "<BR>";
	print "Oral suggest: ", param("oral") ? "yes" : "no";
	print "<BR>Notes: ", param("notes");
    }
    save_editor_data($id, \%save_data);

} 


sub show_edit {
    if (param("Edit") =~ /bstract/) {
	print h1("Edit Abstract $id"),
	p, start_form, textarea(-name => "abstext",
				-default => raw_abstract_text($id),
				-rows => 30, -columns => 80),
	p, submit("Submit"), hidden("id", $id), end_form;
    } else {
	my $papdir = last_pap_dir($id) or return;
	open(TEX, "$papdir/pap-$id.tex") or return;
	my(@lines) = <TEX>;
	close(TEX);
	my $pap_text = join "", grep(!/^\s*%/, @lines);
	my @papfiles = dir_listing($papdir);
	print h1("Edit Manuscript $id"), p, "Manuscript figures:\n<UL>\n";
	for (@papfiles) {
	    next if (/^pstill\.log/ || /^pap-$id/);
	    print li(a({href => "/cgi/download/$id./$_"}, $_));
	}
	print "</UL>\n";
	print start_form, textarea(-name => "paptext",
				-default => $pap_text,
				-rows => 30, -columns => 80),
	p, submit("Submit"), hidden("id", $id), end_form;
    }
}

sub show_email {
    my $author  = param("author");
    my $to = param("email");
    my $action = param("mail_action");
    my $subject = "LT22 Abstract $id_prefix$id";
    my $pw = "";
    my @actions = qw(acc acc-min acc-mod corr);
    print h1("Message for $id");
    $pw = get_password($id);
    my $msg = "Dear $author,\n\n";
    $msg .= get_message("mail-editor-" . $actions[$action], $id, $pw);

    $msg .= "
The form of the presentation will be a poster, unless you receive
a separate invitation before June.
" unless ($action == 3 || param("invited"));
    

    $msg .= "
PLEASE NOTE: According to our records, the speaker of this abstract has
not registered to LT22. We ask the speaker to register before May 30.
Instructions for registering are given in the Final Announcement, and
on the web page http://lt22.hut.fi/register.html

If the speaker marked in the abstract cannot participate to LT22, there
are two alternatives.

1) Some other author can present the paper.
The speaker can be changed by resubmitting the abstract with a
different speaker. The submission of a revised version is described in
the Final Announcement, or on the web page
http://lt22.hut.fi/abstract/revise.html

2) the paper should be withdrawn by sending an empty email to
withdraw\@lt22.hut.fi with the subject line
  
  $id_prefix$id $pw

We are thankful for the abstract you have sent, and hope you will
participate in LT22 in Helsinki.
" unless param("reg");

    $msg .= "
We encourage you to start thinking about a two page contribution to
the proceedings, which will be published in Physica B.

Information about the proceedings is found at web page
http://lt22.hut.fi/scientific.html
Information about submission of your paper can be found at web page
http://lt22.hut.fi/paper/index.html

The deadline for submission is June 15, 1999. All contributions should
describe new unpublished research and will be refereed.
" unless $action == 3;



    $msg .= "\nWith kind regards,\n" . $editor_full[param("old_editor")] .
	"\nLT22 Editor\n\n";

    $msg .= "-"x70 . "\n\nAbstract Information\n\nPaper-id: $id_prefix$id\n" .
	"Password: $pw\nTitle: " . param("title") .
	 "\nSubmitted: " . nice_date(param("lastsub")) .
	 "\n\n" . "-"x70 . "\n\n";

    $msg .= raw_abstract_text($id) if (!param("reg") || $action != 0);

    print p, start_form,
    "To: ", textfield(-name => "to", -value => $to, -size=> 40), br,
    "Subject: ", textfield(-name => "subject", -value => $subject,
			   -size => 40), br,
    textarea(-name => "msg", -value => $msg, -rows => 30,
	     -columns => 74),
    p, submit("Send"), hidden("id", $id), hidden("notes", param("notes")),
    hidden("mail_type", $actions[$action]),
    end_form;

#    print "<PRE>To: ", a({href => "mailto:" . uri_escape($email) .
#	     "?subject=" . uri_escape($subject) . "&body=" . uri_escape($msg)},
#	      clean_html($email)), "\nSubject: $subject\n\n",
#	      clean_html($msg), "</PRE>";
}

sub show_reflett {
    my $p = abstract_data($id);
    my $comma = 0;
    my $msg = "";
    my $title = $p->{Title}[0][0];
    my $auth = "";
    for  (@{$p->{Speaker}}, @{$p->{Author}}) {
	$auth .= ", " if $comma++;
	$auth .= flatten_name($$_[1] . " " . $$_[2]);
    }
    my $text = "";
    my $ref_full = param("ref_first") . " " . param("ref_last");
    $text .= "Manuscript number: $id_prefix$id\n";
    $text .= fill("", "", "Author: $auth") . "\n";
    $text .= fill("", "", "Title: $title") . "\n";
    $text .= "Referee: " . $ref_full . "\n"; 

print h1("Referee letter"), p, start_form,
    "To: ", textfield(-name => "to",
		      -value => , $ref_full . " <" . param("ref_email") . ">",
		      -size=> 40), br,
    "Subject: ", textfield(-name => "subject",
			   -value=>"Invitation to referee an LT22 manuscript",
			   -size => 40), br,
    textarea(-name => "msg",
	     -value => get_message("mail-editor-referee", $id, "", $text,
				   $editor_email[param("old_editor")],
				   "+1-555-123666",
				   $editor_full[param("old_editor")],
				   param("ref_last")),
				   
	     -rows => 30,
	     -columns => 74),
    p, hidden("id", $id),
    hidden("from", $editor_full[param("old_editor")] . " <" .
	   $editor_email[param("old_editor")] . ">"),
    submit("Send"), end_form;
}    


sub show_report {
    my @report = ();
    open REP, "$docdir/$id/report" and @report = <REP> and close REP;
    print h1("Referee report for $id"), p, start_form,
    textarea(-name => "report",
	     -value => join("", @report),
	     -rows => 30,
	     -columns => 74),
    p, hidden("id", $id),
    submit("Save report"), end_form;
}
    

sub show_totals {
    my @count = ();
    my $papers = read_editor_data();
    my $sum = 0;

    for my $id (keys %$papers) {
	next if $papers->{$id}->{withdrawn};
	next if $papers->{$id}->{invited};
	$count[$papers->{$id}->{editor}]++;
    }
    
    print h3("Total number of contributed abstracts"), p;

    for (1..$#editor) {
	print $editor[$_], ": ", $count[$_], br, "\n";
	$sum += $count[$_];
    }
    print p, "Total ", $sum;
}


sub show_main {
    my($fieldref) = {};
    my($dataref) = {};
    $fieldref = abstract_data($id) or my_error($id);
    $dataref = read_editor_data()->{$id} or my_error($id);
    show_top();

    if (param("g")) {
	print p, img({src => "/cgi/download/" . time() . "/$id.jpg"}),
	p, "View abstract as ", a({href => script_name . "?id=$id"},
				  "as text"), ".\n";
    } else {
	print html_abstract($id),
	p, "View abstract as ", a({href => script_name . "?id=$id&g=1"},
				  "as graphics"), ".\n";
    }
    print hr;

    print start_form, hidden("id", $id);
    print $dataref->{invited} ? (strong("INVITED PAPER"), br) : "",
    hidden("invited", $dataref->{invited});
    print "\nPACS: ", $fieldref->{PACS}[0][0], "<BR>\n";
    my $author = flatten_name($fieldref->{ContactAuthor}[0][0] . " " .
	$fieldref->{ContactAuthor}[0][1]);
    print "Contact author: ", clean_html($author), ", ";
    my $email = $fieldref->{Email}[0][0];
    print a({href => "mailto:$email"}, clean_html($email)), "\n";
    print hidden("author", $author), hidden("email", $email), 
    hidden("title", $fieldref->{Title}[0][0]), br,
    hidden("reg", $dataref->{r}), p;

    print "Abstract submitted: ", nice_date($dataref->{abssub}), br;
    print "Abstract modified by author: ",
    nice_date($dataref->{absre}), br;
    print "Manuscript modified: ", nice_date($dataref->{papsub}),
    hidden("lastsub", $dataref->{absre} || $dataref->{abssub}), p;

    print "Editor: ", $editor[$dataref->{editor}];
    print ", transfer to editor: ",
	popup_menu(-name => 'editor', -values => [1..$#editor],
		   -default => $dataref->{editor},
		   -labels => \%{{map (($_,$editor[$_]),(1..$#editor))}});
    print hidden("old_editor", $dataref->{editor});

    print p, "Session number: ",
    textfield(-name => "session", -value => $dataref->{session},
	      -size => 10);
    print " Poster number: ",
    textfield(-name => "poster", -value => $dataref->{poster},
	      -size => 10), br;

    print checkbox_group(-name=> 'oral', -value=> '1',
			 -labels => {1 => ''}, -defaults =>
			 $dataref->{oral}),
	  " Suggest for oral presentation", br;
    print checkbox_group(-name => 'reject', -value => '1',
			 -labels => {1 => ''}, -defaults =>
			 $dataref->{reject}), " Reject", br;
    print "Notes: ", textfield(-name => 'notes', 
			       -default => $dataref -> {notes},
			       -size => 60);

    print p, submit("Update"),
    strong(" Remember to update whenever you change the data above!");

    print hr;

    print submit(-name => "Edit", -value => "Edit abstract"),
    " Modify the abstract contents\n", br;
    print submit("Print", "Print abstract");

    print p, "Send an email to the abstract author:", br;
    print radio_group(-name => "mail_action", -values => [0..3],
		      -default => 0, -linebreak => "true", -labels => 
		      {0 => " accept unmodified [acc]",
		       1 => " accept with minor editor modifications [acc-min]",
		       2 => " accept with editor modifications [acc-mod]",
		       3 => " needs author corrections [corr]"}),
    submit("Show message"), hr;
    
    my $papdir = "";
    if ($papdir = last_pap_dir($id)) {
	print submit("Print", "Print manuscript"),
	" or download ", a({href => "/cgi/download/$id.ps"}, "ps"),
	" \nor ", a({href => "/cgi/download/$id.pdf"}, "pdf"), br,
	submit(-name => "Edit", -value => "Edit manuscript"), br;
    }

    my $last = my $first = my $ref_email = "";
    if (my $code = $dataref->{ref}) {
	my $ref_data = referee_data();
	$last  = $ref_data->{$code}->{last};
	$first = $ref_data->{$code}->{first};
	$ref_email = $ref_data->{$code}->{email};
    }
    print a({href => script_name . "?refselect=" .
		 (substr($last, 0, 1) || "A")}, "Referee:"), " ",
    textfield({-name => "ref_first", -size => 10,
	       -value => $first, -override => 1}),
    textfield({-name => "ref_last", -size => 15,
	       -value => $last, -override => 1}), 
    " email: ",
    textfield({-name => "ref_email", -size => 30,
	       -value => $ref_email, -override => 1}),
    " ", submit("Save"), p,
	submit("Show letter"), br,
	submit("Referee report"), p,
	"Manuscript transactions:", br,
	table({cellpadding => 0, cellspacing => 0});
    for my $key (sort keys %$dataref) {
	next unless $key =~ /^paplog_/;
	print Tr, td(nice_date($'). " ");
	$dataref->{$key} =~ /(\S+)(?:\s+|$)(.*)/;
	my $act = $1;
	my $info = $2 || "";
	print td({edit => "Edited",
		  lett1 => "Referee letter to",
	          sub => "Submitted",
		  rep => "Referee report edited",
		  snail => "Submitted in hardcopy"
		  }->{$act} .
	" " . clean_html($info)), "</TR>\n";
    }
    print "</TABLE>\n",
    end_form;
}


sub show_top {
    print start_form, "Id number ", textfield("id"), p,
    submit("Show"), end_form, hr;
}


sub show_select {
    print p, "You can ", a({href => script_name() . "?id="},
			  "view individual abstracts"),
    p, "or", p, "see a list of abstracts for\n<UL>";
    for my $idx (1..$#editor) {
	print li($editor[$idx], ": ",
		 a({href => script_name() . "?list=$idx"}, "all"), " or ",
		 a({href => script_name() . "?news=$idx"}, "new"));
 
    }
    print "</UL>";
    print p, a({href => "/cgi/search"}, "Search abstracts"), p;
    print a({href => script_name . "?refselect=A"}, "Referee selection"), p;
    show_totals();
}


# NOT print_pap_dl but print pap_dl(); !!!


#sub print_pap_download {
#    my($id) = @_;
#    my($ps) = my($pdf) = my($tex) = 0;
#    if (my($papdir) = last_pap_dir($id)) {
#	$ps = 1 if -f "$papdir/pap-$id.ps";
#	$pdf = 1 if -f "$papdir/pap-$id.pdf";
#	$tex = 1 if -f "$papdir/pap-$id.tex";
#    }
#    print "Download manuscript: ",
#    ($tex ? "<A HREF=\"/cgi/gimme?name=/$id.tex\">TeX</A>" : "TeX"), " | ",
#    ($ps ? "<A HREF=\"/cgi/gimme?name=/$id.ps\">PS</A>" : "PS"), " | ",
#    ($pdf ? "<A HREF=\"/cgi/gimme?name=/$id.pdf\">PDF</A>" : "PDF"), "\n";
#    print " or ", submit("Print", "Print it") if $ps;
#}

sub nice_date {
    my $time = shift or return "";
    return strftime("%b %d, %Y", localtime($time));
}

sub my_error {
    my($id) = @_;
    print p;
    if($id != 0) {
	if (-d "$docdir/$id-W")    { print "Paper $id has been withdrawn." }
        elsif (! -d "$docdir/$id") { print "Unknown paper $id." }
	else {
	    print "Something wrong with paper $id.",
	    "I'll mail the webmaster.";
	    send_email("", "webmaster", "FAIL with $id", "");
	    confess $@;
	}
    } else { print "Say what?" }
    print end_html;
    exit;
}

#sub uri_escape {
#    my($text) = @_;
#    $text =~ s/\n/\r\n/g;
#    $text =~ s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;
#    return $text;
#}

sub raw_abstract_text {
    my($id) = @_;
    my $file = last_abs_file($id) or return "";
    open(TEX, last_abs_file($id)) or return "";
    my(@lines) = <TEX>;
    close(TEX);
    my $abs_text = join "", grep(!/^\s*%/, @lines);
    return $abs_text;
}

sub get_password {
    my($id) = @_;
    my $pw = "";
    return "" if (($id == 0) || (! -d "$docdir/$id") ||
		  (! open(PASS, "$docdir/$id/pass")));
    chomp($pw = <PASS>);
    close(PASS);
    return $pw;
}
