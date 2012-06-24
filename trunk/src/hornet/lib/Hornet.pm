# $Id$
package Hornet;

use Moose;
use strict;
use POSIX;

sub asm2case {
	my $filename = shift;

	my $instructions = {
    ';'      => { code => 0 },
    'ex'     => { code => 1 },
    'jump'   => { code => 2 , lit => 1 },
    'call'   => { code => 3 , lit => 1 },
    'unext'  => { code => 4 },
    'next'   => { code => 5 , lit => 1 },
    'if'     => { code => 6 , lit => 1 },
    '-if'    => { code => 7 , lit => 1 },

    '@p+'    => { code => 8 },
    '@p'     => { code => 8 }, # old

    '@+'     => { code => 9 },
    '@b'     => { code => 10},
    '@'      => { code => 11},
    '!p'     => { code => 12},
    '!+'     => { code => 13},
    '!b'     => { code => 14},
    '!'      => { code => 15},

    '+*'     => { code => 16},
    '2*'     => { code => 17},
    '2/'     => { code => 18},

    '-'      => { code => 19},
    'not'    => { code => 19}, # old

    '+'      => { code => 20},
    'and'    => { code => 21},
    'or'     => { code => 22},
    'drop'   => { code => 23},

    'dup'    => { code => 24},
    'pop'    => { code => 25},
    'over'   => { code => 26},
    'a'      => { code => 27},
    '.'      => { code => 28},
    'push'   => { code => 29},
    'b!'     => { code => 30},
    'a!'     => { code => 31}
};

	my @RET;

	open INP, $filename or die "Couldn't open file: $!";
	binmode INP;

	for my $line (<INP>) {
		my @LINE = split (' ', $line);
		if (scalar @LINE > 1) {
			my $addr = hex $LINE[0];
			$RET[$addr][1] = $line;
			if ($LINE[1] =~ /^[0-9A-F]{1,3}$/) {
				$RET[$addr][0] = hex $LINE[1];
			} else {
				my $slot0 = %{$instructions}->{$LINE[1]}->{"code"};
				$RET[$addr][0] = ($slot0 ^ 10) * 8192;
				if (defined %{$instructions}->{$LINE[1]}->{"lit"}) {
					$RET[$addr][0] += (hex $LINE[2]) + 5120;
				} else {
					my $slot1 = %{$instructions}->{$LINE[2]}->{"code"};
					$RET[$addr][0] += ($slot1 ^ 21) * 256;				
					if (defined %{$instructions}->{$LINE[2]}->{"lit"}) {
						$RET[$addr][0] += hex $LINE[3];
					} else {
						my $slot2 = %{$instructions}->{$LINE[3]}->{"code"};
						$RET[$addr][0] += ($slot2 ^ 10) * 8;
						if (defined %{$instructions}->{$LINE[3]}->{"lit"}) {
							$RET[$addr][0] += hex $LINE[4];
						} else {
							my $slot3 = %{$instructions}->{$LINE[4]}->{"code"};
							$RET[$addr][0] += ($slot3 / 4) ^ 5;
						}
					}
				}
			}
		}
	}
	close INP;

	my $ret = '';
	for (my $i = 0; $i < scalar @RET; $i++) {
		if (defined $RET[$i]) {
			
			$ret .= sprintf "\t\t%5d : q_rom = 18'b %018b; // %05X --- %s", $i, $RET[$i][0], $RET[$i][0], $RET[$i][1];
		}
	}
	return $ret;
}

1;
