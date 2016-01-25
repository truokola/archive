#!/usr/bin/perl

require "common.pl";
require "common2.pl";

@oldsess = ([1],   [2],  [3], [4,10], [5], [6],  [7],    [8],    [9]);
@newsess = ([1,8], [10], [6], [7]   , [2], [14], [9,13], [3,12], [4,5,11]);


for $set (0..$#oldsess) {
  next unless $last_oral[$newsess[$set][0]] > 0;
  print "From (", join(",",@{$oldsess[$set]});
  print ") to (", join(",",@{$newsess[$set]}), ")\n";

  %old = ();
  %new = ();
  for $sess (@{$oldsess[$set]}) {
    for $id (keys %session) {
      $old{$id} = 1 if $session{$id} == $sess;
    }
  }

  for $sess (@{$newsess[$set]}) {
    for $n (1..$#{$talkid[$sess]}) {
      $id = $talkid[$sess][$n];
      print "    Duplicate new: $id\n" if $new{$id};
      $new{$id} = 1;
      print "        Extra new: $id\n" if not $old{$id};
    }
  }

  for $id (keys %old) {
    print "      Missing old: $id\n" if not $new{$id};
  }
}
