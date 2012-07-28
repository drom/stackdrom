#
# VeriSub - perl class for Verilog structures
#
# $Id$
#
package VeriSub;

use Moose;
use Graph;
use strict;
use POSIX;

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

sub unite_graphs {
	my $g0 = shift;
	my $g1 = shift;
	my $attr;

	my @gv = $g1->vertices;
	for my $v (@gv) {
#		push (@over_vertices, $v) if $g0->has_vertex($v);
		$g0->add_vertex($v);
		$attr = $g1->get_vertex_attributes($v);
		# ToDo: check vertex attributes for conflict
		$g0->set_vertex_attributes($v, $attr);
	}
	for my $v (@gv) {
		my @edges = $g1->edges_from($v);
		for my $e (@edges) {
			my @e = @{$e};
#			push (@over_edges, @e) if $g0->has_edge(@e);
			$g0->add_edge(@e);
			$attr = $g1->get_edge_attributes(@e);
			# ToDo: check for conflicted attributes
			$g0->set_edge_attributes(@e, $attr);
		}
	}
}

1;
