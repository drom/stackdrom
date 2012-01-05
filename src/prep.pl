#!/usr/bin/perl -w

use strict;
use POSIX;

{
	my $input  = $ARGV[0]; # input Verilog file name
	my @Aval;
	open(INP, "<$input") or die "Could not open file - input file: $!";
	my $state = 0; # 0 = perl mode; 1 = dot mode
	while(<INP>) {
		chomp;
		if ($_ =~ m/\/\/;/) { # perl mode
			if($state == 1) {
				$_ =~ s/\/\/;//g;
				$_ = "EOD\n" . $_;
			} else {
				$_ =~ s/\/\/;//g;
			}
			$state = 0;
		} else { # source mode
			if($state == 0) {
				$_ = "print <<EOD;\n" . $_;
				$state = 1;
			}
		}
		push @Aval, $_;
	}
	if($state == 1) { push @Aval, "EOD\n"; }
	close(INP);
	if (defined $ARGV[1]) {
		eval(join("\n", @Aval));
	} else {
		print join("\n", @Aval);
	}
}
