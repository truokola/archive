#!/usr/bin/perl

# Print a LaTeX listing with the abstract titles sorted
# according to the preliminary sessions

require "common.pl";

# Counter for the total abstract number
$total = 0;

# Counter for the abstracts in one session
$cnt = 0;



# Print the abstract line
sub print_line {
  $cnt++;
  $total++;
  print "$cnt & {\\bf $id} & $speaker{$id}: $titletex{$id}\\\\\n";
}


# TeX preamble
print "\\documentclass[a4paper]{article}\n";
print "\\usepackage{longtable}\n";
print "\\usepackage[latin1]{inputenc}\n";
print "\\setlength{\\voffset}{-25mm}\n";
print "\\setlength{\\oddsidemargin}{-5mm}\n";
print "\\setlength{\\evensidemargin}{-5mm}\n";
print "\\setlength{\\textheight}{250mm}\n";
print "\\pagestyle{empty}\n";
print "\\begin{document}\n";
print "\\setcounter{section}{-1}\n"; # first section is 0


# Iterate over all sessions
for $n (0..$#sessname) {
  print "\\section{$sessname[$n]}\n";

  # First oral abstracts...
  print "\\subsection{Oral}\n";
  print "\\begin{longtable}{rrp{15cm}}\n";
  $cnt = 0;
  for $id (sort keys %session) {
    print_line if $session{$id} == $n and $oral{$id};
  }
  print "\\end{longtable}\n";

  # ...then posters
  print "\\subsection{Poster}\n";
  print "\\begin{longtable}{rrp{15cm}}\n";
  $cnt = 0;
  for $id (sort keys %session) {
    print_line if $session{$id} == $n and not $oral{$id};
  }
  print "\\end{longtable}\n";
}


print "{\\bf GRAND TOTAL: $total}\n";
print "\\end{document}\n";
