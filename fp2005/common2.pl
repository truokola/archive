# Some more stuff common to many scripts in this directory
# To be used when the final program is about ready



open(DATA, ".data/oral_sessions.txt") or die;
while(<DATA>) {
  /^([0-9]+): (.*)::(.*)::(.*)::(.*)::(.*)/ or next;
  $oralsess_name[$1] = $2;  # session name
  $chairman[$1] = $3;       # chairman name
  $affil[$1] = $4;          # chairman affiliation
  $location[$1] = $5;       # session location
  $oralsess_day[$1] = $6;   # day of the month of the session
}
close(DATA);
$oralsess_name[0] = "Plenary lectures";


open(DATA, "./data/poster_sessions.txt") or die;
while(<DATA>) {
  /^([0-9]+): (.*)::(.*)/ or next;
  $postsess_name[$1] = $2;  # session name
  $postsess_day[$1] = $3;   # day of the month of the session
}
close(DATA);


for $sess (0..$#oralsess_name) {

  open(DATA, "./data/session_$sess.txt") or next;

  # Sequence number of the presentation within the session
  $num = 1;

  # Number of the last oral in the session
  $last_oral[$sess] = 0;

  # Number of the first poster in the session
  $first_post[$sess] = 0;

  while(<DATA>) {
    /^(....)\s*(\S*)/ or next;
    ${$talkid[$sess]}[$num] = $1;
    if ($2) { # it's oral
      $time{$1} = $2;
    } else { # it's a poster
      $first_post[$sess] = $num if $first_post[$sess] == 0;
    }
    $num++;
  }

  if($first_post[$sess] == 0) {
    $last_oral[$sess] = $#{$talkid[$sess]};
  } else {
    $last_oral[$sess] = $first_post[$sess] - 1;
  }

  close(DATA);
}

1;
