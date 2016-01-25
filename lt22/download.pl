#!/usr/bin/perl

use CGI qw(:standard);
use FindBin qw($RealBin);
require "$RealBin/common-funcs";

my %mime_types = (jpg => "image/jpeg",
		  ps  => "application/postscript",
		  pdf => "application/pdf",
		  tex => "text/plain");

sub not_found {
    print header, start_html, p, "Not found.", end_html;
    exit;
}

if (my $name = path_info()) {
    not_found() unless $name =~ m!/(\d+)\.(jpg|ps|pdf|tex|/)!i;
    my $id = $1;
    my $type = lc($2);
    my $post = $';
    my $file = "";
    if ($type eq "/") {
	my $papdir = last_pap_dir($id) or not_found();
	$file = "$papdir/$post";
	$type = "ps";
    } elsif ($type eq "jpg") {
	$file = abstract_jpeg($id);
    } elsif ($type eq "ps") {
	$file = "/lt22/ps/$id.ps";
    } elsif ($type eq "pdf") {
	$file = "/lt22/pdf/$id.pdf";
    } else {
	$file = last_pap_dir($id) . "/pap-$id.$type";
    }
    open(FILE, $file) or not_found();
    print header(-type => $mime_types{$type},
		 -content_length => (stat FILE)[7]);
    print STDOUT <FILE>;
    close(FILE);
    
} else { not_found() }

sub abstract_jpeg {
    my($id) = @_;
    my $abs_dir  = "$docdir/$id/abs" . last_dir_num("$docdir/$id", "abs");
    my $pub_name = "abs-public";
    chdir $abs_dir;
    return "$abs_dir/$pub_name.jpg" if -f "$pub_name.jpg";
    symlink "/usr/share/texmf/tex/latex/misc/LTabs-public.sty", "LTabs.sty";
    symlink "abs-$id.tex", "$pub_name.tex";
    if (fork==0) {
	open STDOUT, "/dev/null";
	open STDERR, "/dev/null";
	system("/usr/bin/latex", $pub_name);
	unlink "LTabs.sty";
	system("/usr/bin/dvips", "-o$pub_name.ps", "$pub_name.dvi");
	system("/usr/X11R6/bin/convert", "-crop", "0x0", "-density", "98x98",
	       "$pub_name.ps", "$pub_name.jpg");
	exit;
    }
    wait;
    return "$abs_dir/$pub_name.jpg";
}
