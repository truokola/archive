#!/usr/bin/perl -w

use FindBin qw($RealBin);
require "$RealBin/mail-funcs";

my($mailfile, $from, $subj) = save_mail();
my($id, $pw) = split_subject($subj);
my($response) = "";

($response) = process_withdrawal($id, $pw);

send_reply($from, $response, "", "wd", $response, $id, $pw);
log_entry("mail-withdraw", $response, "From: $from", $id, $pw, $mailfile);
