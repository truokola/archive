# -*- Perl -*-
require "/home/lt22/bin/common-funcs";

my $auth_base = "$logdir/author_base";
my $addr_base = "$logdir/address_base";
my $keys_base = "$logdir/keyword_base";

@exclude = qw(a about after along also an and any are as at be been both
	      but by for from has have how if in into is it no not of off on
	      only or our since some such than that the them then there
	      these this to very was we were when which while why with);

for (@exclude) { $exclude{$_} = 1 }

sub split_to_words {
    my($text) = @_;
    @words = grep ((/^[A-Za-z0-9]+$/ &&
		    s/(.*)/\L$1/ &&
		    !$exclude{$_}), 
		   split /\s*[\.\s\?\-\{|\}|\(|\)|\"|\`|\'|\[|\]\/\$!,;:_]+\s*/,
		   $text);
    return \@words;
}


my %index = ();

open AUTH, ">$auth_base";
open ADDR, ">$addr_base";


for my $id (grep /^\d{5}$/, dir_listing($docdir)) {
    my @words = ();
    my %old = ();
    my $f = abstract_data($id);
    push @words, @{ split_to_words abstract_body($id) };
    push @words, @{ split_to_words $f->{Title}[0][0] };
    for (@words) { 
	push @{$index{$_}}, $id unless $old{$_};
	$old{$_}++;
    }
    print ADDR ":$id\n";
    for my $addr (@{$f->{Address}}) {
	print ADDR flatten_latex(lc($$addr[1])), "\n";
    }
    print AUTH ":$id\n";
    for my $auth (@{$f->{Speaker}}, @{$f->{Author}}) {
	print AUTH flatten_name(lc($$auth[2])), "\n";
    }
}

close AUTH;
close ADDR;

open KEYS, ">$keys_base";

for (sort keys %index) {
    print KEYS $_, "\t", join (" ",  @{$index{$_}}), "\n";
}

close KEYS;
