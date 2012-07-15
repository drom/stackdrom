#!/usr/bin/perl -w

use strict;
use Graph;
use Graph::Writer::Dot;

sub layers {
	my $g0     = shift;
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
					$g0->add_edge("re-$from", "im-$to");
					$g0->set_edge_attribute("im-$from", "re-$to", 'headlabel', -1);
				} elsif ($e == 1) {
					$g0->add_edge("re-$from", "re-$to");
					$g0->add_edge("im-$from", "im-$to");
				} elsif ($e) {
					$g0->set_edge_attribute("re-$from", "re-$to", 'headlabel', $e);
					$g0->set_edge_attribute("im-$from", "im-$to", 'headlabel', $e);
				}
				$k++;
			}
			$j++;
		}
		$i++;
	}
}

sub operations {
	my $g0 = shift;

 	for my $v ($g0->vertices) {
		if ($g0->in_degree($v) == 2) {
#			$g0->set_vertex_attribute($v, 'label', '+');
			$g0->set_vertex_attribute($v, 'shape', 'oval');
		} elsif ($g0->in_degree($v) == 1) {
			my @EDGE = $g0->edges_to($v);
			my $label = $g0->get_edge_attribute(@{$EDGE[0]}, 'headlabel');
			if (defined $label) {
				if (($label == 1) or ($label == -1)) {
					$g0->set_vertex_attribute($v, 'shape', 'point');
				} else {
					$g0->set_vertex_attribute($v, 'shape', 'box');
					$g0->set_vertex_attribute($v, 'height', 3);
				}
			} else {
				$g0->set_vertex_attribute($v, 'shape', 'point');
			}
		} else {
			$g0->set_vertex_attribute($v, 'shape', 'point');
		}
	}
}

sub clean1 {
	my $g0 = shift;

	for my $v ($g0->vertices) {
		if (($g0->in_degree($v) == 1) and ($g0->out_degree($v) > 0)) {
			my @EDGES_TO = $g0->edges_to($v);
			my @EDGE_TO  = @{$EDGES_TO[0]};
			my $label = $g0->get_edge_attribute(@EDGE_TO, 'headlabel');
			if (!defined $label) {
				my @EDGES_FROM = $g0->edges_from($v);
				for my $e (@EDGES_FROM) {
					my @EDGE = @{$e};
					my $attr = $g0->get_edge_attributes(@{$e});
					$g0->set_edge_attributes($EDGE_TO[0], $EDGE[1], $attr);
				}
				$g0->delete_vertex($v);
			}			
		}
	}
}

sub clean2 {
	my $g0 = shift;

	for my $v ($g0->vertices) {
		if (($g0->in_degree($v) == 1) and ($g0->out_degree($v) > 0)) {
			my @EDGES_TO = $g0->edges_to($v);
			my @EDGE_TO  = @{$EDGES_TO[0]};
			my $label = $g0->get_edge_attribute(@EDGE_TO, 'headlabel');
			if ($label eq '-1') {
				my @EDGES_FROM = $g0->edges_from($v);
				for my $e (@EDGES_FROM) {
					my @EDGE = @{$e};
					my $attr = $g0->get_edge_attributes(@{$e});
					$g0->set_edge_attributes($EDGE_TO[0], $EDGE[1], $attr);

					my $l = $g0->get_edge_attribute(@{$e}, 'headlabel');
					if (defined $l) {
						if ($l eq '-1') {
							$g0->delete_edge_attribute($EDGE_TO[0], $EDGE[1], 'headlabel');
						} else {
							$g0->set_edge_attribute($EDGE_TO[0], $EDGE[1], 'headlabel', "-$l");
						}
					} else {
						$g0->set_edge_attribute($EDGE_TO[0], $EDGE[1], 'headlabel', '-1');
					}
				}
				$g0->delete_vertex($v);
			}			
		}
	}
}

sub colorize {
	my ($g0, $code, $colors) = @_;
	
	my $i = 0;
	for my $thread (@{$code}) {
		my $j = 0;
		for my $v (@{$thread}) {
			$g0->set_vertex_attribute($v, 'color', $colors->[$i]);
			$g0->set_vertex_attribute($v, 'style', 'filled');
			$j++;
		}
		$i++;
	}
}

sub straighten {
	my ($g0, $code, $colors) = @_;
	
	my $i = 0;
	for my $thread (@{$code}) {
		my $j = 0;
		for my $v (@{$thread}) {
			if ($j) {
				if (!($g0->has_edge($thread->[$j-1], $thread->[$j]))) {
					$g0->set_edge_attribute($thread->[$j-1], $thread->[$j], 'style', 'invis');
				}
				$g0->set_edge_attribute($thread->[$j-1], $thread->[$j], 'group', $i);
				$g0->set_edge_attribute($thread->[$j-1], $thread->[$j], 'weight', 100);
				$g0->set_edge_attribute($thread->[$j-1], $thread->[$j], 'type', 'cfg');
			}
			$j++;
		}
		$i++;
	}
}

sub index_ports {
	my $g0 = shift;
	for my $v ($g0->vertices) {
		if ($g0->in_degree($v) == 0) {
			$g0->set_vertex_attribute($v, 'shape', 'invhouse');
			$g0->set_vertex_attribute($v, 'type',  'inport');
		} elsif ($g0->out_degree($v) == 0) {
			$g0->set_vertex_attribute($v, 'shape', 'invhouse');
			$g0->set_vertex_attribute($v, 'type',  'ouport');
		}
	}
}

sub decouple {
	my $g0 = shift;

	for my $v ($g0->vertices) {
		my $color = $g0->get_vertex_attribute($v, 'color');
		if (defined $color) {
			for my $e ($g0->edges_from($v)) {
				my $c2 = $g0->get_vertex_attribute($e->[1], 'color');
				if (defined $c2 and ($c2 ne $color)) {
					my $label = $g0->get_edge_attribute(@{$e}, 'headlabel');

					$g0->add_edge($e->[0], "${v}_ou");
					$g0->set_vertex_attribute("${v}_ou", 'shape', 'invhouse');
					$g0->set_vertex_attribute("${v}_ou", 'type',  'ouport');

					$g0->set_edge_attribute("${v}_ou", "${v}_in", 'constraint', 'false');
					$g0->set_edge_attribute("${v}_ou", "${v}_in", 'style', 'dotted');

					$g0->set_edge_attribute("${v}_in", $e->[1], 'headlabel', $label);

					$g0->set_vertex_attribute("${v}_in", 'shape', 'invhouse');
					$g0->set_vertex_attribute("${v}_in", 'type',  'inport');

					$g0->delete_edge(@{$e});
				}
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
	my $g0 = shift;

	for my $v ($g0->vertices) {
		my $type = $g0->get_vertex_attribute($v, 'type');
		if (defined $type and $type eq 'ouport') {
			my @e = $g0->edges_to($v);
			my $v1 = $e[0]->[0];
			for my $e1 ($g0->edges_from($v1)) {
				my $e1type = $g0->get_edge_attribute(@{$e1}, 'type');
				if ((defined $e1type) and ($e1type eq 'cfg')) {
					my $e1style = $g0->get_edge_attribute(@{$e1}, 'style');
					if ((defined $e1style) and ($e1style eq 'invis')) {
						$g0->delete_edge(@{$e1});
						$g0->set_edge_attribute(@{$e[0]}, 'weight', 100);
						$g0->set_edge_attribute(@{$e[0]}, 'type', 'cfg');

						$g0->set_edge_attribute($e[0]->[1], $e1->[1], 'weight', 100);
						$g0->set_edge_attribute($e[0]->[1], $e1->[1], 'type',  'cfg');
						$g0->set_edge_attribute($e[0]->[1], $e1->[1], 'style', 'invis');
					}
				}
			}
		}
	}
}

sub get_cfg_root {
	my $g0 = shift;
	my $v  = shift;

	for my $e ($g0->edges_to($v)) {
		my @E = @{$e};
		my $etype = $g0->get_edge_attribute(@E, 'type');
		if ((defined $etype) and ($etype eq 'cfg')) {
			return get_cfg_root ($g0, $E[0]);
		}
	}
	return $v;
}

sub get_cfg_root_by_color {
	my ($g0, $color) = @_;

	for my $v0 ($g0->vertices) {
		my $v0color = $g0->get_vertex_attribute($v0, 'color');
		if ((defined $v0color) and ($v0color eq $color)) {
			return get_cfg_root($g0, $v0);
		}
	}
	
}

sub get_cfg_match {
	my ($g0, $v, $v0) = @_;

	if ($g0->has_edge($v0, $v)) {
		return $v;
	}
	for my $e ($g0->edges_from($v)) {
		my @E = @{$e};
		my $etype = $g0->get_edge_attribute(@E, 'type');
		if ((defined $etype) and ($etype eq 'cfg')) {
			return get_cfg_match ($g0, $E[1], $v0);
		}
	}
	return undef;
}

sub straighten_inports {
	my $g0 = shift;

	for my $v0 ($g0->vertices) {
		my $v0type = $g0->get_vertex_attribute($v0, 'type');
		if (defined $v0type and $v0type eq 'inport') {
			my @E = $g0->edges_from($v0);
			my $color = $g0->get_vertex_attribute($E[0]->[1], 'color');
			my $vroot = get_cfg_root_by_color($g0, $color);
			my $v1    = get_cfg_match($g0, $vroot, $v0);
			for my $e1 ($g0->edges_to($v1)) {
				my @E1 = @{$e1};
				my $v2 = $E1[0];
				my $e1type = $g0->get_edge_attribute($v2, $v1, 'type');
				if ((defined $e1type) and ($e1type eq 'cfg')) {
					my $e1style = $g0->get_edge_attribute($v2, $v1, 'style');
					if ((defined $e1style) and ($e1style eq 'invis')) {
						$g0->delete_edge($v2, $v1);
					} else {
						$g0->set_edge_attribute     ($v2, $v1, 'weight', 1);
						$g0->set_edge_attribute     ($v2, $v1, 'type', '');
#						$g0->delete_edge_attribute  ($v2, $v1, 'type');
					}
					$g0->set_edge_attribute($v0, $v1, 'weight', 100);
					$g0->set_edge_attribute($v0, $v1, 'type', 'cfg');

					$g0->set_edge_attribute($v2, $v0, 'weight', 100);
					$g0->set_edge_attribute($v2, $v0, 'type',  'cfg');
					$g0->set_edge_attribute($v2, $v0, 'style', 'invis');
					last;
				}
			}
		}
	}
}

{
my @COLORS = ("tomato", "yellow", "cyan", "violet", "orange", "greenyellow", "skyblue", "fuchsia");

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


my @CODE6 = (
['re-1,1', 're-1,3', 're-2,3', 're-2,1', 're-3,1', 're-5,1', 're-5,3', 're-6,1', 're-6,3'],
['re-1,7', 're-1,5', 're-2,5', 're-2,7', 're-3,7', 're-5,7', 're-5,5', 're-6,7', 're-6,5'],
['re-1,6', 're-1,2', 're-2,4', 're-2,0', 're-4,0', 're-4,2', 're-5,0', 're-5,4', 're-6,2', 're-6,6'],
['im-1,1', 'im-1,3', 'im-2,3', 'im-2,1', 'im-3,1', 'im-5,1', 'im-5,3', 'im-6,1', 'im-6,3'],
['im-1,7', 'im-1,5', 'im-2,5', 'im-2,7', 'im-3,7', 'im-5,7', 'im-5,5', 'im-6,7', 'im-6,5'],
['im-1,6', 'im-1,2', 'im-2,4', 'im-2,0', 'im-4,0', 'im-4,2', 'im-5,0', 'im-5,4', 'im-6,2', 'im-6,6'],
);

my @CODE2 = (
['re-1,1', 're-1,7', 're-1,3', 're-1,5', 're-2,5', 're-2,7', 're-2,1', 're-2,3',
 're-2,4', 're-2,0',
 're-1,2',
 're-4,0', 're-4,2', 're-5,0', 're-5,4', 're-6,2', 're-6,6',
 're-1,6', 're-3,1',
 're-5,1', 're-5,3', 're-3,7',
 're-5,5', 're-5,7', 
 're-6,3', 're-6,5', 're-6,1', 're-6,7',
],

['im-1,1', 'im-1,7', 'im-1,3', 'im-1,5', 'im-2,5', 'im-2,7', 'im-2,1', 'im-2,3',
 'im-2,4', 'im-2,0',
 'im-1,2',
 'im-4,0', 'im-4,2', 'im-5,0', 'im-5,4', 'im-6,2', 'im-6,6',
 'im-1,6', 'im-3,1',
 'im-5,1', 'im-5,3', 'im-3,7',
 'im-5,5', 'im-5,7',
 'im-6,3', 'im-6,5', 'im-6,1', 'im-6,7',
],
);

colorize($g0, \@CODE2, \@COLORS);
$w0->write_graph ($g0, 'dot\03.dot');

my $g1 = Graph->new;
node_map($g0, $g1);
my $w1 = Graph::Writer::Dot->new();
$w1->write_graph ($g1, 'dot\map.dot');

decouple($g0);
$w0->write_graph ($g0, 'dot\04.dot');

straighten($g0, \@CODE2, \@COLORS);
$w0->write_graph ($g0, 'dot\05.dot');

straighten_ouports($g0);
straighten_inports($g0);
$w0->write_graph ($g0, 'dot\06.dot');

}
