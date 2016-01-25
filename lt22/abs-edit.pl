#!/usr/bin/perl

use CGI qw(:standard);
use FindBin qw($RealBin);
use File::Path;
require "$RealBin/common-funcs";

@editor = qw(noboby Gantmakher Thuneberg Pekola Rasmussen Hakonen);
@editor_full = ('', 'Vsevolod Gantmakher', 'Erkki Thuneberg',
		'Jukka Pekola', 'Finn Rasmussen', 'Pertti Hakonen');

@section = ("","Superconductivity",
	    "Quantum Gases, Fluids and Solids",
	    "Quantum Electron Transport",
	    "Magnetism and Lattice Properties",
	    "Applications, Materials and Techniques");

%editor_fields = (editor => 'Editor', session => 'Session',
		  oral => 'Suggest for oral presentation',
		  transfer => 'Transfer to editor');


# NOT print_pap_dl but print pap_dl(); !!!

sub print_pap_download {
    my($id) = @_;
    my($ps) = my($pdf) = my($tex) = 0;
    if (my($papdir) = last_pap_dir($id)) {
	$ps = 1 if -f "$papdir/pap-$id.ps";
	$pdf = 1 if -f "$papdir/pap-$id.pdf";
	$tex = 1 if -f "$papdir/pap-$id.tex";
    }
    print "Download manuscript: ",
#    ($tex ? "<A HREF=\"/cgi/gimme?name=/$id.tex\">TeX</A>" : "TeX"), " | ",
    ($ps ? "<A HREF=\"/cgi/gimme?name=/$id.ps\">PS</A>" : "PS"), " | ",
    ($pdf ? "<A HREF=\"/cgi/gimme?name=/$id.pdf\">PDF</A>" : "PDF"), "\n";
    print " or ", submit("Print", "Print it") if $ps;
}

sub nice_date {
    my($time) = shift || return "";
    my($d, $m) = (localtime($time))[3,4];
    return ($d) . "." . ($m+1) . ".";
}

sub print_editor_header {
    print start_form, "Id number ", textfield("id"), p,
    submit("Show"),
    end_form,
    hr;
}


print header, start_html("LT22 Session Editor");
print h1("Session Editor");

if(param("Print") && param("id")) {
    my($id) = param("id");
    if (param("Print") eq "Print") {
	my($abs_file) = last_abs_file($id);
	$abs_file =~ s/tex$/dvi/;
	system("dvips -P glyph $abs_file");
    } else {
	system("lpr", "-Pglyph", last_pap_dir($id)."/pap-$id.ps");
    }
}


if(param("Edit") && param("id")) {
    my($id) = param("id");
    open(TEX, last_abs_file($id)) || confess;
    my(@lines) = <TEX>;
    close(TEX);
    my($abs_text) = join "", grep(!/^\s*%/, @lines);
    print h3("Abstract $id");
    print p, start_form, textarea(-name => abstext, -default => $abs_text,
				  -rows => 30, -columns => 80);
    print p,submit("Submit"), hidden("id", $id), end_form;
}

elsif(param("Submit") && param("id")) {
    my($id) = param("id");
    my($savedir) = "$indir/$$";
    rmtree $savedir, 0, 0;
    mkpath $savedir, 0, 0755;
    open(TEX, ">$savedir/abstract.tex") || confess;
    print TEX param("abstext");
    close(TEX);
    my($result, $data) = tex_it($id, 'abs');
    if ($result) {
	print p, "Error:\n<PRE>", $data, "</PRE>\n";
    } else {
	check_in($id, 'abs');
	save_abstract_data($id, "editor-re");
	my($ref) = abstract_data($id);
	my $editor = read_editor_data()->{$id}->{editor};
	my($name) = $ref->{ContactAuthor}[0][0]." ".$ref->{ContactAuthor}[0][1];
	my($email) = $ref->{Email}[0][0];
	print p, "I need your suggestions on what's the best way to send this ";
	print "email notification. Cut-and-paste to your email program?<HR>\n"; 
	print "<PRE>\nTo: <A HREF=\"mailto:$email\">$name &lt;$email&gt;</A>\n\n";
	print "Dear $name,\n\nYour abstract S$id is accepted to ";
	print "the LT22 conference in the following form.\n\n";
	print "Yours,\n$editor_full[$editor]\nLT22 Editor - ";
	print $section[$editor], "\n\n";
	print "-"x72, "\n\n";
	open(TEX, last_abs_file($id));
	while(my $line = <TEX>) {
	    print clean_html($line);
	}
	print "</PRE>";
    }


} elsif(param("Update")) {
    my(%save_data) = ();
    my($id) = param("id");
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
	$save_data{notes} .= "[from $editor[$old_editor]]";
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

} elsif (param()) {
    (my $id  = param("id")) =~ s/\D//g;
    if(-d "$docdir/$id-W") {
	print p, "Paper $id has been withdrawn.";
    } elsif((not -d "$docdir/$id") || $id == 0) {
        print p, "Unknown paper $id.";
    } else {
	my($fieldref) = {};
	my($dataref) = {};
	$fieldref = abstract_data($id);
	$dataref = read_editor_data()->{$id};
	print_editor_header();
	print_html_abstract($id);
	print hr;

	print start_form, hidden("id", $id);
	print ($dataref->{invited} ? 
	       "<STRONG>INVITED PAPER</STRONG><BR>\n" : "");
	print "PACS: ", $fieldref->{PACS}[0][0], "<BR>\n";
	print "Contact author: ", $fieldref->{ContactAuthor}[0][0], " ",
	$fieldref->{ContactAuthor}[0][1], ", ",
	clean_html($fieldref->{Email}[0][0]), "<BR>\n";
	print p;
	print submit("Print")," Print this abstract with glyph.hut.fi (",
	"download <A HREF=\"/cgi/gimme?name=/$id.tex\">LaTeX</A> or ",
	"<A HREF=\"/cgi/gimme?name=/$id.dvi\">dvi</A>)<BR>\n";
	print submit("Edit"), " Modify the abstract contents<BR>\n";
	print "Editor: ", $editor[$dataref->{editor}], "<P>";
	print hidden("old_editor", $dataref->{editor});
	print "Abstract submitted: ", nice_date($dataref->{abssub}), "<BR>";
	print "Abstract modified by author: ", nice_date($dataref->{absre}), "<BR>";
	print "Manuscript modified: ", nice_date($dataref->{papsub}), "<P>";

	print "Session number: ",
	    textfield("session", $dataref->{session}), "<BR>";
	print "Poster number: ",
	    textfield("poster", $dataref->{poster}), "<BR>";
	print "Suggest for oral presentation:",
	checkbox_group(-name=>'oral', -value=>'1',
		       -labels=>{1=>''}, -defaults => $dataref->{oral}),
	    "<BR>";
	print "Notes: ", textfield(-name => 'notes', 
				   -default => $dataref->{notes},
				   -size => 60), "<BR>";
	print "Transfer to editor: ",
	popup_menu(-name => 'editor', -values => [1..$#editor],
		   -default => $dataref->{editor},
		   -labels => \%{{map (($_,$editor[$_]),(1..$#editor))}}),
		   "<BR>";
	print "Reject: ", checkbox_group(-name=>'reject', -value=>'1',
		       -labels=>{1=>''}, -defaults => $dataref->{reject}), p;
	print_pap_download($id);
	print p, submit("Update"), "<STRONG>Remember to update after all ",
	"changes you make to this page!</STRONG>",end_form;
    }
} else {
    print_editor_header;
}

print "\n", end_html;





