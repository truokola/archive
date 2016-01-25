#!/usr/bin/perl -w

use FindBin qw($RealBin);
require "$RealBin/mail-funcs";


my($mailfile, $from, $subj) = save_mail();
my($id, $pw) = split_subject($subj);
my($type, $action, $response, $text, $code);

process_body($mailfile);

$text = "";

$type = shift @ARGV;
$action  = "sub";
$action  = "re" if $id and $pw and $type eq "abs";

($response, $id, $pw, $text) = process_submission($id, $pw, $type, $action);

$code = $response;
if($code eq "ok") {
    $code .= "-$type-$action";
    if($type eq "abs" and $action eq "sub") {
	$text = abstract_data($id)->{'Title'}[0][0];
    } else {
	$text = last_dir_num("$docdir/$id", $type) - 99;
    }
}

send_reply($from, $code, $type, $action, $response, $id, $pw, $text);
log_entry("mail-submit", $code, "From: $from",
	  "$type-$action", $id, $pw, $mailfile);
