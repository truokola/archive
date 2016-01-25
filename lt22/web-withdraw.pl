#!/usr/bin/perl

do "/home/lt22/bin/web-funcs";

my($cgi_file, %cgi_data, %cgi_sfn, %cgi_ct, %cgi_sfn);
my($id, $pw, $email, $response, $hostinfo);

# Remote host info for logs
$hostinfo = "Host: $ENV{'REMOTE_HOST'} [$ENV{'REMOTE_ADDR'}]";

lockfile("process", 1);

# Parse the CGI data
$cgi_file = save_cgi_data();
ReadParse($cgi_file, \%cgi_data,\%cgi_cfn,\%cgi_ct,\%cgi_sfn);

($id = $cgi_data{'idnum'}) =~ s/\D+//g;    # remove non-digits
($pw = $cgi_data{'password'}) =~ s/\s+//g; # remove spaces

$email = abstract_data("$id", "Email");

$response = process_withdrawal($id, $pw);
lockfile("process", 0);

if($response eq "ok-wd") {
    send_reply($email, "web-$response", "", "wd", $response, $id, $pw);
}

show_page($response, "", "wd", $response, $id, $pw, "", $email);
log_entry("web-withdraw", $response, $hostinfo, $id, $pw, $cgi_file);
