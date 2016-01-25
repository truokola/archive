do "/home/lt22/bin/common-funcs";
use POSIX;

$f = read_editor_data();
for my $id (sort keys %{$f}) {
  my $p = $f->{$id};
  next if $p->{withdrawn};
  next if $p->{invited};
  next if $p->{r};
  print ++$nummer, ": $id";
  my $a = abstract_data($id);
  my $to = $a->{Email}[0][0];
  my $author = $a->{ContactAuthor}[0][0] . " " . $a->{ContactAuthor}[0][1];
  my $subject = "LT22 Abstract $id_prefix$id";
  my $pw = get_password($id);
  
  my $msg = "Dear $author,\n\n";
  $msg .= get_message("mail-editor-reg", $id, $pw) .
    "\nWith kind regards,\n\nLT22 Editors\n\n";

  $msg .= "-"x70 . "\n\nAbstract Information\n\nPaper-id: $id_prefix$id\n" .
    "Password: $pw\nTitle: " . $p->{title} .
      "\nSubmitted: " . nice_date($p->{absre} || $p->{abssub}) .
	"\n\n" . "-"x70 . "\n\n";

  $msg .= raw_abstract_text($id);

#  print "To: $to\nSubject: $subject\n\n\n$msg\n\n\n\n\n\n\n";
  send_email($to, $subject, $msg);
  print " : OK\n";
}

sub get_password {
    my($id) = @_;
    my $pw = "";
    return "" if (($id == 0) || (! -d "$docdir/$id") ||
		  (! open(PASS, "$docdir/$id/pass")));
    chomp($pw = <PASS>);
    close(PASS);
    return $pw;
}

sub nice_date {
    my $time = shift or return "";
    return strftime("%b %d, %Y", localtime($time));
}
sub raw_abstract_text {
    my($id) = @_;
    my $file = last_abs_file($id) or return "";
    open(TEX, last_abs_file($id)) or return "";
    my(@lines) = <TEX>;
    close(TEX);
    my $abs_text = join "", grep(!/^\s*%/, @lines);
    return $abs_text;
}
