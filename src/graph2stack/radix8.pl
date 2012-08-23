#!/usr/bin/perl -w

use strict;
use Graph;
use Graph::Writer::Dot;
use Data::Dumper;

sub layers {
	my $g     = shift;
	my $layers = shift;

	my $i = 1; # layer number
	for my $layer (@{$layers}) {
		my $j = 0; # to
		for my $row (@{$layer}) {
			my $k = 0; # from
			my $to = $i . ',' . $j;
			for my $e (@{$row}) {
				my $from = ($i-1) . ',' . $k;
				if ($e eq 'i') {
					$g->add_edge("re-$from", "im-$to");
					$g->set_edge_attribute("im-$from", "re-$to", 'headlabel', -1);
				} elsif ($e eq '1') {
					$g->add_edge("re-$from", "re-$to");
					$g->add_edge("im-$from", "im-$to");
				} elsif ($e) {
					$g->set_edge_attribute("re-$from", "re-$to", 'headlabel', $e);
					$g->set_edge_attribute("im-$from", "im-$to", 'headlabel', $e);
				}
				$k++;
			}
			$j++;
		}
		$i++;
	}
}

sub operations {
	my $g = shift;

 	for my $v ($g->vertices) {
		if ($g->in_degree($v) == 2) {
#			$g->set_vertex_attribute($v, 'label', '+');
			$g->set_vertex_attribute($v, 'shape', 'oval');
			$g->set_vertex_attribute($v, 'type',  '+');
		} elsif ($g->in_degree($v) == 1) {
			my @EDGE = $g->edges_to($v);
			my $label = $g->get_edge_attribute(@{$EDGE[0]}, 'headlabel');
			if (defined $label) {
				if (($label eq '1') or ($label eq '-1')) {
					$g->set_vertex_attribute($v, 'shape', 'point');
				} else {
					$g->set_vertex_attribute($v, 'type',  '*');
					$g->set_vertex_attribute($v, 'shape', 'box');
					$g->set_vertex_attribute($v, 'height', 3);
				}
			} else {
				$g->set_vertex_attribute($v, 'shape', 'point');
			}
		} else {
			$g->set_vertex_attribute($v, 'shape', 'point');
		}
	}
}

sub clean1 {
	my $g = shift;

	for my $v ($g->vertices) {
		if (($g->in_degree($v) == 1) and ($g->out_degree($v) > 0)) {
			my @EDGES_TO = $g->edges_to($v);
			my @EDGE_TO  = @{$EDGES_TO[0]};
			my $label = $g->get_edge_attribute(@EDGE_TO, 'headlabel');
			if (!defined $label) {
				my @EDGES_FROM = $g->edges_from($v);
				for my $e (@EDGES_FROM) {
					my @EDGE = @{$e};
					my $attr = $g->get_edge_attributes(@{$e});
					$g->set_edge_attributes($EDGE_TO[0], $EDGE[1], $attr);
				}
				$g->delete_vertex($v);
			}			
		}
	}
}

sub clean2 {
	my $g = shift;

	for my $v ($g->vertices) {
		if (($g->in_degree($v) == 1) and ($g->out_degree($v) > 0)) {
			my @EDGES_TO = $g->edges_to($v);
			my @EDGE_TO  = @{$EDGES_TO[0]};
			my $label = $g->get_edge_attribute(@EDGE_TO, 'headlabel');
			if ($label eq '-1') {
				my @EDGES_FROM = $g->edges_from($v);
				for my $e (@EDGES_FROM) {
					my @EDGE = @{$e};
					my $attr = $g->get_edge_attributes(@{$e});
					$g->set_edge_attributes($EDGE_TO[0], $EDGE[1], $attr);

					my $l = $g->get_edge_attribute(@{$e}, 'headlabel');
					if (defined $l) {
						if ($l eq '-1') {
							$g->delete_edge_attribute($EDGE_TO[0], $EDGE[1], 'headlabel');
						} else {
							$g->set_edge_attribute($EDGE_TO[0], $EDGE[1], 'headlabel', "-$l");
						}
					} else {
						$g->set_edge_attribute($EDGE_TO[0], $EDGE[1], 'headlabel', '-1');
					}
				}
				$g->delete_vertex($v);
			}			
		}
	}
}

sub colorize {
	my ($g, $code, $colors) = @_;
	
	my $i = 0;
	for my $thread (@{$code}) {
		my $j = 0;
		for my $v (@{$thread}) {
			$g->set_vertex_attribute($v, 'color', $colors->[$i]);
			$g->set_vertex_attribute($v, 'style', 'filled');
			$g->set_vertex_attribute($v, 'fontcolor', 'black');
			$j++;
		}
		$i++;
	}
}

sub straighten {
	my ($g, $code, $colors) = @_;
	
	my $i = 0;
	for my $thread (@{$code}) {
		my $j = 0;
		for my $v (@{$thread}) {
			if ($j) {
				if (!($g->has_edge($thread->[$j-1], $thread->[$j]))) {
					$g->set_edge_attribute($thread->[$j-1], $thread->[$j], 'style', 'invis');
				}
				$g->set_edge_attribute($thread->[$j-1], $thread->[$j], 'group', $i);
				$g->set_edge_attribute($thread->[$j-1], $thread->[$j], 'weight', 100);
				$g->set_edge_attribute($thread->[$j-1], $thread->[$j], 'type', 'cfg');
			}
			$j++;
		}
		$i++;
	}
}

sub index_ports {
	my $g = shift;
	for my $v ($g->vertices) {
		if ($g->in_degree($v) == 0) {
			$g->set_vertex_attribute($v, 'shape', 'invhouse');
			$g->set_vertex_attribute($v, 'type',  'inport');
		} elsif ($g->out_degree($v) == 0) {
			$g->set_vertex_attribute($v, 'shape', 'invhouse');
			$g->set_vertex_attribute($v, 'type',  'ouport');
		}
	}
}

sub decouple {
	my $g = shift;

	for my $v ($g->vertices) {
		my $color = $g->get_vertex_attribute ($v, 'color');
		if (defined $color) {
			for my $e ($g->edges_from($v)) {
				my $c2 = $g->get_vertex_attribute($e->[1], 'color');
				if (defined $c2 and ($c2 ne $color)) {
					my $label = $g->get_edge_attribute(@{$e}, 'headlabel');

					$g->add_edge($e->[0], "${v}_ou");
					$g->set_vertex_attribute("${v}_ou", 'shape', 'invhouse');
					$g->set_vertex_attribute("${v}_ou", 'type',  'ouport');

					$g->set_edge_attribute("${v}_ou", "${v}_in", 'constraint', 'false');
					$g->set_edge_attribute("${v}_ou", "${v}_in", 'style', 'dashed');

					$g->add_edge("${v}_in", $e->[1]);
					$g->set_edge_attribute("${v}_in", $e->[1], 'headlabel', $label) if defined $label;

					$g->set_vertex_attribute("${v}_in", 'shape', 'invhouse');
					$g->set_vertex_attribute("${v}_in", 'type',  'inport');

					$g->delete_edge(@{$e});
				}
			}
		}
	}	
}

sub decouple_inports {
	my $g = shift;

	for my $v ($g->vertices) {
		my $vtype = $g->get_vertex_attribute ($v, 'type');
		if ((defined $vtype) and ($vtype eq "inport")) {
			my $colors;
			for my $e ($g->edges_from($v)) {
				my $color = $g->get_vertex_attribute($e->[1], 'color');
				if (defined $color) {
					$colors->{$color} += 1;
				}
			}
			if ((scalar keys %{$colors}) > 1) {
				for my $e ($g->edges_from($v)) {
					my $color = $g->get_vertex_attribute($e->[1], 'color');
					if (defined $color) {
						my $label = $g->get_edge_attribute(@{$e}, 'headlabel');

						$g->set_vertex_attribute("${v}_${color}", 'shape', 'invhouse');
						$g->set_vertex_attribute("${v}_${color}", 'type',  'inport');

						$g->add_edge("${v}_${color}", $e->[1]);
						$g->set_edge_attribute("${v}_${color}", $e->[1], 'headlabel', $label) if defined $label;
					}
				}
				$g->delete_vertex($v);
			}
		}
	}	
}

sub node_map {
	my ($g0, $g1) = @_;
	for my $e ($g0->edges) {
		my $c0 = $g0->get_vertex_attribute($e->[0], 'color');
		my $c1 = $g0->get_vertex_attribute($e->[1], 'color');
		if ((defined $c0) and (defined $c1) and ($c0 ne $c1)) {
			$g1->add_edge($c0, $c1);
		}
	}
}

sub straighten_ouports {
	my $g = shift;

	for my $v ($g->vertices) {
		my $type = $g->get_vertex_attribute($v, 'type');
		if (defined $type and $type eq 'ouport') {
			my @e = $g->edges_to($v);
			my $v1 = $e[0]->[0];
			for my $e1 ($g->edges_from($v1)) {
				my $e1type = $g->get_edge_attribute(@{$e1}, 'type');
				if ((defined $e1type) and ($e1type eq 'cfg')) {
					my $e1style = $g->get_edge_attribute(@{$e1}, 'style');
					if ((defined $e1style) and ($e1style eq 'invis')) {
						$g->delete_edge(@{$e1});
						$g->set_edge_attribute(@{$e[0]}, 'weight', 100);
						$g->set_edge_attribute(@{$e[0]}, 'type', 'cfg');

						$g->set_edge_attribute($e[0]->[1], $e1->[1], 'weight', 100);
						$g->set_edge_attribute($e[0]->[1], $e1->[1], 'type',  'cfg');
						$g->set_edge_attribute($e[0]->[1], $e1->[1], 'style', 'invis');
					}
				}
			}
		}
	}
}

sub get_cfg_root {
	my $g = shift;
	my $v  = shift;

	for my $e ($g->edges_to($v)) {
		my @E = @{$e};
		my $etype = $g->get_edge_attribute(@E, 'type');
		if ((defined $etype) and ($etype eq 'cfg')) {
			return get_cfg_root ($g, $E[0]);
		}
	}
	return $v;
}

sub get_cfg_root_by_color {
	my ($g, $color) = @_;

	for my $v0 ($g->vertices) {
		my $v0color = $g->get_vertex_attribute($v0, 'color');
		if ((defined $v0color) and ($v0color eq $color)) {
			return get_cfg_root($g, $v0);
		}
	}
	
}

sub get_cfg_match {
	my ($g, $v, $v0) = @_;

	if ($g->has_edge($v0, $v)) {
		return $v;
	}
	for my $e ($g->edges_from($v)) {
		my @E = @{$e};
		my $etype = $g->get_edge_attribute(@E, 'type');
		if ((defined $etype) and ($etype eq 'cfg')) {
			return get_cfg_match ($g, $E[1], $v0);
		}
	}
	return undef;
}

sub straighten_inports {
	my $g = shift;

	for my $v0 ($g->vertices) {
		my $v0type = $g->get_vertex_attribute($v0, 'type');
		if (defined $v0type and $v0type eq 'inport') {
			my @E = $g->edges_from($v0);
			my $color = $g->get_vertex_attribute($E[0]->[1], 'color');
			my $vroot = get_cfg_root_by_color($g, $color);
			my $v1    = get_cfg_match($g, $vroot, $v0);
			for my $e1 ($g->edges_to($v1)) {
				my @E1 = @{$e1};
				my $v2 = $E1[0];
				my $e1type = $g->get_edge_attribute($v2, $v1, 'type');
				if ((defined $e1type) and ($e1type eq 'cfg')) {
					my $e1style = $g->get_edge_attribute($v2, $v1, 'style');
					if ((defined $e1style) and ($e1style eq 'invis')) {
						$g->delete_edge($v2, $v1);
					} else {
						$g->set_edge_attribute     ($v2, $v1, 'weight', 1);
						$g->set_edge_attribute     ($v2, $v1, 'type', '');
#						$g->delete_edge_attribute  ($v2, $v1, 'type');
					}
					$g->set_edge_attribute($v0, $v1, 'weight', 100);
					$g->set_edge_attribute($v0, $v1, 'type', 'cfg');

					$g->set_edge_attribute($v2, $v0, 'weight', 100);
					$g->set_edge_attribute($v2, $v0, 'type',  'cfg');
					$g->set_edge_attribute($v2, $v0, 'style', 'invis');
					last;
				}
			}
		}
	}
}

sub dfg_colors {
	my $g = shift;

	my @C = ();
	my %seen = ();
	for my $v ($g->vertices) {
		my $color = $g->get_vertex_attribute($v, 'color');
		if (defined $color) {
			next if $seen{$color}++;
			push (@C, $color);
		}
	}
	return \@C;
}

sub dfg_asap {
	my $g = shift;

	my @A = ();
	my %seen = ();
	my @RET = ();
	for my $v ($g->vertices) {
		my $vtype = $g->get_vertex_attribute($v, 'type');
		if ((defined $vtype) and (($vtype eq 'inport') or ($vtype eq 'ouport'))) {
			$seen{$v}++;
			push @A, $v;
		}
	}
	do {
		my %see = ();
		push @RET, [];
		MAIN: for my $v ($g->vertices) {
			next if $seen{$v};
			my $e;
			for $e ($g->edges_to($v)) {
				next MAIN unless $seen{$e->[0]};
			}
			push $RET[-1], $v;
			$see{$v}++;
		}
		%seen = (%seen, %see);
	} while (scalar @{$RET[-1]});
	return \@RET;
}

sub dfg_alap {
	my $g = shift;

	my @A = ();
	my %seen = ();
	my @RET = ();
	for my $v ($g->vertices) {
		my $vtype = $g->get_vertex_attribute($v, 'type');
		if ((defined $vtype) and (($vtype eq 'inport') or ($vtype eq 'ouport'))) {
			$seen{$v}++;
			push @A, $v;
		}
	}
	do {
		my %see = ();
		push @RET, [];
		MAIN: for my $v ($g->vertices) {
			next if $seen{$v};
			my $e;
			for $e ($g->edges_from($v)) {
				next MAIN unless $seen{$e->[1]};
			}
			push $RET[-1], $v;
			$see{$v}++;
		}
		%seen = (%seen, %see);
	} while (scalar @{$RET[-1]});
	return \@RET;
}

sub dfg_mobility {
	my ($g, $asap, $alap) = @_;

	my %mobility = ();
	my $i = 0;
	for my $row (@{$asap}) {
		for my $v (@{$row}) {
			$mobility{$v}->[0] = $i;
		}
		$i++;
	}
	my $depth = $i;
	$i = 0;
	for my $row (@{$alap}) {
		for my $v (@{$row}) {
			$mobility{$v}->[1] = $depth - $i - 2 - $mobility{$v}->[0];
		}
		$i++;
	}
	return \%mobility;
}

sub get_inports {
	my $g = shift;

	my %seen = ();
	for my $v ($g->vertices) {
		my $vtype = $g->get_vertex_attribute($v, 'type');
		if ((defined $vtype) and ($vtype eq 'inport')) {
			$seen{$v}++;
		}
	}
	return \%seen;
}

sub get_vertices_by_color {
	my ($g, $color) = @_;
	my @V = ();
	for my $v ($g->vertices) {
		my $c = $g->get_vertex_attribute($v, 'color');
		if ((defined $c) and ($c eq $color)) {
			push (@V, $v);
		}
		my $t = $g->get_vertex_attribute($v, 'type');
		if ((defined $t) and ($t eq 'ouport')) {
			push (@V, $v);
		}
	}
	return \@V;
}

sub dump_stack {
	my $stack = shift;
#	return Dumper $stack;

	my $ret = "";

	for my $stack_element (@{$stack}) {
		$ret .= sprintf "%-24s" , ('(' . join (' ', @{$stack_element}) . ') ');
#		$ret .= sprintf " %-8s" , $$stack_element[0];
	}
	return "   " . $ret;
}

sub stack_match {
	my ($e, $ref) = @_;
	if ($$ref[0] eq $e) {
		return 1;
	}
	return 0;
}

sub stack_reduce {
	my ($stack, $index, $e) = @_;

	my $se = $stack->[$index];
	
#	if (scalar @{$se} < 3) {
#		splice ($stack, $index, 1);
#		return $stack;
#	}
	for (my $i = 0; $i < scalar (@{$se}); $i++) {
		if ($se->[$i] eq $e) {
			splice ($stack->[$index], $i, 1);
			last;
		}
	}
	return $stack;
}

sub vertex_destinations {
	my ($g, $v) = @_;

	my $ret = [$v];
	for my $e ($g->edges_from($v)) {
		push @{$ret}, $e->[1];
	}
	return $ret;
}

sub fisher_yates_shuffle {
	my $array = shift;
	my $i;
	for ($i = @$array; --$i; ) {
		my $j = int rand ($i+1);
		next if $i == $j;
		@$array[$i,$j] = @$array[$j,$i];
	}
}

# number of operands for operation
sub f_degree {
	my $before = shift;

	my $ret = 0;
	for my $i (@{$before}) {
		if ($i eq 'y') { $ret = 2; next; }
		if (($i eq 'x') and ($ret < 2)) { $ret = 1; }
	}
	return $ret;
}

# 0 - don't care
# 1 - 1 destination
# 2 - >1 destination
# 3 - no destinations
sub f_destinations {
	my ($before, $after) = @_;

	my $ret = [];
	my $len = scalar @{$before};
	for (my $i = 0; $i < $len; $i++) {
		my $current = $$before[$i];
		if (($current eq 'x') or ($current eq 'y')) {
			if ((defined $$after[$i]) and ($current eq $$after[$i])) {
				push @{$ret}, 2; # more x's
			} else {
				push @{$ret}, 1; # last x
			}
		} else {
			push @{$ret}, 3; # empty cell
			for my $j (@{$after}) {
				if ($current eq $j) {
					$$ret[-1] = 0;
					last;
				}
			}
		}
	}
	while ((scalar @{$ret}) and ($$ret[0] == 0)) {
		shift @{$ret};
	}
	return $ret;
}

# 0 - don't care
# 1 - x
# 2 - y
sub f_operands {
	my ($before, $after) = @_;

	my $ret = [];
	my $len = scalar @{$before};
	for (my $i = 0; $i < $len; $i++) {
		my $current = $$before[$i];
		if ($current eq 'x') {
			push @{$ret}, 1; # x
		} elsif ($current eq 'y') {
			push @{$ret}, 2; # y
		} else {
			push @{$ret}, 0; # empty cell
		}
	}
	while ((scalar @{$ret}) and ($$ret[0] == 0)) {
		shift @{$ret};
	}
	return $ret;
}

sub f_assembly {
	my ($before, $after) = @_;

	my $ret = [];
	my $len = scalar @{$after};
	M: for (my $i = 0; $i < $len; $i++) {
		my $current = $$after[$i];
		if ($current eq 'z') {
			push $ret, 0;
		} else {
			my $len_before = scalar @{$before};
			for (my $j = 1; $j <= $len_before; $j++) {
				if ($$before[-$j] eq $current) {
					push $ret, -$j;
					next M;
				}
			}
			die "Error! in euristic ( @{$before} -- @{$after} ), the element '$current' on stack apeared from nothing";
		}
	}
	return $ret;
}

sub read_eu {
	my $name = shift;

	open (INP, "<" . $name);
	my @A = ();
	for my $line (<INP>) {
		my @L = split(/\(|\-\-|\)/, $line);
		if ((scalar @L) > 2) {
			my $before   = [split (' ', $L[1])];
			my $after    = [split (' ', $L[2])];
			push @A, [
				[split (' ', $L[0])], # forth notation
				$before,
				$after,
				(scalar @{$before}),
				f_degree       ($before, $after),
				f_destinations ($before, $after),
				f_operands     ($before, $after),
				f_assembly     ($before, $after)
			];
		}
	}
	close INP;
	return \@A;
}

sub my_dumper {
	my $row = shift;

	my $ret = '';
	for my $col (@{$row}) {
		if (ref $col eq 'ARRAY') {
			$ret .= sprintf "%25s", join ' ', @{$col};
		} else {
			$ret .= sprintf "%2d", $col;
		}
		$ret .= ' | ';
	}
	$ret .= "\n";
	return $ret;
}

sub cfg_asap_new {
	my $g = shift;

	my @EU = @{read_eu('eu.txt')};

	my $max = 0;
	my $colors = dfg_colors($g);
	for my $color (@{$colors}) {
		my $seen = get_inports($g); # initial set of variables available
		my @OPS  = @{get_vertices_by_color($g, $color)}; # initial set of operations to schedule
		my $stack = []; # initial empty evaluation stack
		my $flag = 0;

		fisher_yates_shuffle (\@OPS);
		
		print "*** $color ****\n";
		my $iii = 0;
		M: for (0..100) {

			my @PRE = (); # all pretenders (may need to be sorted by mobility!!!)
			L1: for my $v (@OPS) {
				next if $seen->{$v};
				for my $e ($g->edges_to($v)) {
					next L1 unless $seen->{$e->[0]};
				}
				push @PRE, $v;
			}

			my $instruction = '';
			
			EU: for my $eu (@EU) {
				if ($eu->[3] == 0) { # fetch operands
					next M if (scalar (@PRE) == 0);

					my $v = $PRE[0]; # first in list
					L2: for my $e ($g->edges_to($v)) { # all data it requires
						my $efrom = $e->[0];
						for my $se (@{$stack}) {
							next L2 if ($$se[0] eq $efrom);
						}
						$instruction = "${efrom}@";
						push (@{$stack}, vertex_destinations ($g, $efrom));
						print sprintf ("%30s" , $instruction) . dump_stack ($stack) . "\n";
						$iii++;
						next M;
					}
					last M;
				}
				next if ((scalar @{$stack}) < $eu->[3]); # match the minimum number of stack enties

				my $top_len = scalar @{$eu->[5]};
				for (my $i = -$top_len; $i < 0; $i++) { # match the number of destinations
					my $mask = $eu->[5]->[$i];
					next if ($mask == 0);
					if ($mask == 1) {
						next if (scalar @{$stack->[$i]} == 2);
					} elsif ($mask == 2) {
						next if (scalar @{$stack->[$i]}  > 2);
					} else {
						next if (scalar @{$stack->[$i]}  < 2);
					}
					next EU;
				}

				CND: for my $v (@PRE) { # for all candidates
					next unless ($g->in_degree($v) == $eu->[4]); # match the number of arguments

					my @E_TO = $g->edges_to($v); # !!! must be sorted by edge headlabel
					for (my $i = -$top_len; $i < 0; $i++) { # match operands on the stack
						my $mask = $eu->[6]->[$i];
						next if ($mask == 0);
						if ($mask == 1) {
							next if (stack_match($E_TO[0]->[0], $stack->[$i]));
						} else {
							next if (stack_match($E_TO[1]->[0], $stack->[$i]));
						}
						next CND;
					}
					for (my $i = -$top_len; $i < 0; $i++) { # reduce
						my $mask = $eu->[6]->[$i];
						next if ($mask == 0);
						if ($mask == 1) {
							$stack = stack_reduce ($stack, $i, $E_TO[0]->[1]);
						} else {
							$stack = stack_reduce ($stack, $i, $E_TO[1]->[1]);
						}
					}
					my @NEWTOP = (); # new top of the stack
					for my $i (@{$eu->[7]}) {
						if ($i == 0) {
							push @NEWTOP, vertex_destinations ($g, $v); # new entry
						} else {
							push @NEWTOP, $stack->[$i]; # old entry
						}
					}
					# clean old stack top
					splice (@{$stack}, -($eu->[3]));
					# attach new stack top
					push (@{$stack}, @NEWTOP);
					$instruction = join (' ', @{$eu->[0]});
					my $vtype = $g->get_vertex_attribute($v, 'type');
					$instruction =~ s/\$/$vtype/;
					# insert operation ID

					# patch operation or node name
					$seen->{$v} += 1;
					$iii++;
					print sprintf ("%30s" , $instruction) . dump_stack ($stack) . "\n";
					next M;
				}
			}
			last;
		}
		print "REMINDER: ";
		for my $v (@OPS) {
			next if $seen->{$v};
			my $t = $g->get_vertex_attribute($v, 'type');
			next unless defined $t;
			next if ($t eq 'ouport');
			print " $v";
		}
		print "\n";
		print "LEN:$iii\n";
		$max = $iii if ($iii > $max);
	}
	return $max;
}

{
my @COLORS = qw(tomato yellow cyan violet orange greenyellow skyblue fuchsia);

my @A1 = (
[ 1, 0, 0, 0, 0, 0, 0, 0],
[ 0, 1, 0, 0, 0, 0, 0, 1],
[ 0, 0, 1, 0, 0, 0, 1, 0],
[ 0, 0, 0, 1, 0, 1, 0, 0],
[ 0, 0, 0, 0, 1, 0, 0, 0],
[ 0, 0, 0, 1, 0,-1, 0, 0],
[ 0, 0, 1, 0, 0, 0,-1, 0],
[ 0, 1, 0, 0, 0, 0, 0,-1]
);
my @A2 = (
[ 1, 0, 0, 0, 1, 0, 0, 0],
[ 0,-1, 0, 1, 0, 0, 0, 0],
[ 0, 0, 1, 0, 0, 0, 0, 0],
[ 0, 1, 0, 1, 0, 0, 0, 0],
[ 1, 0, 0, 0,-1, 0, 0, 0],
[ 0, 0, 0, 0, 0,-1, 0, 1],
[ 0, 0, 0, 0, 0, 0, 1, 0],
[ 0, 0, 0, 0, 0, 1, 0, 1]
);
my @A3 = (
[ 1, 0, 1, 0, 0, 0, 0, 0],
[ 0, 1, 0, 0, 0, 0, 0, 0],
[ 1, 0,-1, 0, 0, 0, 0, 0],
[ 0, 0, 0, 0, 1, 0, 0, 0],
[ 0, 0, 0, 1, 0, 0, 0, 0],
[ 0, 0, 0, 0, 0, 0, 1, 0],
[ 0, 0, 0, 0, 0, 1, 0, 0],
[ 0, 0, 0, 0, 0, 0, 0, 1]
);
my @M = (
[ 1,  0,  0,  0,  0,  0,  0,  0],
[ 0,'a',  0,  0,  0,  0,  0,  0],
[ 0,  0,  1,  0,  0,  0,  0,  0],
[ 0,  0,  0,  1,  0,  0,  0,  0],
[ 0,  0,  0,  0,  1,  0,  0,  0],
[ 0,  0,  0,  0,  0,'i',  0,  0],
[ 0,  0,  0,  0,  0,  0,'i',  0],
[ 0,  0,  0,  0,  0,  0,  0,'b']
);
my @D = (
[ 1, 0, 0, 0, 0, 0, 0, 0],
[ 0, 1, 0, 0, 0, 0, 0, 0],
[ 0, 0, 1, 0, 0, 0, 0, 0],
[ 0, 0, 0, 1, 0, 0, 0, 0],
[ 0, 0, 0, 0, 1, 0, 0, 0],
[ 0, 0, 0, 0, 0, 1, 0, 0],
[ 0, 0, 0, 0, 0, 0, 1, 0],
[ 0, 0, 0, 0, 0, 0, 0, 1]
);
my @RADIX8 = (\@A1, \@A2, \@M, \@A3, \@A2, \@A1, \@D);



my $g0 = Graph->new;
my $w0 = Graph::Writer::Dot->new();

layers($g0, \@RADIX8);
for my $v ($g0->vertices) {$g0->set_vertex_attribute($v, 'shape', 'point');}
$w0->write_graph ($g0, 'dot\00.dot');

operations($g0);
index_ports($g0);
$w0->write_graph ($g0, 'dot\01.dot');

clean1($g0);
clean2($g0);
$w0->write_graph ($g0, 'dot\02.dot');

my $asap = dfg_asap($g0);
my $alap = dfg_alap($g0);
#print Dumper ($alap);
my $parallelism = 0;
for my $row (@{$asap}) {
	if (scalar (@{$row}) > $parallelism) {
		$parallelism = scalar (@{$row});
	}
}
print scalar @{$asap} . "-" . $parallelism . "\n";
#print Dumper dfg_mobility($g0, $asap, $alap);

my @CODE6 = (
['re-1,1', 're-1,3', 're-2,3', 're-2,1', 're-3,1', 're-5,1', 're-5,3', 're-6,1', 're-6,3'],
['re-1,7', 're-1,5', 're-2,5', 're-2,7', 're-3,7', 're-5,7', 're-5,5', 're-6,7', 're-6,5'],
['re-1,6', 're-1,2', 're-2,4', 're-2,0', 're-4,0', 're-4,2', 're-5,0', 're-5,4', 're-6,2', 're-6,6'],
['im-1,1', 'im-1,3', 'im-2,3', 'im-2,1', 'im-3,1', 'im-5,1', 'im-5,3', 'im-6,1', 'im-6,3'],
['im-1,7', 'im-1,5', 'im-2,5', 'im-2,7', 'im-3,7', 'im-5,7', 'im-5,5', 'im-6,7', 'im-6,5'],
['im-1,6', 'im-1,2', 'im-2,4', 'im-2,0', 'im-4,0', 'im-4,2', 'im-5,0', 'im-5,4', 'im-6,2', 'im-6,6'],
);

my @CODE2 = (
[ qw (re-1,6 re-1,2 re-1,7 re-1,1 re-1,3 re-1,5 re-2,5 re-2,7 re-3,7 re-2,1 re-2,3 re-3,1 re-5,7 re-5,5 re-2,0 re-2,4 re-5,1 re-6,1 re-6,7 re-5,3 re-6,5 re-6,3 re-4,2 re-4,0 re-5,4 re-5,0 re-6,2 re-6,6)],
[ qw (im-1,6 im-1,2 im-1,7 im-1,1 im-1,3 im-1,5 im-2,5 im-2,7 im-3,7 im-2,1 im-2,3 im-3,1 im-5,7 im-5,5 im-2,0 im-2,4 im-5,1 im-6,1 im-6,7 im-5,3 im-6,5 im-6,3 im-4,2 im-4,0 im-5,4 im-5,0 im-6,2 im-6,6)],
);

colorize($g0, \@CODE2, \@COLORS);
$w0->write_graph ($g0, 'dot\03.dot');


my $g1 = Graph->new;
node_map($g0, $g1);
my $w1 = Graph::Writer::Dot->new();
$w1->write_graph ($g1, 'dot\map.dot');

decouple($g0);
decouple_inports($g0);
$w0->write_graph ($g0, 'dot\04.dot');

my $timer = time();
my $maxxxx = 0;
for (0..3) {
	my $tmax = cfg_asap_new ($g0);
	$maxxxx = $tmax if ($tmax > $maxxxx);
}
print "MAX:$maxxxx\n";
print "TIME:" .  (time() - $timer);

#print Dumper (dfg_colors($g0));

straighten($g0, \@CODE2, \@COLORS);
$w0->write_graph ($g0, 'dot\05.dot');

straighten_ouports($g0);
straighten_inports($g0);
$w0->write_graph ($g0, 'dot\06.dot');

}
