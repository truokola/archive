#!/usr/bin/perl

# Generate the latex code for the program leaflet

require "common.pl";
require "common2.pl";

$cnt = "001";
for $sess (0..14) {
  for $n (1..$last_oral[$sess]) {
    $id = ${$talkid[$sess]}[$n];
    if($speaker{$id} =~ /(.*\.) ([^\.]+)/) {
      print "$cnt:$2 $1 [$sess.$n]:$sess/$sess\_$n\_$2\n";
      $cnt++;
    }
  }
}
