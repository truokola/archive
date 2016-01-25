# -*- Perl -*-

#BEGIN {
#    use CGI::Carp qw(carpout);
#    open(LOG, ">>/home/lt22/3/log/errors") ||
#              die("Unable to open log: $!\n");
#    carpout(LOG);
#}

#use Mail::Mailer;
use LockFile::Simple;
use CGI::Carp;
use File::Copy;
use File::Path;

# Relevant directories

$rootdir = "/home/lt22";
$bindir  = "$rootdir/bin";   # programs
$docdir  = "$rootdir/paper"; # contributions
$logdir  = "$rootdir/log";   # log files
$msgdir  = "$rootdir/msg";   # response messages
$tmpdir  = "$rootdir/tmp";   # temp/debugging stuff
$indir   = "$rootdir/in";    # incoming, unpacked files
$workdir = "$rootdir/work";  # for LaTeX runs

$id_prefix = "S";   # The stuff before the paper id number

umask 022;


# Get a response message from a text file and interpolate variables

sub get_message {
    local($msgcode, $id_, $pw_, $text_, $email_, $fax_,
	  $name_, $to_) = @_;
    my($message) = "";
    my(@lines); 
    $id_ = $id_prefix . $id_;
    open(MSG, "$msgdir/$msgcode") || 
      confess "can't open message $msgcode";
    @lines = <MSG>;
    close(MSG);
    for (@lines) {
        s/\$([\w]+)/${$1}/eg;
        $message .= $_;
    }
    return $message;
}


# Send an email using 'sendmail'. Default is 'mail', but my version
# seems broken, doesn't handle slashes and quotes properly.

sub send_email {
    my($from, $to, $subject, @message) = @_;
    $from ||= "LT22 Office <info\@lt22.hut.fi>";
    open (MAIL, "|-") || exec ("sendmail", "-t");
    print MAIL "From: ", $from, "\n";
    print MAIL "To: ", $to, "\n";
    print MAIL "Subject: ", $subject, "\n";
    print MAIL @message;
    close MAIL;
    open SAVE, ">$tmpdir/sent" . unique_stamp();
    print SAVE "From: $from\nTo: $to\nSubject: $subject\n\n@message";
    close SAVE;
}


# Send a response to client action via email

sub send_reply {
    my($to, $code, $type, $action, $response, @vars) = @_;
    my($subj) = response_title($type, $action, $response);
    my($message) = "Your $subj.\n";
    $message .= get_message("mail-$code", @vars);
    $message .= "\n-- \nThis is an automatically generated message\n";
    send_email("", $to, $subj, $message);
}


# Form a response title (both web and mail) based on the client action

sub response_title {
    my($type, $action, $response) = @_;
    my($title)  = "LT22 ";
    $title .= {abs => "abstract ",
	       pap => "manuscript "} -> {$type};
    $title .= {sub => "submission ",
	       re => "resubmission ",
	       wd => "contribution withdrawal "} -> {$action};
    $title .= ($response =~ /^ok/ ? "succeeded" : "failed");
    return $title;
}



sub last_abs_file {
    my($id) = shift;
    my($type) = shift || "tex";
    my($paperdir) = "$docdir/$id";
    return "" if not -d $paperdir;
    my(@dirlist) = sort {$b cmp $a} grep(/^abs\d+$/, 
					 dir_listing($paperdir));
    my($last_absfile) = "$paperdir/$dirlist[0]/abs-$id.$type";
    return "" if not -f $last_absfile;
    return $last_absfile;
}

sub last_pap_dir {
    my($id) = @_;
    my($papdir) = "$docdir/$id/pap" . last_dir_num("$docdir/$id", "pap");
    return (-d $papdir ? $papdir : "");
}


# Return the next unused paper id

sub new_id {
    lockfile("new_id", "lock");
    return basename(next_filename($docdir, "", 10000));
}


# Return a new filename in $dir which starts with $prefix and ends with
# a number one greater than the greatest before

sub next_filename {
    my($dir, $prefix, $start) = @_;
    my($last) = last_dir_num($dir, $prefix);
    return "$dir/$prefix" . ($last ? ++$last : $start);
}


sub last_dir_num {
    my($dir, $prefix) = @_;
    my($last) = "0";
    for (dir_listing($dir)) {
	if(/^${prefix}(\d+)/) {
	   $last = $1 if $1 and $1 > $last;
        }
    }
    return $last;
}

# Return a list of files in $dir, excluding dotfiles.

sub dir_listing {
    my($dir) = @_;
    opendir(LIST_DIR, $dir) ||
	confess "can't open $dir for listing: $!";
    my(@files) = grep(/^[^.]/, readdir(LIST_DIR));
    close(LIST_DIR);
    return @files;
}



# Generate a random string of lowercase letters

sub random_string {
    my($length) = @_;
    my($i) = 0;
    my($string) = "";
    $string .= chr int (rand()*26+97) while $i++ < $length;
    return $string;
}


# Withdraw a paper entry

sub withdraw_entry {
    my($id) = @_;
    rename("$docdir/$id", "$docdir/$id-W") ||
	confess "can't withdraw $id: $!";
}


# Make a timestamped log entry

sub log_entry {
    my($logfile, @loginfo) = @_;
    lockfile("log", "lock");
    open(LOG, ">>$logdir/$logfile") ||
	confess "can't open logfile $logdir/$logfile: $!";
    print LOG scalar(localtime) . " " . join(" ", @loginfo) . "\n";
    close(LOG);
    lockfile("log", "unlock");
}


# Validate the id/pw combination. 'noid' = no such id exists,
# 'wrongpw' = password wrong, '0' = ok

sub validate_pw {
    my($id, $pw) = @_;
    my($paperdir, $pass);
    $paperdir = "$docdir/$id";
    return "noid" unless -d $paperdir;
    open(FILE, "$paperdir/pass") ||
	confess "can't open passfile in $paperdir: $!";
    chomp($pass = <FILE>);
    close(FILE);
    return (lc($pw) cmp lc($pass) ? "wrongpw" : "0");
}


# Move a text file, fixing newlines from different OS's and
# determining file type

sub move_text_file {
    my($source, $dest) = @_;
    my($format) = "";
    open(OLD, $source) ||
	internal_error("cf::move_text_file::open_old", $!, @_);
    open(NEW, ">$dest") or
	internal_error("cf::move_text_file::open_new", $!, @_);
    while(<OLD>) {
	s/(\r\n|\r)/\n/g;
	print NEW;
	next if $format;
	do { $format = "latex"; next; } if /\\document(class|style)/;
        do { $format = "ps"; last; } if /%!/;
    }
    close(OLD);
    close(NEW);
    if($format eq "ps") { rename $source, $dest }
    else { unlink $source }
    return $format;
}


# Return the substring after the last slash

sub basename {
    my($filename) = @_;
    $filename =~ m!(?:\\|/)([^\\/]+)$!;
    return ($1 ? $1 : $filename);
}


# Process internal errors in this program

sub internal_error {
    my($errcode, $errtext, @args) = @_;
    chomp($errtext);
    log_entry("internal", $$, $errcode, @args, "Stderr:", $errtext);
    confess;
}


# Create a new paper entry $id

sub create_entry {
    my($id) = @_;
    my($newdir) = "$docdir/$id";
    my($pass) = random_string(5);
    mkdir $newdir, 0775 or
	internal_error("cf::create_entry::mkdir", $!, @_);
    open(FILE, ">$newdir/pass") or
	internal_error("cf::create_entry::open", $!, @_);
    print FILE $pass;
    close(FILE);
    return $pass;
}


# Check in an abstract or manuscript after TeXing

sub check_in {
    my($id, $type) = @_;
    my($newdir) = next_filename("$docdir/$id", $type, 100);
    mkdir $newdir, 0775 or
	internal_error("cf::check_in::mkdir", $!, @_);
    for (dir_listing("$workdir/$$")) {
	move("$workdir/$$/$_", "$newdir/$_");
    }
}   


# The main function for submissions

sub process_submission {
    my($id, $pw, $type, $action) = @_;
    my($response, $data) = process_subm_aux(@_);
    if($response eq "ok") {
	if($type eq "abs" && $action eq "sub") {
	    $id = $data;
	    $pw = create_entry($id);
	}
	check_in($id, $type);
	if ($type eq "abs") { save_abstract_data($id, $type . $action) }
	else { 
	    make_ps($id);
	    my $time = time();
	    save_editor_data($id, {"paplog_".$time => "sub",
			       papsub => $time});
	}
    }
    lockfile("new_id", "unlock") if lockfile("new_id", "is_locked");
    return ($response, $id, $pw, $data);
}

sub process_subm_aux {
    my($id, $pw, $type, $action) = @_;
    my($result) = "";
    my($data) = "";
    my(@files) = dir_listing("$indir/$$");
    return "nofile" unless @files;

    if($id && $pw) {
	return $result if $result = validate_pw($id, $pw);
    } elsif($type eq "abs" && $action eq "sub") {
	$id = new_id();
    } else {
	return "noinfo";
    }

    ($result, $data) = tex_it($id, $type, @files);
    return ($result, $data) if $result; 
    return ("ok", $id);
}   
	

# Return the arguments of given commands in the latest
# abstract file for entry number $id

sub abstract_data {
    my($id) = @_;
    my $file = last_abs_file($id) or return 0;
    return parse_tex_file($file);
}



# A highly simplified TeX parsing algorithm. Return arguments for
# commands listed in @$fieldref.

sub parse_tex_file {
    my($texfile) = @_;
    open(TEX, $texfile) || confess "can't open $texfile for parsing";
    
    # the number of arguments for each tex command
    my(%args) = (Title => 1, Address => 2, Speaker => 3, Author => 3,
		 PACS => 1, ContactAuthor => 2, Department => 1,
		 Institute => 1, StreetAddress => 1, PostalCode => 1,
		 City => 1, Country => 1, Email => 1, Fax => 1, Phone => 1);

    my($content) = "";
    my($line) = "";
    my(%ret) = ();
    my $continue = 0;
    my $speakerpos = -1;

  MAIN_LOOP: 
    while($continue or $line = <TEX>) {
	$continue = 0;
        next unless $line =~ /^(?:\\%|[^%])*?\\(\w+)\s*/g;
	my($command) = $1;
        next unless $args{$command}; # skip unwanted commands
	my($nesting) = 0;
	my($arg_idx) = 0;
	$content = "";

	while($line =~ /((?:\\%|\\{|\\}|.)*?)(}|{|%|$)/g) {
	    $content .= $1;

	    if ($2 eq "}") {
		if (--$nesting == 0) { # argument complete
		    $field_idx = $#{$ret{$command}};
		    $field_idx++ if $arg_idx == 0;
		    if (($command eq "Speaker" || $command eq "Author") &&
			$arg_idx == 2) {
			$content = remove_kluge($content);
			$speakerpos++;
			$ret{speakerpos} = $speakerpos if $command eq "Speaker";
		    }
		    $ret{$command}[$field_idx][$arg_idx] = 
			clean_wspace($content);
		    $content = "";
		    if (++$arg_idx == $args{$command}) {
			$line = $';
			$continue = 1;
			next MAIN_LOOP;
		    }
		} else { # brace is part of the argument
		    $content .= "}";
		}

	    } elsif ($2 eq "{") { # nest one level deeper
		$content = ($nesting++ == 0 ? "" : $content . "{");

	    } else { # we encountered a comment or a newline
		$content .= " ";
		$line = <TEX> or return {}; # runaway argument
	    }

	} # inner while
	  
    } # MAIN_LOOP

    return \%ret;
}	


# Since our style file doesn't allow authors to have multiple affiliations,
# they use some kluges (\footnote{} and $^b,$) in the \Speaker or \Author
# fields to get around that.

sub remove_kluge {
    my($string) = @_;
    $string =~ s/\$.*?\$//g;
    $string =~ s/\\footnote\{.*\}//g;
    return $string;
}


# Yet another TeX parser. Return the abstract text body.

sub abstract_body {
    my($id, $command) = @_;
    my($body) = "";
    open(TEX, last_abs_file($id)) || confess "can't open abstract $id: $!";
    while(<TEX>) {
	if (not $body) {
	    next unless 
		/^(?:\\%|[^%])*\\BeginAbstract\s*((?:\\%|.)*?)($|%)/;
	    $body .= $1 . " ";
	} else {
	    /^((?:\\%|.)*?)(\\EndAbstract|%|$)/;
	   $body .= $1 . " ";
	   last if $2 eq "\\EndAbstract";
        }
    }
    return clean_wspace($body);
}



# Check whether a paper is invited. A third TeX parser. :-(

sub is_marked_invited {
    my($id) = @_;
    my($invited) = 0;
    open(TEX, last_abs_file($id)) || confess "can't open abstract $id: $!";
    while (not $invited) {
	$_ = <TEX> || last;
	$invited++ if /^[^%]*\\InvitedPaper/;
    }
    close(TEX);
    return $invited;
}



# Delete all extra whitepace from string.

sub clean_wspace {
    my($string) = @_;
    for ($string) {
	s/\s+/ /g;
	s/^\s+//;
	s/\s+$//;
    }
    return $string;
}



# Find the first line starting with a backslash, i.e., kill greetings etc.
# from the beginning of text. Return the first matching line for further
# examination.

sub strip_head {
    my($oldfile, $newfile) = @_;
    my($line) = "";
    my($firstline) = "";
    open(OLD, "$oldfile") || confess "can't open $oldfile for reading: $!";
    open(NEW, ">$newfile") || confess "can't open $newfile for writing: $!";
  READWRITE: {
	do {
	    # if no line begins with '\', the tex file is malformed
	    last READWRITE if not defined ($line = <OLD>);
	} until ($line =~ /^\s*\\/);
	$firstline = $line;
	do {
	    print NEW $line;
	    last READWRITE if $line =~ /^[\\%|^%]*\\end\s*\{document\}/;
	    $line = <OLD>;
	} while defined $line;
    } # READWRITE
    close(OLD);
    close(NEW);
    unlink $oldfile;
    return $firstline;
}



# Create a lockfile for serial access. Steal the lock if it's older than
# 20 secs, die after trying for 30 secs.

sub lockfile {
    my($lockname, $action) = @_;
    my($lockfile_name) = "$tmpdir/$lockname.lock";
    return -f $lockfile_name if $action eq "is_locked";
    my($locker) = LockFile::Simple->make(-delay => 1, -hold => 15,
					 -max => 60, -ext => '');
    $locker->$action($lockfile_name) || confess "can't $action $lockname";
}


# The main function for withdrawals

sub process_withdrawal {
    my($id, $pw) = @_;
    my($result) = "";
    my($email) = "";

    if($id && $pw) {
	return $result if $result = validate_pw($id, $pw);
	$email = abstract_data($id)->{Email}[0][0];
	withdraw_entry($id);
	save_editor_data($id, {withdrawn => 1});
	return ("ok-wd", $email);
    } else {
	return "noinfo";
    }
}

# Produce a unique string of the form 'time.pid'. NOT unique over
# NFS, must add hostname. Watch out for the y2k bug. :-)

sub unique_stamp {
    join("", map(($_ < 10 ? "0" : "") . "$_",
		 (localtime(time))[5,4,3,2,1,0])) . ".$$";
}


sub tex_it {
    my($id, $type) = @_;
    my($working) = "$workdir/$$";
    my($texfile) = "";
    my($new_texfile) = "";
    my($firstline) = "";
    my($logfile) = "";
    my(@logtext) = "";
    my($logtext) = "";
    my($errormsg) = "No messages";
    my($result) = "";
    my(@ps_files) = ();
    rmtree $working, 0, 0;
    mkpath $working, 0, 0755;
    if ($type eq "pap" && (my $papdir = last_pap_dir($id))) {
	for my $file (dir_listing($papdir)) {
	    next if ($file =~ /^pap-$id/ || $file =~ /pstill\.log/);
	    link "$papdir/$file", "$working/$file";
	}
    }
    for (dir_listing("$indir/$$")) {
	my($newname) = "$working/$_";
	my($type) = move_text_file("$indir/$$/$_", $newname);
	if($type eq "latex") {
	    return "2many" if $texfile;  # more than 1 texfile
	    $texfile = $newname;
	} elsif($type eq "ps") {
	    push @ps_files, basename($newname);
	} else {   # reject if not ps or latex
	    unlink $newname;
	}
    }
    return "notex" if not $texfile;
    $new_texfile = "$working/$type-$id.tex"; 
    $firstline = strip_head($texfile, $new_texfile);
    return "nolt" if $type eq "abs" and 
	not $firstline =~ /^\s*\\documentstyle\s*\[LTabs\]\s*{article}/;
    $texfile = $new_texfile;
    chdir $working;
    if(@ps_files) {  # try to correct problems with case-insensitive OS's
	my(@ps_names) = ();
	open(TEX, $texfile);
	while(<TEX>) {   # find all references to .(e)ps files
	    push @ps_names, $1 while /([\w-+]+\.e?ps)/gi;
	}
	close(TEX);
	for my $orig (@ps_files) {
	    for my $new (@ps_names) {
		if(lc($orig) eq lc($new)) { 
		    rename $orig, $new if $orig ne $new;
		    last;
		}
	    }
	}
    }
    $result = system("latex $texfile </dev/null >/dev/null 2>&1");
    if($result == 0) {
	$result = system("latex $texfile </dev/null >/dev/null 2>&1");
	return 0 if $result == 0;
    }
    $texfile =~ /(.*)\.tex$/;
    $logfile = $1 . ".log";
    open(FILE, $logfile) or return ("texfail", $errormsg);
    @logtext = <FILE>;
    close(FILE);
    $logtext = join("", @logtext);
    $errormsg = $1 if $logtext =~ /(\n! .*?\n(?:\?|!))/s; ##### perl bug
    return ("texfail", $errormsg);
}

# Corrects '<', '>' and '&' for html

sub clean_html {
    my($text) = @_;
    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    return $text;
}


sub pacs_to_editor {
    my($pacs) = @_;
    my($maj) = my($min) = 0;
    $maj = $1 if $pacs =~ /(\d+)/g;
    $min = $1 if $pacs =~ /(\d+)/g;
    return 2 if $maj == 74;
    return 1 if $maj == 3 || $maj == 47 || $maj == 67 ||
	($maj == 68 && ($min <= 18 || $min == 45));
    return 4 if $maj == 72 || $maj == 73 || ($maj == 61 &&
					     ($min == 46 || $min == 48));
    return 3 if $maj >= 60 && $maj <= 79;
    return 5;
}


sub save_editor_data {
    my($id, $dataref) = @_;
    lockfile("editor", "lock");    
    open(DATA, ">>$logdir/editor-data") || confess "can't open editor-data: $!";
    print DATA ":$id\n";
    for (keys %$dataref) {
	print DATA "$_:$dataref->{$_}\n";
    }
    close(DATA);
    lockfile("editor", "unlock");
}


sub read_editor_data {
    my($id) = 0;
    my(%data) = ();
    if(open(DATA, "$logdir/editor-data")) {
	while(<DATA>) {
	    chomp;
	    next unless /(.*?):(.*)/;
	    if($1) {
		$data{$id}->{$1} = $2;
	    } else {
		$id = $2;
		$data{$id}->{id} = $id;
	    }
	}
	close(DATA);
    } else { return 0 }
    return \%data;
}


sub html_abstract {
    my($id) = @_;
    my(%addr_tags) = ();
    my(%addresses) = ();
    my($num_addresses) = 0;
    my($fieldref) = {};
    my $abs = "";
    $fieldref = abstract_data($id);
    $num_addresses = $#{$fieldref->{Address}} + 1;
    my $spos = $fieldref->{speakerpos};
    my @authors = @{$fieldref->{Author}};
    splice (@authors, $spos, 0, @{$fieldref->{Speaker}});
    $abs .= "<H3>" . clean_html($fieldref->{Title}[0][0]) . "</H3>\n<P>";
    for my $pos (0..$#authors) {
	$abs .= ($pos > 0 ? ", " : "");
	$abs .= ($pos == $spos ? "<U>" : "");
	$addr_tags{$authors[$pos]->[0]} = chr($#{[keys %addr_tags]} + 98) if
	    not $addr_tags{$authors[$pos]->[0]};
	$abs .= flatten_name($authors[$pos]->[1] . " " . $authors[$pos]->[2]) .
	    ($pos == $spos ? "</U>" : "") .
	    ($num_addresses == 1 ? "" : " [$addr_tags{$authors[$pos]->[0]}]");
    }
    $abs .= "\n\n<P>";
    for (@{$fieldref->{Address}}) {
	$addresses{$addr_tags{$$_[0]}} = flatten_latex($$_[1]);
    }
    for (sort keys %addresses) {
	$abs .= ($num_addresses == 1 ? "" : "[$_] ");
	$abs .= "$addresses{$_}<BR>\n";
    }
    $abs .= "\n<P>", clean_html(abstract_body($id)), "\n\n";
}


sub save_abstract_data {
    my($id, $subm_type) = @_;
    my($abs) = abstract_data($id);
    my($ed) = read_editor_data()->{$id};
    $abs->{PACS}[0][0] =~ /^\s*(\S+?)(?:,|;|\s|$)/;
    my($pacs) = $1;
    my($editor) = $ed->{editor} || pacs_to_editor($pacs);
    my($notes) = $ed->{notes};
    $notes .=  " [" . {abssub => 'new', absre => 'updated',
		      papsub => 'manuscript', 'editor-re' => 'edited'
		      }->{$subm_type} . "]";
    my $speaker = (flatten_name($abs->{Speaker}[0][2]) . ", " .
				flatten_name($abs->{Speaker}[0][1]));
    my $reg = (speaker_registered($speaker) ? "x" : "");
    save_editor_data($id, {editor => $editor,
			   title => $abs->{Title}[0][0],
			   speaker => $speaker,
			   pacs => $pacs,
			   invited => is_marked_invited($id),
			   $subm_type => time(),
			   r => $reg,
			   notes => $notes});
}


sub speaker_registered {
    my($speaker) = @_;
    $speaker =~ /(.*?), (.)/;
    my $sp_last  = lc($1);
    my $sp_first = lc($2);
    my $regd = 0;
    open DATA, "$logdir/reg_base";
    while(<DATA>) {
        my ($last, $first, $country, $email) = split /\t/;
        do { $regd++; last } if ($sp_last eq lc($last) &&
				 $sp_first eq lc(substr($first, 0, 1)));
    }
    close DATA;
    return $regd;
}

sub make_ps {
    return if fork() != 0;
    my($id) = @_;
    my($papdir) = last_pap_dir($id);
    open(STDOUT, ">/dev/null");
    open(STDERR, ">/dev/null");
    chdir $papdir;
    system("/usr/bin/dvips", "-Ppdf", "-o/lt22/ps/$id.ps", "pap-$id.dvi");
#    open STDOUT, ">pstill.log";
#    system("/usr/bin/pstill", "-cipt", "-opap-$id.pdf", "pap-$id.ps");
#    close STDOUT;
#    open PST, "pstill.log";
#    while(<PST>) {
#	if (/^PStill:/) {
#	    log_entry("pstill", $id);
#	    unlink "$papdir/pap-$id.pdf";
#	    last;
#	}
#    }
#    close PST;
    exit;
}

@flat_iso = qw(A A A A A A A C
	       E E E E I I I I
	       D N O O O O O *
	       O U U U U Y D ss
	       a a a a a a a c
	       e e e e i i i i
	       d n o o o o o /
	       o u u u u y d y);


sub flatten_iso {
    my($string) = @_;
    $string =~ 
	s/([\300-\377])/$flat_iso[(ord $1) - 0300]/eg;
    return $string;
}

sub flatten_latex {
    my($string) = @_;
    for ($string) {
	s/\\[\'\"\`\.^~=vc] *//g;
        s/\\(i|I|o|O|ss) */$1/g;
	s/\\AA */A/g;
	s/\\aa */a/g;
        s/(}|{)//g;
	s/~/ /g;
	s/\\\S+\s*//g;
	s/\s+/ /g;
    }
    return flatten_iso($string);
}

sub flatten_name {
    my($string) = @_;
    $string = flatten_latex($string);
    $string =~ s/[^A-Za-z \-\.,]//g;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}


1;
