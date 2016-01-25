# -*- Perl -*-

use CGI::Carp;
use File::Path;
require "/home/lt22/bin/common-funcs";


# Save the mail message from stdin into a file, return From: and
# Subject:. If the header is multiline, returns only the first line.
# Correcting that is not worth the trouble.

sub save_mail {
    my($mailfile) = "";
    my($from) = "";
    my($subj) = "";
    my($no_more_headers) = "";
    $mailfile = "$tmpdir/mail" . unique_stamp();
    open(FILE, ">$mailfile") || 
	confess "can't open $mailfile for saving: $!";
    while(<STDIN>) {
	print FILE;
        next if $no_more_headers;
	chomp($_);
	$no_more_headers = not $_;  # an empty line end headers
	$from = $1 if /^From:\s*(.*?)\s*$/i;
	$subj = $1 if /^Subject:\s*(.*?)\s*$/i;
    }
    close(FILE);
    confess "no From: in $mailfile" if not $from;   # no From: ?!
    return($mailfile, $from, $subj);
}
	

# Split the subject line into id and password

sub split_subject {
    my($subj) = @_;
    $subj =~ /$id_prefix(\d+)(?:\s|_|,|:|-|;)*([A-Za-z]+)/i;
    return($1, $2);
}


# Process the whole message with 'metamail'.

sub process_body {
    my($mailfile) = @_;
    my($incoming) = "$indir/$$";
    rmtree $incoming, 0, 0;
    mkpath $incoming, 0, 0755;
    $ENV{"METAMAIL_TMPDIR"} = $incoming;
    system("metamail -d -w $mailfile > /dev/null 2>&1");
    confess "metamail failed with $mailfile" if $? != 0;
} 

1;
