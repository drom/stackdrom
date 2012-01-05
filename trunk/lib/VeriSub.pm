#
# VeriSub - perl class for Verilog structures
#
# $Id$
#
package VeriSub;

use strict;
use POSIX;

sub new {
	my $class = shift;
	my $self  = {
		START => time(),
		AGE   => 0,
		NAME  => shift,
		LINKS => [],
		@_
	};
	bless($self, $class);
	return $self;
}

sub logic_dim {
#	my $self = shift;
	my $w = shift;
	if ($w == 1) { return '       '; }
	return sprintf "%4s:0]", ('[' . ($w - 1));
}

sub logic_slice {
#	my $self = shift;
	my $o = shift;
	my $w = shift;
	if ($w == 1) {
		return sprintf "%-7s", "[$o]";
	}
	return sprintf "%-7s", ('[' . ($o + $w - 1) . ':' . ($o).']');
}

sub logic_slice_0 {
#	my $self = shift;
	my $w = shift;
	if ($w == 1) {
		return '[0]    ';
	}
	return sprintf "%-7s", ('[' . ($w - 1) . ':0]');
}

sub ild_extract {
#	my $self = shift;
	my $root   = shift;
	my $formats = shift;
	my $ret    = shift;
	my $offset = shift;
	my $reg    = shift;
	my $chunk  = shift;
	if (ref($root) eq 'HASH') {
		for my $e (keys %$root) {
			$ret .= sprintf("(%s[%-3s] ? ", "$reg", ($e + $offset));
			$ret = ild_extract (${$root->{$e}}[0], $formats, $ret, $offset, $reg, $chunk);
			$ret .= ' : ';
			$ret = ild_extract (${$root->{$e}}[1], $formats, $ret, $offset, $reg, $chunk);
			$ret .= ')';
		}
	} else {
		$ret .= @{$formats->{$root}}[0] / $chunk;
	}
	return $ret;
}

sub max {
	my ($a, $b) = @_;
	return $a if $a > $b;
	return $b;
}

sub maxlen {
#	my $self = shift;
	my $root    = shift;
	my $formats = shift;
	my $ret     = shift;
	if (ref($root) eq 'HASH') {
		for my $e (keys %$root) {
			$ret = maxlen (${$root->{$e}}[0], $formats, $ret);
			$ret = maxlen (${$root->{$e}}[1], $formats, $ret);
		}
	} else {
		$ret = max ($ret, ${$formats->{$root}}[0]);
	}
	return $ret;
}

sub gcd {
	my ($a, $b) = @_;
	($a, $b) = ($b, $a) if $a > $b;
	while ($a) {
		($a, $b) = ($b % $a, $a);
	}
	return $b;
}

sub gcdlen {
#	my $self = shift;
	my $root    = shift;
	my $formats = shift;
	my $ret     = shift;
	if (ref($root) eq 'HASH') {
		for my $e (keys %$root) {
			$ret = gcdlen (${$root->{$e}}[0], $formats, $ret);
			$ret = gcdlen (${$root->{$e}}[1], $formats, $ret);
		}
	} else {
		$ret = gcd ($ret, ${$formats->{$root}}[0]);
	}
	return $ret;
}

1;
