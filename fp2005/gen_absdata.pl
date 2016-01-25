#!/usr/bin/perl
$absdir = "www/data/abs";
$id = 1000;

open(SEQ, "$absdir/seq");
$last_id = <SEQ>;
close(SEQ);

while ($id <= $last_id) {
  $file = "$absdir/$id.data";
  if (-e $file) {
    open (DATA, $file);
    while($line = <DATA>) {
      if ($line eq "prestype: poster\n") { # relic of evolution...
	$line = "oral: 0\n";
      } elsif ($line eq "prestype: oral\n") {
	$line = "oral: 1\n";
      }
      print "$id:$line";
    }
    close(DATA);
  }
  $id++;
}
