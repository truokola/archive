#!/usr/bin/perl

# Generate a text list of the final sessions

require "common.pl";
require "common2.pl";

chdir "proc";

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

sub get_authors {
  my $id = shift;
  my @auth_list = split (/, /, $authors{$id});
  my $num_auth = $#auth_list + 1;
  my $authstr = "";

  if ($num_auth == 1) {
    $authstr = $auth_list[0];
  } elsif ($num_auth == 2) {
    $authstr = join (" and ", @auth_list);
  } elsif ($num_auth > 10) {
    $authstr = $auth_list[0] . " et al.";
  } else {
    $authstr = join (", ", @auth_list[0..$num_auth-2]);
    $authstr .= ", and " . $auth_list[$num_auth-1];
  }

  return $authstr;
}

sub index_names {
  my $id = shift;
  my @auth_list = split (/, /, $authors{$id});
  my @idx_list = ();
  for $auth (@auth_list) {
    if ($auth =~ /^(.+\.) ([^\.]+)$/) {
      my $name = "$2 $1";
      push @idx_list, $name;
    }
  }

  return @idx_list;
}

open(TOC, ">toc.tex");
open(PAP, ">papers.tex");

select TOC;

$pagenum = 1;

for my $sess (0..$#oralsess_name) {
  $num_talks = $#{$talkid[$sess]};
  next unless $num_talks > 0;

  print "\\tocsession{$sess}{$oralsess_name[$sess]}{$pagenum}\n";
  print "\\begin{toc}\n\n";
  print PAP "\\session{$sess}{$oralsess_name[$sess]}\n\n";
  for my $n (1..$num_talks) {
    my $id = $talkid[$sess][$n];
    print "\\item[";
    if ($time{$id}) {
      print "\\underline{$sess.$n}";
    } else {
      print "$sess.$n";
    }
    print " \\hfill]\n";
    print get_authors($id), ":\n";
    print $titletex{$id}, "\n\n";
    print PAP map("\\index{$_}\n", index_names($id));
#    print PAP "\\includegraphics[trim=$trim{$id},width=126mm]";
#    print PAP "{$absdir/$id}\n\n";
    print PAP "\\pdfpaper{$sess.$n}{$absdir/$id}{$trim{$id}}\n\n";
  }

  print "\\end{toc}\n\n";
  $pagenum += $num_talks;
}

close(TOC);
close(PAP);

unlink "fp.aux";
unlink "fp.idx";
system("pdflatex fp.tex");
system("makeindex fp");
system("pdflatex fp.tex");
#system("pdftops fp.pdf");
#system("ps2pdf fp.ps");
