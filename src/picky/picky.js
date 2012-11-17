/* configuration file */
var my = {
width : {
	base  : 32, // [bit] 2^n
	fetch : 32, // [bit] 2^n
	ir    : 8   // [fetch words] 2^n
},
isa : { // instruction format tree
	0 : [
		'card',
		{1 : ['pick', 'lttr']}
	]
},
parcels : { // all instuction formats
	card : [ 4, {                         op : [3,1]}, 'Collection of the most common words.'],
	pick : [12, {pk : [11,8], op : [7,4], ds : [3,2]}, '[pick] PICK [op].'],
	lttr : [16, {imm : [15,5],            op : [4,2]}, "Operations with literal."],
},
liw : [
	{a    : 8},
	{b    : 8},
	{d    : 8},
	{"(d)": 8},
	{c    : 8},
	{"(c)": 8},
	{ls   : 8},
	{ds   : 2},
	{rs   : 2},
	{lit  : 32},
	{goto : 32}
],
card: {
	exit  : [{op:0}, {       rs:-1, goto:'r0'}],
	drop  : [{op:1}, {ds:-1       }],
	'>r'  : [{op:2}, {ds:-1, rs: 1}],
	'r>'  : [{op:3}, {ds: 1, rs:-1}],
	'+'   : [{op:4}, {ds:-1, a:"s1", b:"s0",            "(d)":"a+b",                       d:"s0"}],
	'pick': [{op:5}, {ds: 1, rs:-1}],
//	swap  : [{op:3}, {       a:"s1", b:"s0", "(c)":"b", "(d)":"a",  c:"s1",                d:"s0"}],
//	'i16@': [{op:4}, {       a:"s0",                    "(d)":"ls",         ls:"i16[a]",   d:"s0"}],
},
pick: {
	'dup $ $'    : [{pk: 0}, {ds: 1, a:'s0'}],
	'over $ $'   : [{pk: 1}, {ds: 1, a:'s1'}],
	'2 pick $ $' : [{pk: 2}, {ds: 1, a:'s2'}],
	'3 pick $ $' : [{pk: 3}, {ds: 1, a:'s3'}],
	'4 pick $ $' : [{pk: 4}, {ds: 1, a:'s4'}],
	'5 pick $ $' : [{pk: 5}, {ds: 1, a:'s5'}],
	'6 pick $ $' : [{pk: 6}, {ds: 1, a:'s6'}],
	'7 pick $ $' : [{pk: 7}, {ds: 1, a:'s7'}],

	'$ nop $'         : [{op:  0}, {               "(d)":'a'   }],
	'$ over + $'      : [{op:  1}, {       b:'s0', "(d)":'a+b' }],
	'$ over - $'      : [{op:  2}, {       b:'s0', "(d)":'a-b' }],
	'$ over swap - $' : [{op:  3}, {       b:'s0', "(d)":'b-a' }],
	'$ over and $'    : [{op:  4}, {       b:'s0', "(d)":'a&a' }],
	'$ over or $'     : [{op:  5}, {       b:'s0', "(d)":'a|b' }],
	'$ over xor $'    : [{op:  6}, {       b:'s0', "(d)":'a^b' }],
	'$ invert $'      : [{op:  7}, {               "(d)":'~a'  }],
	'$ 2/ $'          : [{op:  8}, {               "(d)":'a>>1'}],
	'$ 2* $'          : [{op:  9}, {               "(d)":'a<<1'}],

	'$ i8@ $'         : [{op: 10}, {               "(d)":'ls', ls:"i8[a]"}],
	'$ 2dup i8! $'    : [{op: 11}, {       b:'s0',             ls:"i8[a]=b"}],

	'$ i16@ $'        : [{op: 12}, {               "(d)":'ls', ls:"i8[a]"}],
	'$ 2dup i16! $'   : [{op: 13}, {       b:'s0',             ls:"i8[a]=b"}],

	'$ i32@ $'        : [{op: 14}, {               "(d)":'ls', ls:"i16[a]"}],
	'$ 2dup i32! $'   : [{op: 15}, {       b:'s0',             ls:"i16[a]=b"}],

	'$ $ nop'         : [{ds:  0}, { d:'s0'}],
	'$ $ nip'         : [{ds:  1}, { d:'s0', ds:-1}],
	'$ $ nip nip'     : [{ds:  2}, { d:'s0', ds:-2}],
},
lttr : {
	"[2047:0]"         : [{imm: "$1", op: 0}, {ds:1, a:'lit', b:'s0',              d:'s0', lit:'imm'}],
	"[2047:0] +"       : [{imm: "$1", op: 1}, {ds:0, a:'lit', b:'s0', "(d)":'a+b', d:'s0', lit:'imm'}],
	"[2047:0] -"       : [{imm: "$1", op: 2}, {ds:0, a:'lit', b:'s0',              d:'s0', lit:'imm'}],
	"[2047:0] call"    : [{imm: "$1", op: 3}, {ds:0, a:'lit', b:'s0',              d:'s0', lit:'imm', goto:'lit'}],
	"[2047:0] branch"  : [{imm: "$1", op: 4}, {ds:0, a:'lit', b:'s0',              d:'s0', lit:'imm', goto:'lit'}],
	"[2047:0] ?branch" : [{imm: "$1", op: 5}, {ds:-1,a:'lit', b:'s0', "(d)":'a-b', d:'s0', lit:'imm', goto:'s0?lit:pnext'}],
}
}
