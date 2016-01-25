#!/usr/bin/perl

# Generate the latex code for the program leaflet

require "common.pl";
require "common2.pl";


# Print the lines for oral session $sess
sub print_oralsess {
  return unless $oralsess_name[$sess];
  print "\\subsubsection*{$sess.~$oralsess_name[$sess]\{\\normalfont, $location[$sess] (pj.~$chairman[$sess])}}\n";
#  print "\\subsubsection*{$sess.~$oralsess_name[$sess], $location[$sess] (pj.~$chairman[$sess], $affil[$sess])}\n";
  print "\\begin{longtable}{\@{}p{$oral1}\@{}p{$oral2}p{$oral3}}\n";

  for $n (1..$last_oral[$sess]) {
    $id = ${$talkid[$sess]}[$n];
    print " $time{$id} \\hfill &\\hfill {$sess.$n} &  \\rright $speaker{$id}: $titletex{$id}\\\\\n";
  }

  print "\\end{longtable}\n";
}


# Print the lines for poster session $sess
sub print_postsess {
  return unless $postsess_name[$sess];
  print "\\subsubsection*{$sess.~$postsess_name[$sess]}\n";

  return unless $first_post[$sess] > 0;

  print "\\begin{longtable}{\@{}p{$post1}\@{}p{$post2}p{$post3}}\n";
  for $n ($first_post[$sess]..$#{$talkid[$sess]}) {
    $id = ${$talkid[$sess]}[$n];
    print "&\\hfill {$sess.$n} & \\rright $speaker{$id}: $titletex{$id}\\\\\n";
  }

  print "\\end{longtable}\n";
}

# Print an external TeX file fragment and substitute the text "#var#" with
# the contents of the variable $var
sub print_ext_file {
  open(TEX, shift);
  while (<TEX>) {
    s/::([\w]+)::/${$1}/eg;
    print;
  }
  close(TEX);
}


$head1 = "0mm";
$head2 = "22mm";
$head3 = "125mm";

$oral1 = "12mm";
$oral2 = "10mm";
$oral3 = "125mm";

$post1 = "0mm";
$post2 = "22mm";
$post3 = "125mm";

$tablehead = "\@{}p{$head1}\@{}p{$head2}p{$head3}";
$oral_title = "\\subsection*{RINNAKKAISISTUNNOT}\n";
$poster_title = "\\subsection*{POSTER-ISTUNTO}\n";
print_ext_file("./data/part_1.tex");

print $oral_title;
for $sess (1..5) {
  print_oralsess;
}

print $poster_title;
for $sess (1..5) {
  print_postsess;
}

print_ext_file("./data/part_2.tex");

print $oral_title;
for $sess (6..9) {
  print_oralsess;
}

print $poster_title;
for $sess (6..14) {
  print_postsess;
}

print_ext_file("./data/part_3.tex");

print $oral_title;
for $sess (10..14) {
  print_oralsess;
}

print_ext_file("./data/part_4.tex");
