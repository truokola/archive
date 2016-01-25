#!/usr/bin/perl -w

use FindBin qw($RealBin);
require "$RealBin/mail-funcs";

my($type, $filedir, $subj, @files, @text);
my($mailfile, $from) = save_mail();

$type = $ARGV[0];

# $filedir contains the requested files
$filedir = "$rootdir/request/$type";
@files = dir_listing($filedir);

for (@files) {
    $subj = $_;
    /^HEADER/ and $subj = "LT22 file request";
    open(FILE, "$filedir/$_") or
	internal_error("rq::open", $!, $mailfile);
    @text = <FILE>;
    close(FILE);
    send_email("", $from, $subj, join("", @text));
}

log_entry("request", $type, "From: $from", $mailfile); 

