#!/usr/bin/perl

# Generate the web pages for the conference program

require "common.pl";
require "common2.pl";

$html_top = "<?php\n\$pagetitle = \"Ohjelma\";\ninclude(\"top.php\");\n?>\n";
$html_bot = "<?php\ninclude(\"bottom.php\");\n?>\n";
$not_ready = "<p>Ohjelma ei ole vielä valmis.</p>\n";

# Print the lines for oral session $sess
sub print_oralsess {
  return unless $oralsess_name[$sess];
  print "<h3><a name=\"$sess\">";
  print "$sess. $oralsess_name[$sess] (pj. $chairman[$sess], $affil[$sess]), $location[$sess]";
  print "</a></h3>\n";

  if ($last_oral[$sess] > 0){
    print "<p>[<a href=\"pdf/sessio_$sess.pdf\">sessio-pdf</a>]</p>\n";
    print "<table cellpadding=\"6\" cellspacing=\"0\" border=\"0\">\n";

    for $n (1..$last_oral[$sess]) {
      $id = ${$talkid[$sess]}[$n];
      print "<tr><td valign=\"top\">$time{$id}</td><td valign=\"top\"><b>$sess.$n</b></td><td>$speaker{$id}:\n";
      print "<a href=\"pdf/abs$id.pdf\">" if not $nopublish{$id};
      print "$titlehtm{$id}";
      print "</a>" if not $nopublish{$id};
      print "</td></tr>\n";
    }
    print "</table>\n";

  } else {
    print $not_ready;
  }

}


# Print the lines for poster session $sess
sub print_postsess {
  return unless $postsess_name[$sess];
  print "<h3><a name=\"$sess\">";
  print "$sess. $postsess_name[$sess]";
  print "</a></h3>\n";

  if ($first_post[$sess] > 0){
    print "<p>[<a href=\"pdf/sessio_$sess.pdf\">sessio-pdf</a>]</p>\n";
    print "<table cellpadding=\"6\" cellspacing=\"0\" border=\"0\">\n";

    for $n ($first_post[$sess]..$#{$talkid[$sess]}) {
      $id = ${$talkid[$sess]}[$n];
      print "<tr><td valign=\"top\"><b>$sess.$n</b></td><td>$speaker{$id}:\n";
      print "<a href=\"pdf/abs$id.pdf\">" if not $nopublish{$id};
      print "$titlehtm{$id}";
      print "</a>" if not $nopublish{$id};
      print "</td></tr>\n";

    }
    print "</table>\n";

  } else {
    print $not_ready;
  }
}


open(HTML, ">puheet_to.php");
select HTML;
print $html_top;
print "<h2>Rinnakkaistunnot 17.3. klo 15.00&#8211;16.30</h2>\n";
for $sess (1..5) {
  print_oralsess;
}
print $html_bot;
close(HTML);


open(HTML, ">puheet_pe.php");
select HTML;
print $html_top;
print "<h2>Rinnakkaistunnot 18.3. klo 14.15&#8211;16.00</h2>\n";
for $sess (6..9) {
  print_oralsess;
}
print $html_bot;
close(HTML);


open(HTML, ">puheet_la.php");
select HTML;
print $html_top;
print "<h2>Rinnakkaistunnot 19.3. klo 9.00&#8211;11.00</h2>\n";
for $sess (10..14) {
  print_oralsess;
}
print $html_bot;
close(HTML);


open(HTML, ">posterit_to.php");
select HTML;
print $html_top;
print "<h2>Poster-istunto 17.3. klo 16.30&#8211;18.30</h2>\n";
for $sess (1..5) {
  print_postsess;
}
print $html_bot;
close(HTML);

open(HTML, ">posterit_pe.php");
select HTML;
print $html_top;
print "<h2>Poster-istunto 18.3. klo 16.00&#8211;17.30</h2>\n";
for $sess (6..14) {
  print_postsess;
}
print $html_bot;
close(HTML);
