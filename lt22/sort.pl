#!/usr/bin/perl

use CGI qw(:standard);
require "/home/lt22/bin/common-funcs";

print header, start_html("Sorter");

my $editor = substr(path_info(), 1, 1);


if(param()) {
    open SAVE, ">$logdir/sort_save.$editor";
    save_parameters(SAVE);
    close SAVE;
    my %items = ();
    print p;
    for (param()) {
	next unless /^data(\d+)/;
	my $id = $1;
	my $data = param("data" . $id);
	$data =~ s/^\s+//;
	$data =~ s/\s+$//;
	for my $item (split /[\s,;]+/, $data) {
	    push @{$items{$item}}, $id;
	}
    }
    print table;
    for my $item (sort keys %items) {
	print Tr(td($item) . td(join(", ", sort @{$items{$item}}))), "\n";
    }
    print "</TABLE>";

} else {
    open SAVE, "$logdir/sort_save.$editor" and restore_parameters(SAVE) and
	close SAVE;

    my $f = read_editor_data();

    print start_form,
    submit("Show reverse listing"), " Pressing this also",
    " saves the data you've entered.", br, 
    "Enter a comma-separated list of items into the input boxes.",
    p, "<PRE>";
    
    for my $id (sort keys %$f) {
	my $p = $f->{$id};
	next if ($p->{withdrawn} || $p->{reject} ||
		 $p->{editor} != $editor);
	print a({href => "/cgi/editors?id=$id"}, $id), " ";
	my $label = $p->{speaker} . ": " . $p->{title};
	print (length($label) > 58 ? substr($label, 0, 55) . "..." :
	       $label . " "x(58-length($label)));
	print textfield(-name => "data" . $id, -value => "",
			-size => 25), br, "\n";
    }
    
    print "</PRE>", end_form;
}

print end_html;
