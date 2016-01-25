#!/usr/bin/perl -w

use FindBin qw($RealBin);
require "$RealBin/mail-funcs";


my($mailfile, $from, $subj) = save_mail();

send_email("", $from, "LT22 abstract submission denied",
"Sorry, abstract submission is not allowed any more. The LT22 programme
is being finalized, and no new abstracts or revised versions of old ones
are accepted.");

log_entry("mail-submit", "abs-deny", "From: $from", $mailfile);
