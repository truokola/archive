#!/usr/bin/perl

# Print the names of all authors, transposing from
# "G.W. Bush" to "Bush, G.W."
# Use with sort -u to find dupes and misspeliings.

require "common.pl";


for $id (keys %authors) {
  $str = "$authors{$id}, $speaker{$id}";
  for $auth (split (/, /,$str)) {
    if ($auth =~ /^(.+\.) ([^\.]+)$/) {
      $line = "$2, $1";
      print $line;
      print " (*)" if $2 =~ / /;
      print "\n";
    } else {
      print "xxx $auth\n";
    }
  }
}
