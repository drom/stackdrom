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

sub e_drop                                      { # drop                        ( .                 --                       )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	if (
		(scalar (@{$stack}) > 0) and
		(scalar @{$stack->[-1]} < 2)
	) {
		pop @{$stack};
		$instruction = "drop";
		return (1, $stack, $seen, $instruction);
	}
	return (0, $stack, $seen, $instruction);
}
sub e_nip                                       { # nip                         ( .   a             -- a                     )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	if (
		(scalar (@{$stack}) > 1) and
		(scalar @{$stack->[-2]} < 2)
	) {
		my $tmp = pop @{$stack};
		pop @{$stack};
		push @{$stack}, $tmp;
		$instruction = "nip";
		return (1, $stack, $seen, $instruction);
	}
	return (0, $stack, $seen, $instruction);
}
sub e_to_r_nip_r_from                           { # >r nip r>                   ( .   a   b         -- a   b                 )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	if (
		(scalar (@{$stack}) > 2) and
		(scalar @{$stack->[-3]} < 2)
	) {
		my $a = pop @{$stack};
		my $b = pop @{$stack};
		pop  @{$stack};
		push @{$stack}, $b;
		push @{$stack}, $a;

		$instruction = ">r nip r>";
		return (1, $stack, $seen, $instruction);
	}
	return (0, $stack, $seen, $instruction);
}
sub e_to_r_to_r_nip_r_from_r_from               { # >r >r nip r> r>             ( .   a   b   c     -- a   b   c             )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	if (
		(scalar (@{$stack}) > 3) and
		(scalar @{$stack->[-4]} < 2)
	) {
		my $c = pop @{$stack};
		my $b = pop @{$stack};
		my $a = pop @{$stack};
		pop  @{$stack};
		push @{$stack}, $a;
		push @{$stack}, $b;
		push @{$stack}, $c;

		$instruction = ">r >r nip r> r>";
		return (1, $stack, $seen, $instruction);
	}
	return (0, $stack, $seen, $instruction);
}

sub e_ouport_store                              { # ouport!                     ( x0                --                       )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (($g->in_degree($v) == 1) and (scalar (@{$stack}) > 0)) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[0]->[0], $stack->[-1])) and
				(scalar @{$stack->[-1]} == 2)              and
				($g->get_vertex_attribute($v, 'type') eq 'ouport')
			) {
				pop @{$stack};
				
				$instruction = "${v}!";
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_dup_ouport_store                          { # dup ouport!                 ( x0'               -- x0'                   )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (($g->in_degree($v) == 1) and (scalar (@{$stack}) > 0)) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[0]->[0], $stack->[-1])) and
				(scalar @{$stack->[-1]} >  2)              and
				($g->get_vertex_attribute($v, 'type') eq 'ouport')
			) {
				$stack = stack_reduce ($stack, -1, $E_TO[0]->[1]);
				
				$instruction = "dup ${v}!";
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_swap_ouport_store                         { # swap ouport!                ( x0  a             -- a                     )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (($g->in_degree($v) == 1) and (scalar (@{$stack}) > 1)) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[0]->[0], $stack->[-2])) and
				(scalar @{$stack->[-2]} == 2)              and
				($g->get_vertex_attribute($v, 'type') eq 'ouport')
			) {
				my $a = pop @{$stack};
				pop @{$stack};
				push @{$stack}, $a;

				$instruction = "swap ${v}!";
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_over_ouport_store                         { # over ouport!                ( x0' a             -- x0' a                 )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (($g->in_degree($v) == 1) and (scalar (@{$stack}) > 1)) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[0]->[0], $stack->[-2])) and
				(scalar @{$stack->[-2]} >  2)              and
				($g->get_vertex_attribute($v, 'type') eq 'ouport')
			) {
				$stack = stack_reduce ($stack, -2, $E_TO[0]->[1]);

				$instruction = "over ${v}!";
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}

sub e_op1                                       { # op1                         ( x0                -- y                     )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (($g->in_degree($v) == 1) and (scalar (@{$stack}) > 0)) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[0]->[0], $stack->[-1])) and
				(scalar @{$stack->[-1]} == 2)
			) {
				pop @{$stack};
				push (@{$stack}, vertex_destinations($g, $v));

				$instruction = $g->get_vertex_attribute($v, 'type');
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_swap_op1                                  { # swap op1                    ( x0  a             -- a   y                 )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (($g->in_degree($v) == 1) and (scalar (@{$stack}) > 1)) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[0]->[0], $stack->[-2])) and
				(scalar @{$stack->[-2]} == 2)
			) {
				my $a = pop @{$stack};
				pop  @{$stack};
				push @{$stack}, $a;
				push @{$stack}, vertex_destinations($g, $v);

				$instruction = "swap " . $g->get_vertex_attribute($v, 'type');
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_dup_op1                                   { # dup op1                     ( x0'               -- x0' y                 )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (($g->in_degree($v) == 1) and (scalar (@{$stack}) > 0)) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[0]->[0], $stack->[-1])) and
				(scalar @{$stack->[-1]} >  2)
			) {
				$stack = stack_reduce ($stack, -1, $E_TO[0]->[1]);
				push (@{$stack}, vertex_destinations($g, $v));

				$instruction = "dup " . $g->get_vertex_attribute($v, 'type');
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_over_op1                                  { # over op1                    ( x0' a             -- x0' a   y             )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (($g->in_degree($v) == 1) and (scalar (@{$stack}) > 1)) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[0]->[0], $stack->[-2])) and
				(scalar @{$stack->[-2]} >  2)
			) {
				$stack = stack_reduce ($stack, -2, $E_TO[0]->[1]);
				push (@{$stack}, vertex_destinations($g, $v));

				$instruction = "over " . $g->get_vertex_attribute($v, 'type');
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}

sub e_op2_a                                     { # op2                         ( x1  x0            -- y                     )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (($g->in_degree($v) == 2) and (scalar (@{$stack}) > 1)) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[0]->[0], $stack->[-1])) and
				(scalar @{$stack->[-1]} == 2)              and
				(stack_match($E_TO[1]->[0], $stack->[-2])) and
				(scalar @{$stack->[-2]} == 2)
			) {
				pop @{$stack};
				pop @{$stack};
				push (@{$stack}, vertex_destinations($g, $v));

				$instruction = $g->get_vertex_attribute($v, 'type');
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_op2_b                                     { # op2                         ( x0  x1            -- y                     )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (($g->in_degree($v) == 2) and (scalar (@{$stack}) > 1)) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[1]->[0], $stack->[-1])) and
				(scalar @{$stack->[-1]} == 2)              and
				(stack_match($E_TO[0]->[0], $stack->[-2])) and
				(scalar @{$stack->[-2]} == 2)
			) {
				pop @{$stack};
				pop @{$stack};
				push (@{$stack}, vertex_destinations($g, $v));

				$instruction = $g->get_vertex_attribute($v, 'type');
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_over_op2_a                                { # over op2                    ( x1' x0            -- x1' y                 )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (
			($g->in_degree($v) == 2) and 
			(scalar (@{$stack}) > 1)
		) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[0]->[0], $stack->[-1])) and
				(scalar @{$stack->[-1]} == 2)              and
				(stack_match($E_TO[1]->[0], $stack->[-2])) and
				(scalar @{$stack->[-2]} > 2)
			) {
				pop @{$stack};
				$stack = stack_reduce ($stack, -1, $E_TO[1]->[1]);
				push (@{$stack}, vertex_destinations($g, $v));

				$instruction = "over " . $g->get_vertex_attribute($v, 'type');
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_over_op2_b                                { # over op2                    ( x0' x1            -- x0' y                 )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (
			($g->in_degree($v) == 2) and 
			(scalar (@{$stack}) > 1)
		) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[0]->[0], $stack->[-2])) and
				(scalar @{$stack->[-2]} > 2)               and
				(stack_match($E_TO[1]->[0], $stack->[-1])) and
				(scalar @{$stack->[-1]} == 2)
			) {
				pop @{$stack};
				$stack = stack_reduce ($stack, -1, $E_TO[0]->[1]);
				push (@{$stack}, vertex_destinations($g, $v));

				$instruction = "over " . $g->get_vertex_attribute($v, 'type');
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_swap_over_op2_a                           { # swap over op2               ( x1  x0'           -- x0' y                 )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (
			($g->in_degree($v) == 2) and 
			(scalar (@{$stack}) > 1)
		) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[0]->[0], $stack->[-1])) and
				(scalar @{$stack->[-1]} > 2)              and
				(stack_match($E_TO[1]->[0], $stack->[-2])) and
				(scalar @{$stack->[-2]} == 2)
			) {
				my $tmp = pop @{$stack}; 
				pop @{$stack};
				push @{$stack}, $tmp;
				$stack = stack_reduce ($stack, -1, $E_TO[0]->[1]);
				push (@{$stack}, vertex_destinations($g, $v));

				$instruction = "swap over " . $g->get_vertex_attribute($v, 'type');
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_swap_over_op2_b                           { # swap over op2               ( x0  x1'           -- x1' y                 )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (
			($g->in_degree($v) == 2) and 
			(scalar (@{$stack}) > 1)
		) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[1]->[0], $stack->[-1])) and
				(scalar @{$stack->[-1]} > 2)              and
				(stack_match($E_TO[0]->[0], $stack->[-2])) and
				(scalar @{$stack->[-2]} == 2)
			) {
				my $tmp = pop @{$stack}; 
				pop @{$stack};
				push @{$stack}, $tmp;
				$stack = stack_reduce ($stack, -1, $E_TO[1]->[1]);
				push (@{$stack}, vertex_destinations($g, $v));

				$instruction = "swap over " . $g->get_vertex_attribute($v, 'type');
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_2dup_op2_a                                { # 2dup op2                    ( x1' x0'           -- x1' x0' y             )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (
			($g->in_degree($v) == 2) and 
			(scalar (@{$stack}) > 1)
		) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[0]->[0], $stack->[-1])) and
				(scalar @{$stack->[-1]} > 2)              and
				(stack_match($E_TO[1]->[0], $stack->[-2])) and
				(scalar @{$stack->[-2]} > 2)
			) {
				$stack = stack_reduce ($stack, -1, $E_TO[0]->[1]);
				$stack = stack_reduce ($stack, -2, $E_TO[1]->[1]);
				push (@{$stack}, vertex_destinations($g, $v));

				$instruction = "2dup " . $g->get_vertex_attribute($v, 'type');
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_2dup_op2_b                                { # 2dup op2                    ( x0' x1'           -- x0' x1' y             )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (
			($g->in_degree($v) == 2) and 
			(scalar (@{$stack}) > 1)
		) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[1]->[0], $stack->[-1])) and
				(scalar @{$stack->[-1]} > 2)              and
				(stack_match($E_TO[0]->[0], $stack->[-2])) and
				(scalar @{$stack->[-2]} > 2)
			) {
				$stack = stack_reduce ($stack, -1, $E_TO[1]->[1]);
				$stack = stack_reduce ($stack, -2, $E_TO[0]->[1]);
				push (@{$stack}, vertex_destinations($g, $v));

				$instruction = "2dup " . $g->get_vertex_attribute($v, 'type');
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}

sub e_to_r_op2_r_from_a                         { # >r op2 r>                   ( x0  x1  a         -- y   a                 )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (
			($g->in_degree($v) == 2) and
			(scalar (@{$stack}) > 2)
		) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[0]->[0], $stack->[-3])) and
				(scalar @{$stack->[-3]} == 2)              and
				(stack_match($E_TO[1]->[0], $stack->[-2])) and
				(scalar @{$stack->[-2]} == 2)
			) {
				my $a = pop @{$stack};
				pop  @{$stack};
				pop  @{$stack};
				push @{$stack}, vertex_destinations($g, $v);
				push @{$stack}, $a;
				
				$instruction = ">r " . $g->get_vertex_attribute($v, 'type') . " r>";
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_to_r_op2_r_from_b                         { # >r op2 r>                   ( x1  x0  a         -- y   a                 )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (
			($g->in_degree($v) == 2) and
			(scalar (@{$stack}) > 2)
		) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[0]->[0], $stack->[-2])) and
				(scalar @{$stack->[-2]} == 2)              and
				(stack_match($E_TO[1]->[0], $stack->[-3])) and
				(scalar @{$stack->[-3]} == 2)
			) {
				my $a = pop @{$stack};
				pop  @{$stack};
				pop  @{$stack};
				push @{$stack}, vertex_destinations($g, $v);
				push @{$stack}, $a;
				
				$instruction = ">r " . $g->get_vertex_attribute($v, 'type') . " r>";
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_to_r_to_r_op2_r_from_r_from_a             { # >r >r op2 r> r>             ( x0  x1  a   b     -- y   a   b             )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (
			($g->in_degree($v) == 2) and
			(scalar (@{$stack}) > 3)
		) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[0]->[0], $stack->[-4])) and
				(scalar @{$stack->[-4]} == 2)              and
				(stack_match($E_TO[1]->[0], $stack->[-3])) and
				(scalar @{$stack->[-3]} == 2)
			) {
				my $b = pop @{$stack};
				my $a = pop @{$stack};
				pop  @{$stack};
				pop  @{$stack};
				push @{$stack}, vertex_destinations($g, $v);
				push @{$stack}, $a;
				push @{$stack}, $b;
				
				$instruction = ">r >r " . $g->get_vertex_attribute($v, 'type') . " r> r>";
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_to_r_to_r_op2_r_from_r_from_b             { # >r >r op2 r> r>             ( x1  x0  a   b     -- y   a   b             )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (
			($g->in_degree($v) == 2) and
			(scalar (@{$stack}) > 2)
		) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[0]->[0], $stack->[-3])) and
				(scalar @{$stack->[-3]} == 2)              and
				(stack_match($E_TO[1]->[0], $stack->[-4])) and
				(scalar @{$stack->[-4]} == 2)
			) {
				my $b = pop @{$stack};
				my $a = pop @{$stack};
				pop  @{$stack};
				pop  @{$stack};
				push @{$stack}, vertex_destinations($g, $v);
				push @{$stack}, $a;
				push @{$stack}, $b;
				
				$instruction = ">r >r " . $g->get_vertex_attribute($v, 'type') . " r> r>";
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_swap_to_r_op2_r_from_a                    { # swap >r op2 r>              ( x0  a   x1        -- y   a                 )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (
			($g->in_degree($v) == 2) and
			(scalar (@{$stack}) > 2)
		) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[0]->[0], $stack->[-3])) and
				(scalar @{$stack->[-3]} == 2)              and
				(stack_match($E_TO[1]->[0], $stack->[-1])) and
				(scalar @{$stack->[-1]} == 2)
			) {
				pop  @{$stack};
				my $a = pop @{$stack};
				pop  @{$stack};
				push @{$stack}, vertex_destinations($g, $v);
				push @{$stack}, $a;
				
				$instruction = "swap >r " . $g->get_vertex_attribute($v, 'type') . " r>";
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_swap_to_r_op2_r_from_b                    { # swap >r op2 r>              ( x1  a   x0        -- y   a                 )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (
			($g->in_degree($v) == 2) and
			(scalar (@{$stack}) > 2)
		) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[0]->[0], $stack->[-1])) and
				(scalar @{$stack->[-1]} == 2)              and
				(stack_match($E_TO[1]->[0], $stack->[-3])) and
				(scalar @{$stack->[-3]} == 2)
			) {
				pop  @{$stack};
				my $a = pop @{$stack};
				pop  @{$stack};
				push @{$stack}, vertex_destinations($g, $v);
				push @{$stack}, $a;
				
				$instruction = "swap >r " . $g->get_vertex_attribute($v, 'type') . " r>";
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_to_r_swap_to_r_op2_r_from_r_from_a        { # >r swap >r op2 r> r>        ( x0  a   x1  b     -- y   a   b             )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (
			($g->in_degree($v) == 2) and
			(scalar (@{$stack}) > 3)
		) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[0]->[0], $stack->[-4])) and
				(scalar @{$stack->[-4]} == 2)              and
				(stack_match($E_TO[1]->[0], $stack->[-2])) and
				(scalar @{$stack->[-2]} == 2)
			) {
				my $b = pop @{$stack};
				pop  @{$stack};
				my $a = pop @{$stack};
				pop  @{$stack};
				push @{$stack}, vertex_destinations($g, $v);
				push @{$stack}, $a;
				push @{$stack}, $b;
				
				$instruction = ">r swap >r " . $g->get_vertex_attribute($v, 'type') . " r> r>";
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_to_r_swap_to_r_op2_r_from_r_from_b        { # >r swap >r op2 r> r>        ( x1  a   x0  b     -- y   a   b             )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (
			($g->in_degree($v) == 2) and
			(scalar (@{$stack}) > 3)
		) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[0]->[0], $stack->[-2])) and
				(scalar @{$stack->[-2]} == 2)              and
				(stack_match($E_TO[1]->[0], $stack->[-4])) and
				(scalar @{$stack->[-4]} == 2)
			) {
				my $b = pop @{$stack};
				pop  @{$stack};
				my $a = pop @{$stack};
				pop  @{$stack};
				push @{$stack}, vertex_destinations($g, $v);
				push @{$stack}, $a;
				push @{$stack}, $b;
				
				$instruction = ">r swap >r " . $g->get_vertex_attribute($v, 'type') . " r> r>";
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_swap_to_r_swap_to_r_op2_r_from_r_from_a   { # swap >r swap >r op2 r> r>   ( x0  a   b   x1    -- y   a   b             )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (
			($g->in_degree($v) == 2) and
			(scalar (@{$stack}) > 3)
		) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[0]->[0], $stack->[-4])) and
				(scalar @{$stack->[-4]} == 2)              and
				(stack_match($E_TO[1]->[0], $stack->[-1])) and
				(scalar @{$stack->[-1]} == 2)
			) {
				pop  @{$stack};
				my $b = pop @{$stack};
				my $a = pop @{$stack};
				pop  @{$stack};
				push @{$stack}, vertex_destinations($g, $v);
				push @{$stack}, $a;
				push @{$stack}, $b;
				
				$instruction = "swap >r swap >r " . $g->get_vertex_attribute($v, 'type') . " r> r>";
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_swap_to_r_swap_to_r_op2_r_from_r_from_b   { # swap >r swap >r op2 r> r>   ( x0  a   b   x1    -- y   a   b             )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (
			($g->in_degree($v) == 2) and
			(scalar (@{$stack}) > 3)
		) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[0]->[0], $stack->[-1])) and
				(scalar @{$stack->[-1]} == 2)              and
				(stack_match($E_TO[1]->[0], $stack->[-4])) and
				(scalar @{$stack->[-4]} == 2)
			) {
				pop  @{$stack};
				my $b = pop @{$stack};
				my $a = pop @{$stack};
				pop  @{$stack};
				push @{$stack}, vertex_destinations($g, $v);
				push @{$stack}, $a;
				push @{$stack}, $b;
				
				$instruction = "swap >r swap >r " . $g->get_vertex_attribute($v, 'type') . " r> r>";
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_to_r_over_op2_r_from_a                    { # >r over op2 r>              ( x1' x0  a         -- x1' y   a             )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (
			($g->in_degree($v) == 2) and 
			(scalar (@{$stack}) > 2)
		) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[0]->[0], $stack->[-2])) and
				(scalar @{$stack->[-2]} == 2)              and
				(stack_match($E_TO[1]->[0], $stack->[-3])) and
				(scalar @{$stack->[-3]} > 2)
			) {
				my $a = pop @{$stack};
				$stack = stack_reduce ($stack, -2, $E_TO[1]->[1]);
				push @{$stack}, vertex_destinations($g, $v);
				push @{$stack}, $a;

				$instruction = ">r over " . $g->get_vertex_attribute($v, 'type') . " >r";
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_to_r_over_op2_r_from_b                    { # >r over op2 r>              ( x0' x1  a         -- x0' y   a             )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (
			($g->in_degree($v) == 2) and 
			(scalar (@{$stack}) > 2)
		) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[1]->[0], $stack->[-2])) and
				(scalar @{$stack->[-2]} == 2)              and
				(stack_match($E_TO[0]->[0], $stack->[-3])) and
				(scalar @{$stack->[-3]} > 2)
			) {
				my $a = pop @{$stack};
				$stack = stack_reduce ($stack, -2, $E_TO[0]->[1]);
				push @{$stack}, vertex_destinations($g, $v);
				push @{$stack}, $a;

				$instruction = ">r over " . $g->get_vertex_attribute($v, 'type') . " >r";
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_to_r_swap_over_op2_r_from_a               { # >r swap over op2 r>         ( x1  x0' a         -- x0' y   a             )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (
			($g->in_degree($v) == 2) and 
			(scalar (@{$stack}) > 2)
		) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[0]->[0], $stack->[-2])) and
				(scalar @{$stack->[-2]} >  2)              and
				(stack_match($E_TO[1]->[0], $stack->[-3])) and
				(scalar @{$stack->[-3]} == 2)
			) {
				my $a = pop @{$stack};
				$stack = stack_reduce ($stack, -1, $E_TO[0]->[1]);
				push @{$stack}, vertex_destinations($g, $v);
				push @{$stack}, $a;

				$instruction = ">r swap over " . $g->get_vertex_attribute($v, 'type') . " >r";
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_to_r_swap_over_op2_r_from_b               { # >r swap over op2 r>         ( x0  x1' a         -- x1' y   a             )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (
			($g->in_degree($v) == 2) and 
			(scalar (@{$stack}) > 2)
		) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[1]->[0], $stack->[-2])) and
				(scalar @{$stack->[-2]} >  2)              and
				(stack_match($E_TO[0]->[0], $stack->[-3])) and
				(scalar @{$stack->[-3]} == 2)
			) {
				my $a = pop @{$stack};
				$stack = stack_reduce ($stack, -1, $E_TO[1]->[1]);
				push @{$stack}, vertex_destinations($g, $v);
				push @{$stack}, $a;

				$instruction = ">r swap over " . $g->get_vertex_attribute($v, 'type') . " >r";
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_to_r_2dup_op2_r_from_a                    { # >r 2dup op2 r>              ( x0' x1' a         -- x0' x1' y   a         )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (
			($g->in_degree($v) == 2) and
			(scalar (@{$stack}) > 2)
		) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[0]->[0], $stack->[-3])) and
				(scalar @{$stack->[-3]} >  2)              and
				(stack_match($E_TO[1]->[0], $stack->[-2])) and
				(scalar @{$stack->[-2]} >  2)
			) {
				my $a = pop @{$stack};
				$stack = stack_reduce ($stack, -1, $E_TO[1]->[1]);
				$stack = stack_reduce ($stack, -2, $E_TO[0]->[1]);

				push @{$stack}, vertex_destinations($g, $v);
				push @{$stack}, $a;
				
				$instruction = ">r 2dup " . $g->get_vertex_attribute($v, 'type') . " r>";
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_to_r_2dup_op2_r_from_b                    { # >r 2dup op2 r>              ( x1' x0' a         -- x1' x0' y   a         )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (
			($g->in_degree($v) == 2) and
			(scalar (@{$stack}) > 2)
		) {
			my @E_TO = $g->edges_to($v);
			if (
				(stack_match($E_TO[0]->[0], $stack->[-2])) and
				(scalar @{$stack->[-2]} >  2)              and
				(stack_match($E_TO[1]->[0], $stack->[-3])) and
				(scalar @{$stack->[-3]} >  2)
			) {
				my $a = pop @{$stack};
				$stack = stack_reduce ($stack, -1, $E_TO[0]->[1]);
				$stack = stack_reduce ($stack, -2, $E_TO[1]->[1]);
				push @{$stack}, vertex_destinations($g, $v);
				push @{$stack}, $a;
				
				$instruction = ">r 2dup " . $g->get_vertex_attribute($v, 'type') . " r>";
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}

sub e_2_pick_op2_a                              { # 2 pick op2                  ( x0? a   x1        -- x0' a   y             )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (($g->in_degree($v) == 2) and (scalar (@{$stack}) > 2)) {
			my @E_TO = $g->edges_to($v);
			if (
				stack_match($E_TO[0]->[0], $stack->[-3]) and
				(scalar @{$stack->[-3]} >  2)            and
				stack_match($E_TO[1]->[0], $stack->[-1]) and
				(scalar @{$stack->[-1]} == 2)
			) {
				pop @{$stack};
				$stack = stack_reduce ($stack, -2, $E_TO[0]->[1]);
				push (@{$stack}, vertex_destinations($g, $v));

				$instruction = "2 pick " . $g->get_vertex_attribute($v, 'type');
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_2_pick_op2_b                              { # 2 pick op2                  ( x1? a   x0        -- x1' a   y             )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (($g->in_degree($v) == 2) and (scalar (@{$stack}) > 2)) {
			my @E_TO = $g->edges_to($v);
			if (
				stack_match($E_TO[0]->[0], $stack->[-1]) and
				(scalar @{$stack->[-1]} == 2)            and
				stack_match($E_TO[1]->[0], $stack->[-3]) and
				(scalar @{$stack->[-1]} >  2)
			) {
				pop @{$stack};
				$stack = stack_reduce ($stack, -2, $E_TO[1]->[1]);
				push (@{$stack}, vertex_destinations($g, $v));

				$instruction = "2 pick " . $g->get_vertex_attribute($v, 'type');
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_2_pick_over_op2_a                         { # 2 pick over op2             ( x0? a   x1'       -- x0' a   x1' y         )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (($g->in_degree($v) == 2) and (scalar (@{$stack}) > 2)) {
			my @E_TO = $g->edges_to($v);
			if (
				stack_match($E_TO[0]->[0], $stack->[-3]) and
				(scalar @{$stack->[-3]} > 1)             and
				stack_match($E_TO[1]->[0], $stack->[-1]) and
				(scalar @{$stack->[-1]} > 2)
			) {
				$stack = stack_reduce ($stack, -3, $E_TO[0]->[1]);
				$stack = stack_reduce ($stack, -1, $E_TO[1]->[1]);
				push (@{$stack}, vertex_destinations($g, $v));

				$instruction = "2 pick over " . $g->get_vertex_attribute($v, 'type');
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_2_pick_over_op2_b                         { # 2 pick over op2             ( x1? a   x0'       -- x1' a   x0' y         )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (($g->in_degree($v) == 2) and (scalar (@{$stack}) > 2)) {
			my @E_TO = $g->edges_to($v);
			if (
				stack_match($E_TO[0]->[0], $stack->[-1]) and
				(scalar @{$stack->[-1]} > 2)             and
				stack_match($E_TO[1]->[0], $stack->[-3]) and
				(scalar @{$stack->[-3]} > 1)
			) {
				$stack = stack_reduce ($stack, -1, $E_TO[0]->[1]);
				$stack = stack_reduce ($stack, -3, $E_TO[1]->[1]);
				push (@{$stack}, vertex_destinations($g, $v));

				$instruction = "2 pick over " . $g->get_vertex_attribute($v, 'type');
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_to_r_2_pick_op2_r_from_a                  { # >r 2 pick op2 r>            ( x0? a   x1  b     -- x0' a   y   b         )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (($g->in_degree($v) == 2) and (scalar (@{$stack}) > 3)) {
			my @E_TO = $g->edges_to($v);
			if (
				stack_match($E_TO[1]->[0], $stack->[-2]) and
				(scalar @{$stack->[-2]} == 2)             and
				stack_match($E_TO[0]->[0], $stack->[-4]) and
				(scalar @{$stack->[-4]} >  1)
			) {
				my $b = pop @{$stack};
				pop  @{$stack}; # x1
				$stack = stack_reduce ($stack, -2, $E_TO[0]->[1]);
				push @{$stack}, vertex_destinations($g, $v);
				push @{$stack}, $b;

				$instruction = ">r 2 pick " . $g->get_vertex_attribute($v, 'type') . " r>";
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_to_r_2_pick_op2_r_from_b                  { # >r 2 pick op2 r>            ( x1? a   x0  b     -- x1' a   y   b         )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (($g->in_degree($v) == 2) and (scalar (@{$stack}) > 3)) {
			my @E_TO = $g->edges_to($v);
			if (
				stack_match($E_TO[0]->[0], $stack->[-2]) and
				(scalar @{$stack->[-2]} == 2)             and
				stack_match($E_TO[1]->[0], $stack->[-4]) and
				(scalar @{$stack->[-4]} >  1)
			) {
				my $b = pop @{$stack};
				pop  @{$stack}; # x0
				$stack = stack_reduce ($stack, -2, $E_TO[1]->[1]);
				push @{$stack}, vertex_destinations($g, $v);
				push @{$stack}, $b;

				$instruction = ">r 2 pick " . $g->get_vertex_attribute($v, 'type') . " r>";
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_to_r_2_pick_over_op2_r_from_a             { # >r 2 pick over op2 r>       ( x0? a   x1' b     -- x0' a   x1' y   b     )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (($g->in_degree($v) == 2) and (scalar (@{$stack}) > 3)) {
			my @E_TO = $g->edges_to($v);
			if (
				stack_match($E_TO[1]->[0], $stack->[-2]) and
				(scalar @{$stack->[-2]} >  2)            and
				stack_match($E_TO[0]->[0], $stack->[-4]) and
				(scalar @{$stack->[-4]} >  1)
			) {
				my $b = pop @{$stack};
				$stack = stack_reduce ($stack, -1, $E_TO[1]->[1]);
				$stack = stack_reduce ($stack, -3, $E_TO[0]->[1]);
				push @{$stack}, vertex_destinations($g, $v);
				push @{$stack}, $b;

				$instruction = ">r 2 pick over " . $g->get_vertex_attribute($v, 'type') . " r>";
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_to_r_2_pick_over_op2_r_from_b             { # >r 2 pick over op2 r>       ( x1? a   x0' b     -- x1' a   x0' y   b     )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (($g->in_degree($v) == 2) and (scalar (@{$stack}) > 3)) {
			my @E_TO = $g->edges_to($v);
			if (
				stack_match($E_TO[0]->[0], $stack->[-2]) and
				(scalar @{$stack->[-2]} >  2)            and
				stack_match($E_TO[1]->[0], $stack->[-4]) and
				(scalar @{$stack->[-4]} >  1)
			) {
				my $b = pop @{$stack};
				$stack = stack_reduce ($stack, -1, $E_TO[0]->[1]);
				$stack = stack_reduce ($stack, -3, $E_TO[1]->[1]);
				push @{$stack}, vertex_destinations($g, $v);
				push @{$stack}, $b;

				$instruction = ">r 2 pick over " . $g->get_vertex_attribute($v, 'type') . " r>";
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_to_r_to_r_2_pick_op2_r_from_r_from_a      { # >r >r 2 pick op2 r> r>      ( x0? a   x1  b   c -- x0' a   y   b   c     )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (($g->in_degree($v) == 2) and (scalar (@{$stack}) > 4)) {
			my @E_TO = $g->edges_to($v);
			if (
				stack_match($E_TO[1]->[0], $stack->[-3]) and
				(scalar @{$stack->[-3]} == 2)             and
				stack_match($E_TO[0]->[0], $stack->[-5]) and
				(scalar @{$stack->[-5]} >  1)
			) {
				my $c = pop @{$stack};
				my $b = pop @{$stack};
				pop  @{$stack}; # x1
				$stack = stack_reduce ($stack, -2, $E_TO[0]->[1]);
				push @{$stack}, vertex_destinations($g, $v);
				push @{$stack}, $b;
				push @{$stack}, $c;

				$instruction = ">r >r 2 pick " . $g->get_vertex_attribute($v, 'type') . " r> r>";
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_to_r_to_r_2_pick_op2_r_from_r_from_b      { # >r >r 2 pick op2 r> r>      ( x1? a   x0  b   c -- x1' a   y   b   c     )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (($g->in_degree($v) == 2) and (scalar (@{$stack}) > 4)) {
			my @E_TO = $g->edges_to($v);
			if (
				stack_match($E_TO[0]->[0], $stack->[-3]) and
				(scalar @{$stack->[-3]} == 2)            and
				stack_match($E_TO[1]->[0], $stack->[-5]) and
				(scalar @{$stack->[-5]} >  1)
			) {
				my $c = pop @{$stack};
				my $b = pop @{$stack};
				pop  @{$stack}; # x0
				$stack = stack_reduce ($stack, -2, $E_TO[1]->[1]);
				push @{$stack}, vertex_destinations($g, $v);
				push @{$stack}, $b;
				push @{$stack}, $c;

				$instruction = ">r >r 2 pick " . $g->get_vertex_attribute($v, 'type') . " r> r>";
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_to_r_to_r_2_pick_over_op2_r_from_r_from_a { # >r >r 2 pick over op2 r> r> ( x0? a   x1' b   c -- x0' a   x1' y   b   c )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (($g->in_degree($v) == 2) and (scalar (@{$stack}) > 4)) {
			my @E_TO = $g->edges_to($v);
			if (
				stack_match($E_TO[1]->[0], $stack->[-3]) and
				(scalar @{$stack->[-3]} >  2)            and
				stack_match($E_TO[0]->[0], $stack->[-5]) and
				(scalar @{$stack->[-5]} >  1)
			) {
				my $c = pop @{$stack};
				my $b = pop @{$stack};
				$stack = stack_reduce ($stack, -1, $E_TO[1]->[1]);
				$stack = stack_reduce ($stack, -3, $E_TO[0]->[1]);
				push @{$stack}, vertex_destinations($g, $v);
				push @{$stack}, $b;
				push @{$stack}, $c;

				$instruction = ">r >r 2 pick over " . $g->get_vertex_attribute($v, 'type') . " r> r>";
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_to_r_to_r_2_pick_over_op2_r_from_r_from_b { # >r >r 2 pick over op2 r> r> ( x1? a   x0' b   c -- x1' a   x0' y   b   c )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";
	for my $v (@{$candidates}) {
		if (($g->in_degree($v) == 2) and (scalar (@{$stack}) > 4)) {
			my @E_TO = $g->edges_to($v);
			if (
				stack_match($E_TO[0]->[0], $stack->[-3]) and
				(scalar @{$stack->[-3]} >  2)            and
				stack_match($E_TO[1]->[0], $stack->[-5]) and
				(scalar @{$stack->[-5]} >  1)
			) {
				my $c = pop @{$stack};
				my $b = pop @{$stack};
				$stack = stack_reduce ($stack, -1, $E_TO[0]->[1]);
				$stack = stack_reduce ($stack, -3, $E_TO[1]->[1]);
				push @{$stack}, vertex_destinations($g, $v);
				push @{$stack}, $b;
				push @{$stack}, $c;

				$instruction = ">r >r 2 pick over " . $g->get_vertex_attribute($v, 'type') . " r> r>";
				$seen->{$v} += 1;
				return (1, $stack, $seen, $instruction);
			}
		}
	}
	return (0, $stack, $seen, $instruction);
}

sub e_inport_fetch_0                            { # inport@                     (                   -- e0                    )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";  # error instruction
	if (scalar @{$candidates} > 0) {
		my $v = $candidates->[0]; # first in list
		L2: for my $e ($g->edges_to($v)) { # all data it requires
			my $efrom = $e->[0];
			for my $se (@{$stack}) {
				next L2 if ($$se[0] eq $efrom);
			}
			$instruction = "${efrom}@";
			push (@{$stack}, vertex_destinations($g, $efrom));
			return (1, $stack, $seen, $instruction);
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_inport_fetch_1                            { # inport@                     (                   -- e0                    )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";  # error instruction
	if (scalar @{$candidates} > 1) {
		my $v = $candidates->[1]; # first in list
		L2: for my $e ($g->edges_to($v)) { # all data it requires
			my $efrom = $e->[0];
			for my $se (@{$stack}) {
				next L2 if ($$se[0] eq $efrom);
			}
			$instruction = "${efrom}@";
			push (@{$stack}, vertex_destinations($g, $efrom));
			return (1, $stack, $seen, $instruction);
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_inport_fetch_2                            { # inport@                     (                   -- e0                    )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";  # error instruction
	if (scalar @{$candidates} > 2) {
		my $v = $candidates->[2]; # first in list
		L2: for my $e ($g->edges_to($v)) { # all data it requires
			my $efrom = $e->[0];
			for my $se (@{$stack}) {
				next L2 if ($$se[0] eq $efrom);
			}
			$instruction = "${efrom}@";
			push (@{$stack}, vertex_destinations($g, $efrom));
			return (1, $stack, $seen, $instruction);
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_inport_fetch_3                            { # inport@                     (                   -- e0                    )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";  # error instruction
	if (scalar @{$candidates} > 3) {
		my $v = $candidates->[3]; # first in list
		L2: for my $e ($g->edges_to($v)) { # all data it requires
			my $efrom = $e->[0];
			for my $se (@{$stack}) {
				next L2 if ($$se[0] eq $efrom);
			}
			$instruction = "${efrom}@";
			push (@{$stack}, vertex_destinations($g, $efrom));
			return (1, $stack, $seen, $instruction);
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_inport_fetch_4                            { # inport@                     (                   -- e0                    )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";  # error instruction
	if (scalar @{$candidates} > 4) {
		my $v = $candidates->[4]; # first in list
		L2: for my $e ($g->edges_to($v)) { # all data it requires
			my $efrom = $e->[0];
			for my $se (@{$stack}) {
				next L2 if ($$se[0] eq $efrom);
			}
			$instruction = "${efrom}@";
			push (@{$stack}, vertex_destinations($g, $efrom));
			return (1, $stack, $seen, $instruction);
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_inport_fetch_5                            { # inport@                     (                   -- e0                    )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";  # error instruction
	if (scalar @{$candidates} > 5) {
		my $v = $candidates->[5]; # first in list
		L2: for my $e ($g->edges_to($v)) { # all data it requires
			my $efrom = $e->[0];
			for my $se (@{$stack}) {
				next L2 if ($$se[0] eq $efrom);
			}
			$instruction = "${efrom}@";
			push (@{$stack}, vertex_destinations($g, $efrom));
			return (1, $stack, $seen, $instruction);
		}
	}
	return (0, $stack, $seen, $instruction);
}
sub e_inport_fetch_6                            { # inport@                     (                   -- e0                    )
	my ($g, $stack, $candidates, $seen) = @_;

	my $instruction = "???";  # error instruction
	if (scalar @{$candidates} > 6) {
		my $v = $candidates->[6]; # first in list
		L2: for my $e ($g->edges_to($v)) { # all data it requires
			my $efrom = $e->[0];
			for my $se (@{$stack}) {
				next L2 if ($$se[0] eq $efrom);
			}
			$instruction = "${efrom}@";
			push (@{$stack}, vertex_destinations($g, $efrom));
			return (1, $stack, $seen, $instruction);
		}
	}
	return (0, $stack, $seen, $instruction);
}

sub cfg_asap {
	my $g = shift;
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
			my $instruction = '';
			L1: for my $v (@OPS) {
				next if $seen->{$v};
				my $e;
				for $e ($g->edges_to($v)) {
					next L1 unless $seen->{$e->[0]};
				}
				push @PRE, $v;
			}

			for my $ref (
\&e_drop,
\&e_ouport_store,
\&e_nip,
\&e_dup_ouport_store,
\&e_swap_ouport_store,
\&e_over_ouport_store,
\&e_op1,
\&e_swap_op1,

\&e_op2_a,
\&e_op2_b,
\&e_to_r_op2_r_from_a,
\&e_to_r_op2_r_from_b,
\&e_swap_to_r_op2_r_from_a,
\&e_swap_to_r_op2_r_from_b,
\&e_to_r_to_r_op2_r_from_r_from_a,
\&e_to_r_to_r_op2_r_from_r_from_b,
\&e_to_r_swap_to_r_op2_r_from_r_from_a,
\&e_to_r_swap_to_r_op2_r_from_r_from_b,
\&e_swap_to_r_swap_to_r_op2_r_from_r_from_a,
\&e_swap_to_r_swap_to_r_op2_r_from_r_from_b,

\&e_over_op2_a,
\&e_over_op2_b,
\&e_swap_over_op2_a,
\&e_swap_over_op2_b,
\&e_to_r_over_op2_r_from_a,
\&e_to_r_over_op2_r_from_b,
\&e_to_r_swap_over_op2_r_from_a,
\&e_to_r_swap_over_op2_r_from_b,
#\&e_2_pick_op2_a,
#\&e_2_pick_op2_b,
#\&e_to_r_2_pick_op2_r_from_a,
#\&e_to_r_2_pick_op2_r_from_b,

\&e_dup_op1,
\&e_over_op1,
\&e_2dup_op2_a,
\&e_2dup_op2_b,
\&e_to_r_2dup_op2_r_from_a,
\&e_to_r_2dup_op2_r_from_b,
\&e_to_r_nip_r_from,
\&e_to_r_to_r_nip_r_from_r_from,

#\&e_2_pick_over_op2_a,
#\&e_2_pick_over_op2_b,
#\&e_to_r_2_pick_over_op2_r_from_a,
#\&e_to_r_2_pick_over_op2_r_from_b,
#\&e_to_r_to_r_2_pick_op2_r_from_r_from_a,
#\&e_to_r_to_r_2_pick_op2_r_from_r_from_b,
#\&e_to_r_to_r_2_pick_over_op2_r_from_r_from_a,
#\&e_to_r_to_r_2_pick_over_op2_r_from_r_from_b,

\&e_inport_fetch_0,
\&e_inport_fetch_1,
\&e_inport_fetch_2,
\&e_inport_fetch_3,
\&e_inport_fetch_4,
\&e_inport_fetch_5,
\&e_inport_fetch_6
) {
				($flag, $stack, $seen, $instruction) = &$ref ($g, $stack, \@PRE, $seen);
				if ($flag) {
					print sprintf ("%30s" , $instruction) . dump_stack($stack) . "\n";
					$iii++;
					next M;
				}
			}
			last;
#			fisher_yates_shuffle (\@OPS);
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
	my $tmax = cfg_asap($g0);
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
