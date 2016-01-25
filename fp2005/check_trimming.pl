#!/usr/bin/perl

# Check the proper trimming of the abstract margins
# by tightly fitting the abstracts in a framebox

require "common.pl";

# List of abstracts to check
@checklist = (1138);

# Output filename
$outfile = "check.tex";


# Print abstract page
sub print_abs {
  print TEX "\\chead{$sessname[$session{$id}]}\n";
  print TEX "Abstract {\\bf $id} (";
  if ($oral{$id}) {
    print TEX "oral";
  } else {
    print TEX "poster";
  }
  print TEX ")\\\\\n";
  print TEX "$speaker{$id}: $titletex{$id}\\\\\n\n";
  print TEX "\\begin{picture}(126,200)\n";
  print TEX "\\framebox(126,200)[tl]{%\n";
  print TEX "\\includegraphics[trim=$trim{$id}";
#  print TEX ",scale=.84";
  print TEX ",width=126mm";
  print TEX "]{$absdir/$id}";
  print TEX "}\\end{picture}\n";
  print TEX "\\newpage\n";

}


# Print TeX preamble
open (TEX, ">$outfile");
print TEX "\\documentclass[a4paper]{article}\n";
print TEX "\\usepackage[latin1]{inputenc}\n";
print TEX "\\usepackage{graphicx}\n";
print TEX "\\usepackage{fancyhdr}\n";
print TEX "\\setlength{\\topmargin}{0pt}\n";
print TEX "\\setlength{\\headsep}{2mm}\n";
print TEX "\\setlength{\\footskip}{0mm}\n";
print TEX "\\setlength{\\textheight}{240mm}\n";
print TEX "\\setlength{\\textwidth}{126mm}\n";
print TEX "\\setlength{\\parindent}{0pt}\n";
print TEX "\\setlength{\\unitlength}{1mm}\n";
print TEX "\\pagestyle{fancy}\n";
print TEX "\\begin{document}\n";


# Iterate the checklist, skip deleted abstracts (= no title)
for $id (@checklist) {
  print_abs if $titletex{$id};
}

print TEX "\\end{document}\n";
close(TEX);

# Run latex
system("pdflatex $outfile");
