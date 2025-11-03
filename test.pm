#!/usr/bin/perl
my $output = "'testa' not found in package names. Trying capabilities.\n'testb' not found in package names. Trying capabilities.\n'testc' not found in package names. Trying capabilities.\n";
foreach my $line (split("\n", $output)) {
    printf "Line: $line\n";
    push(@new_packages, $1) if $line =~ /'(\w+)'/;
    printf "Push: @new_packages\n";
}
