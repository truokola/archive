#!/usr/bin/perl

# Print a text listing with the abstract titles sorted
# according to the preliminary sessions

require "common.pl";

# Maximum length of one line
$maxlen = 67;

# Counter for the total abstract number
$total = 0;



# Print the abstract line
sub print_line {
  $total++;
  $full = "$id $speaker{$id}: $titletex{$id}";
  @words = split / +/, $full;
  $line = shift @words;
  $word = shift @words;
  # Make sure the line is not longer than $maxlen (before adding "...")
  while (($word ne '') and (length($line) + length($word) < $maxlen))
    {
      $line .= " $word";
      $word = shift @words;
    }
  print $line;
  print "..." if $word ne '';
  print "\n";
}

# Iterate over all sessions
for $n (0..$#sessname) {
  print "\n\n\n********** $sessname[$n] **********\n\n";
  # First oral abstracts...
  print "Oral\n\n";
  for $id (sort keys %session) {
    print_line if $session{$id} == $n and $oral{$id};
  }
  # ...then posters
  print "\nPoster\n\n";
  for $id (sort keys %session) {
    print_line if $session{$id} == $n and not $oral{$id};
  }

}

print "\nGRAND TOTAL: $total\n";
