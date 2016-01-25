#!/usr/bin/perl

# Generate pdf files, one for each preliminary session,
# containing all submitted abstracts

require "common.pl";

# Names of the pdf files
@pdfname = ( "00_plenary",
	     "01_cond_mat_struct",
	     "02_cond_mat_electr",
	     "03_nano",
	     "04_bio",
	     "05_atomic",
	     "06_optics",
	     "07_particle",
	     "08_astro",
	     "09_applied",
	     "10_medical",
	     "11_teaching");

# Name for the temporary files (without extension)
$tmpname = "tmp_sess";

# Print the abstract page
sub print_abs {
  print TEX "Abstract {\\bf $id} (";
  if ($oral{$id}) {
    print TEX "oral";
  } else {
    print TEX "poster";
  }
  print TEX ")\\\\\n";
  print TEX "$speaker{$id}: $titletex{$id}\\\\\n";
  print TEX "\\hrule\\vskip 7mm\n";
  print TEX "\\centerline{\n";
  print TEX "\\includegraphics[trim=$trim{$id},keepaspectratio,width=124mm,height=215mm]";
  print TEX "{$absdir/$id}";
  print TEX "\n}\n";

  print TEX "\\newpage\n";
}


# Iterate over all sessions
for $n (0..$#sessname) {
  open (TEX, ">$tmpname.tex");
  print TEX "\\documentclass[a4paper]{article}\n";
  print TEX "\\usepackage[latin1]{inputenc}\n";
  print TEX "\\usepackage{graphicx}\n";
  print TEX "\\usepackage{fancyhdr}\n";
#  print TEX "\\setlength{\\voffset}{-15mm}\n";
  print TEX "\\setlength{\\topmargin}{0pt}\n";
  print TEX "\\setlength{\\headsep}{2mm}\n";
  print TEX "\\setlength{\\footskip}{0mm}\n";
#  print TEX "\\setlength{\\oddsidemargin}{-8mm}\n";
#  print TEX "\\setlength{\\evensidemargin}{-8mm}\n";
  print TEX "\\setlength{\\textheight}{240mm}\n";
  print TEX "\\setlength{\\textwidth}{130mm}\n";
  print TEX "\\setlength{\\parindent}{0pt}\n";
  print TEX "\\setlength{\\unitlength}{1mm}\n";
  print TEX "\\pagestyle{fancy}\n";
  print TEX "\\chead{$sessname[$n]}\n";
  print TEX "\\begin{document}\n";

  # First oral abstracts...
  for $id (sort keys %session) {
    print_abs if $session{$id} == $n and $oral{$id};
  }
  # ...then posters
  for $id (sort keys %session) {
    print_abs if $session{$id} == $n and not $oral{$id};
  }

  print TEX "\\end{document}\n";
  close(TEX);

  # Create the pdf; seems clumsy but this was the only way I
  # could get around some font problems. YMMV.
  system("pdflatex $tmpname.tex");
  system("pdftops $tmpname.pdf");
  system("ps2pdf $tmpname.ps $pdfname[$n].pdf");
}
