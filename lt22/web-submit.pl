#!/usr/bin/perl

use FindBin qw($RealBin);
require "$RealBin/web-funcs";
use File::Path;
#use strict;

my($cgi_file, %cgi_data, %cgi_sfn, %cgi_ct, %cgi_cfn);
my($id, $pw, $type, $action, $response, $text, $email, $hostinfo);
my(%subm_type) = ('a' => 'abs', 'p' => 'pap', 's' => 'sub', 'r' => 're',
		  'w'=> 'wd');

# Remote host info for logs
$hostinfo = "Host: $ENV{'REMOTE_HOST'} [$ENV{'REMOTE_ADDR'}]";

# Determine what to do based on the name of the cgi symlink.
($action, $type) = map $subm_type{substr($_, 0, 1)}, split '-', basename($0);

$cgi_file = save_cgi_data();

# Parse the CGI data
ReadParse($cgi_file, \%cgi_data,\%cgi_cfn,\%cgi_ct,\%cgi_sfn);

$id = $pw = $text = $email = "";
($id = $cgi_data{'idnum'}) =~ s/\D+//g;    # remove non-digits
($pw = $cgi_data{'password'}) =~ s/\s+//g; # remove spaces

if($action eq "wd") {
    ($response, $email) = process_withdrawal($id, $pw);

    if($response eq "ok-wd") {
	send_reply($email, "web-$response", "", "wd", $response, $id, $pw);
    }

    $code = $response;

} else {

# Move and rename uploaded files to incoming, deleting empty ones
    my($incoming) = "$indir/$$";
    rmtree $incoming, 0, 0;
    mkpath $incoming, 0, 0755;

    for (keys %cgi_sfn) {
	my($oldname) = $cgi_sfn{$_};
	do {unlink $oldname; next;} if -z $oldname;
	my($newname) = $cgi_cfn{$_};
	$newname = "$incoming/" . ($newname ? basename($newname) : 
				   next_filename($indir, "file", 1000));
	rename $oldname, $newname;
    }

    ($response, $id, $pw, $text) =process_submission($id, $pw, $type, $action);

    $code = $response;
    if($code eq "ok") {
	$code .= "-$type-$action";
	$email = abstract_data($id)->{Email}[0][0];;
	if($type eq "abs" and $action eq "sub") {
	    $text = abstract_data($id)->{Title}[0][0];;
	} else {
	    $text = last_dir_num("$docdir/$id", $type) - 99;
	}
	send_reply($email, "web-$code", $type, $action, $response,
		   $id, $pw, $text, $email);
    }
}

show_page($code, $type, $action, $response, $id, $pw, 
	  clean_html($text), clean_html($email));
log_entry("web-submit", $code, $hostinfo, "$type-$action", $id, $pw,
	  $cgi_file);
