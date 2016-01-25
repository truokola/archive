#!/usr/bin/perl

# Generate pdf files for web

require "common.pl";
require "common2.pl";

# Name for the temporary session files (without extension)
$tmpsess = "tmp_sess";

# Name for the temporary abstract files (without extension)
$tmpabs = "tmp_abs";

# Print the abstract page
sub print_abs {
  print "\\lhead{\\bfseries $sess.$n}\n";
  print "{\\sl Presentation on ";
  if ($time{$id}) { # oral
    print "$oralsess_day[$sess].3.~at $time{$id} ($location[$sess])";
  } else {
    print "$postsess_day[$sess].3.~(poster session)";
  }
  print "\\\\\n";
  print "\\hrule\\vskip 5mm\n";
  print "\\centerline{\n";
  print "\\includegraphics[trim=$trim{$id},keepaspectratio,width=126mm,height=215mm]";
  print "{$absdir/$id}";
  print "\n}\n";
  print "\\newpage\n";
}



# Iterate over all sessions
for $sess (12) {
  $last_talk = $#{$talkid[$sess]};
  next unless $last_talk > 0;

  $preamble =
  "\\documentclass[a4paper]{article}\n".
  "\\usepackage[latin1]{inputenc}\n".
  "\\usepackage{graphicx}\n".
  "\\usepackage{fancyhdr}\n".
  "\\setlength{\\topmargin}{0pt}\n".
  "\\setlength{\\headsep}{3.2mm}\n".
  "\\setlength{\\footskip}{0mm}\n".
  "\\setlength{\\textheight}{240mm}\n".
  "\\setlength{\\textwidth}{126mm}\n".
  "\\setlength{\\parindent}{0pt}\n".
  "\\setlength{\\unitlength}{1mm}\n".
  "\\pagestyle{fancy}\n".
  "\\chead{$oralsess_name[$sess]}\n".
  "\\cfoot{}\n".
  "\\begin{document}\n";

  open (SESS, ">$tmpsess.tex");
  print SESS $preamble;

  for $n (1..$last_talk) {
    $id = $talkid[$sess][$n];
    if (not $nopublish{$id}) {
      select SESS;
      print_abs;
      open(ABS, ">$tmpabs.tex");
      print ABS $preamble;
      select ABS;
      print_abs;
      print ABS "\\end{document}\n";
      close(ABS);
      system("pdflatex $tmpabs.tex");
      system("pdftops $tmpabs.pdf");
      system("ps2pdf $tmpabs.ps abs$id.pdf");
    }
  }
  
  print SESS "\\end{document}\n";
  close(SESS);
  
  # Create the pdf; seems clumsy but this was the only way I
  # could get around some font problems. YMMV.
  system("pdflatex $tmpsess.tex");
  system("pdftops $tmpsess.pdf");
  system("ps2pdf $tmpsess.ps sessio_$sess.pdf");
}
