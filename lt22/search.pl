#!/usr/bin/perl


use CGI qw(:standard);
require "/home/lt22/bin/common-funcs";

my $auth_base = "$logdir/author_base";
my $addr_base = "$logdir/address_base";
my $keys_base = "$logdir/keyword_base";


sub split_to_words {
    my($text) = @_;
    @words = grep ((/^[A-Za-z0-9]+$/ &&
		    s/(.*)/\L$1/),
		   split /\s*[\.\s\?\-\{|\}|\(|\)|\"|\`|\'|\[|\]\/\$!,;:_]+\s*/,
		   $text);
    return \@words;
}



sub intersect {
    my @tabrefs = @_;
    my %elem = ();
    my @ret = ();
    for my $tab (@tabrefs) {
	my %old = ();
	for (@{$tab}) { $elem{$_}++ unless $old{$_}++ }
    }
    for (keys %elem) {
	push @ret, $_ if $elem{$_} == @tabrefs;
    }
    return \@ret;
}

print header, start_html("Abstract Search"), h1("Search");

if(param()) {
    my @keys = @{ split_to_words(param("freetext")) };
    my @auth = map {flatten_name($_)} split /\s*[\s,;]+\s*/, param("authors");
    my $addr = lc(flatten_latex(param("addresses")));
    my @collect = ();
    my $result = [];

    if(@keys) {
	my @matches = ();
	open KEYS, $keys_base;
	while(<KEYS>) {
	    my($term, @ids) = split /\s+/;
	    for my $keypos (0..$#keys) {
		next unless $term =~ /^$keys[$keypos]/;
		push @{$matches[$keypos]}, @ids;
		last;
	    }
	}
	close KEYS;
	push @collect, intersect(@matches);
    }

    
    if(@auth) {
	my @matches = ();
	my $id = 0;
	open AUTH, $auth_base;
	while(my $line = <AUTH>) {
	    if($line =~ /^:(\d+)/) {
		$id = $1;
	    } else {
		for my $keypos (0..$#auth) {
		    next unless $line =~ /^$auth[$keypos]/;
		    push @{$matches[$keypos]}, $id;
		    last;
		}
	    }
	}
	close AUTH;
	push @collect, intersect(@matches);
    }


    if($addr) {
	my @matches = ();
	my $id = 0;
	open ADDR, $addr_base;
	while(my $line = <ADDR>) {
	    if($line =~ /^:(\d+)/) {
		$id = $1;
	    } else {
		push @matches, $id if $line =~ /\b$addr/;
	    }
	}
	close ADDR;
	push @collect, \@matches;
    }

    $result = intersect(@collect);
    if(@{$result}) {
	print h3("Matching abstracts"), p;
	my $f = read_editor_data();
	for my $id (sort @{$result}) {
	    print a({href => "/cgi/editors?id=$id"}, $id), " ",
	    $f->{$id}->{speaker}, ": ", $f->{$id}->{title}, br;
	}
    } else {
	print p, "No matches.";
    }

} else {
    print start_form, p,
    "The fields are ANDed together. ", 
    "Search matches only the beginning of the words.", br,
    "Authors' surnames: ", textfield("authors"), br,
    "Addresses: ", textfield("addresses"), br,
    "Abstract text: ", textfield("freetext"), p,
    submit("Search"),
    end_form;
}

print end_html;

    
