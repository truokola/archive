#!/usr/bin/perl

# Generate a text list of the final sessions

require "common.pl";
require "common2.pl";


# Print the lines for oral session $sess
sub print_oralsess {
  return unless $oralsess_name[$sess];
  print "$sess. $oralsess_name[$sess] (pj. $chairman[$sess], $affil[$sess]), $location[$sess]\n\n";

  for $n (1..$last_oral[$sess]) {
    $id = ${$talkid[$sess]}[$n];
    print "[$id] $sess.$n  $time{$id}  $speaker{$id}: $titletex{$id}\n";
  }
  print "\n\n";
}


# Print the lines for poster session $sess
sub print_postsess {
  return unless $postsess_name[$sess];
  print "$sess. $postsess_name[$sess]\n\n";

  return unless $first_post[$sess] > 0;

  for $n ($first_post[$sess]..$#{$talkid[$sess]}) {
    $id = ${$talkid[$sess]}[$n];
    print "[$id] $sess.$n  $speaker{$id}: $titletex{$id}\n";
  }
  print "\n\n";
}

for $sess (0..$#oralsess_name) {
  print_oralsess;
  print_postsess;
}
