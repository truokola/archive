# -*- Perl -*-

use FindBin qw($RealBin);
use CGI::Carp;
use File::Path;
do "$RealBin/common-funcs";
require "cgi-lib-lt.pl";


# Spool the files to $tmpdir
$cgi_lib::writefiles = $tmpdir;   


# Limit upload size
$cgi_lib::maxdata = 25_000_000;


sub save_cgi_data {
    my($cgifile) = "$tmpdir/cgi" . unique_stamp();
    open(SAVE, ">$cgifile") or confess "can't open $cgifile for writing: $!";
    print SAVE <STDIN>;
    close(SAVE);
    return $cgifile;
}


sub show_page {
    my($code, $type, $action, $response, @vars) = @_;
    my($title) = response_title($type, $action, $response);
    $message = get_message("html-$code", @vars);
    print_html_page($title, $message);
}

sub print_html_page {
    my($title, $message) = @_;

    print <<EOT;
Content-type: text/html

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
        "http://www.w3.org/TR/REC-html40/loose.dtd">
<HTML>
<HEAD>
<TITLE>$title</TITLE>
</HEAD>
<BODY BGCOLOR="#FFFFFF">
<H1>$title</H1>

$message

</BODY>
</HTML>
EOT
}



