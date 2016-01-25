# -*- Perl -*-

require "/home/lt22/bin/common-funcs";


@sect = ("Quantum Gases, Fluids and Solids",
	 "Superconductivity",
	 "Magnetism and Lattice Properties",
	 "Quantum Electron Transport",
	 "Applications, Materials and Techniques");

@sessions = [];
@timeindex = ();
my @mins = (45, 45, 30, 15);

open(DATA, "$logdir/oral_sessions") or die "Can't open file";

while(<DATA>) {
    next if not /^\S+:/;
    for ("A".."Z") { undef $$_ }

    $line = $_;
    while(defined $line && $line =~ /^(.*?):\s*(.*)$/) {
	my $cmd = $1;
	my $val = $2;
	$$cmd = $val;
	$line = <DATA>;
    }

    die if not defined $T;
    die if not defined $S;
    die if not defined $N;
    die if not defined $P;
    die if not defined $D;
    $sessions[$T][$S]{name} = $N;
    $sessions[$T][$S]{day} = $D;
    $sessions[$T][$S]{pos} = $P;
    $sessions[$T][$S]{chair} = $C;
    $timeindex[$D][$P][$T] = $S;
}

close DATA;

sub session_time {
    my ($sect, $sess) = @_;
    my @ret = ();
    my $day = $sessions[$sect][$sess]{day};
    my $pos = $sessions[$sect][$sess]{pos};
    push @ret, $day;
    if ($day == 0) { push @ret, (14, 00) }
    elsif ($day == 5) { push @ret, (9, 00) }
    else { push @ret, ($pos == 0 ? 11 : 14, 0) }
    return @ret;
}

sub speakers {
    my @sp2 = ();
    my $cumul_time = 0;
    my @speakers = [];
    open DATA, "$logdir/invited" or die;
    my $sect = 0;
    my $sess = 0;

MAIN_LOOP:
    while(<DATA>) {
	next if not /^\S+?:/;
	for ("A".."Z") { undef $$_ }
	
	$line = $_;
	while(defined $line && $line =~ /^(.*?):\s*(.*)$/) {
	    my $cmd = $1;
	    my $val = $2;
	    if(lc($cmd) eq "section") {
		$sect++;
		$sess = 0;
		next MAIN_LOOP;
	    } elsif(lc($cmd) eq "session") {
		$sess++;
		$cumul_time = 0;
		next MAIN_LOOP;
	    } else {
		$$cmd = $val;
		$line = <DATA>;
	    }
	}
	
	die if not defined $N;
	die if not defined $I;
	die if not defined $E;
	die if not defined $P;
	die if not defined $G;
	die unless (defined $A || defined $Q);
	
	my %data = ();
	$data{name} = $N;
	if (defined $T) {
	    ($data{day}, $data{hour}, $data{min}) = split /:/, $T; ##WRONG!!
	} else {
	    my ($day, $hour, $min) = session_time($sect, $sess);
	    $data{day} = $day;
	    ($data{hour}, $data{min}) = addtime($hour, $min, $cumul_time);
	    $cumul_time += $mins[$G];
	}
	$data{len} = $mins[$G];
	$data{paper} = ($P =~ /^-/ ? "" : $P);
	$data{type} = $G;
	$data{apply} = $F;
	$data{accept} = $A;
	$data{grant} = $M;
	$data{email} = $E;
	push @{$speakers[$sect][$sess]}, \%data;
	push @sp2, \%data;
    }
    close DATA;
    return \@speakers, \@sp2;
}

sub addtime {
    my ($hour, $min, $addmin) = @_;
    $min += $addmin;
    return ($hour + int ($min / 60), $min % 60);
}
