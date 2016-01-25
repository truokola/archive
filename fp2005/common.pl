# Some stuff common to many scripts in this directory

# Location of the abstract images
$absdir = "./pdfs";


# Input the main abstract data file, "absdata".
# For instance, the absdata line
# 1002:session: 6
# implies
# $session{1002} = 6;

open(DATA, "./data/absdata.txt") or die;
while(<DATA>) {
  /^([0-9]+):([a-z]+): (.*)/;
  chomp($str = $3);
  $$2{$1} = $str;
}
close(DATA);


# Input the preliminary session names.
# For instance, the "sessions" line
# 4: Biological matter
# implies
# $sessname[4] = "Biological matter";

open(DATA, "./data/sessions.txt") or die;
while(<DATA>) {
  /^([0-9]+): (.*)/;
  chomp($str = $2);
  $sessname[$1] = $str;
}
close(DATA);

1;
