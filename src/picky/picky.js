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
	card : [ 4, {              op : [3,1]}, 'Collection of the most common words.'],
	pick : [ 8, {imm : [ 7,6], op : [5,2]}, '[pick] PICK [op].'],
	lttr : [16, {imm : [15,5], op : [4,2]}, "Operations with literal."],
},
liw : [
	{a    : 8},
	{b    : 8},
	{d    : 8},
	{"(d)"  : 8},
	{c    : 8},
	{"(c)"  : 8},
	{ls   : 8},
	{ds   : 2},
	{rs   : 2},
	{lit  : 32},
	{goto : 32}
],
card : {
	exit  : [{op:0}, {       rs:-1,                                                                goto:"r0"}],
	drop  : [{op:1}, {ds:-1 }],
	'>r'  : [{op:2}, {ds:-1, rs: 1}],
	'r>'  : [{op:3}, {ds: 1, rs:-1}],
//	'+'   : [{op:2}, {ds:-1, a:"s1", b:"s0",            "(d)":"a+b",                       d:"s0"}],
//	swap  : [{op:3}, {       a:"s1", b:"s0", "(c)":"b", "(d)":"a",  c:"s1",                d:"s0"}],
//	'i16@': [{op:4}, {       a:"s0",                    "(d)":"ls",         ls:"i16[a]",   d:"s0"}],
},
pick : {
	"dup"           : [{imm: 0, op: 0}, {ds:1,  a:'s0',         "(d)":'a',   d:'s0'}],
	"over"          : [{imm: 1, op: 0}, {ds:1,  a:'s1',         "(d)":'a',   d:'s0'}],
	"2 pick"        : [{imm: 2, op: 0}, {ds:1,  a:'s2',         "(d)":'a',   d:'s0'}],
	"3 pick"        : [{imm: 3, op: 0}, {ds:1,  a:'s3',         "(d)":'a',   d:'s0'}],

	"dup +"         : [{imm: 0, op: 1}, {       a:'s0', b:'s0', "(d)":'b+a', d:'s0'}],
	"over +"        : [{imm: 1, op: 1}, {       a:'s1', b:'s0', "(d)":'b+a', d:'s0'}],
	"2 pick +"      : [{imm: 2, op: 1}, {       a:'s2', b:'s0', "(d)":'b+a', d:'s0'}],
	"3 pick +"      : [{imm: 3, op: 1}, {       a:'s3', b:'s0', "(d)":'b+a', d:'s0'}],

	"dup -"         : [{imm: 0, op: 2}, {       a:'s0', b:'s0', "(d)":'b-a', d:'s0'}],
	"over -"        : [{imm: 1, op: 2}, {       a:'s1', b:'s0', "(d)":'b-a', d:'s0'}],
	"2 pick -"      : [{imm: 2, op: 2}, {       a:'s2', b:'s0', "(d)":'b-a', d:'s0'}],
	"3 pick -"      : [{imm: 3, op: 2}, {       a:'s3', b:'s0', "(d)":'b-a', d:'s0'}],

	"dup swap -"    : [{imm: 0, op: 3}, {       a:'s0', b:'s0', "(d)":'a-b', d:'s0'}],
	"over swap -"   : [{imm: 1, op: 3}, {       a:'s1', b:'s0', "(d)":'a-b', d:'s0'}],
	"2 pick swap -" : [{imm: 2, op: 3}, {       a:'s2', b:'s0', "(d)":'a-b', d:'s0'}],
	"3 pick swap -" : [{imm: 3, op: 3}, {       a:'s3', b:'s0', "(d)":'a-b', d:'s0'}],

	"dup @"         : [{imm: 0, op: 4}, {ds:1,  a:'s0',         "(d)":'ls', d:'s0', ls:"i16[a]"}],
	"over @"        : [{imm: 1, op: 4}, {ds:1,  a:'s1',         "(d)":'ls', d:'s0', ls:"i16[a]"}],
	"2 pick @"      : [{imm: 2, op: 4}, {ds:1,  a:'s2',         "(d)":'ls', d:'s0', ls:"i16[a]"}],
	"3 pick @"      : [{imm: 3, op: 4}, {ds:1,  a:'s3',         "(d)":'ls', d:'s0', ls:"i16[a]"}],

	"dup c@"        : [{imm: 0, op: 5}, {ds:1,  a:'s0',         "(d)":'ls', d:'s0', ls:"i8[a]"}],
	"over c@"       : [{imm: 1, op: 5}, {ds:1,  a:'s1',         "(d)":'ls', d:'s0', ls:"i8[a]"}],
	"2 pick c@"     : [{imm: 2, op: 5}, {ds:1,  a:'s2',         "(d)":'ls', d:'s0', ls:"i8[a]"}],
	"3 pick c@"     : [{imm: 3, op: 5}, {ds:1,  a:'s3',         "(d)":'ls', d:'s0', ls:"i8[a]"}],

	"dup !"         : [{imm: 0, op: 6}, {ds:-1, a:'s0', b:'s0',                     ls:"i16[a]=b"}],
	"over !"        : [{imm: 1, op: 6}, {ds:-1, a:'s1', b:'s0',                     ls:"i16[a]=b"}],
	"2 pick !"      : [{imm: 2, op: 6}, {ds:-1, a:'s2', b:'s0',                     ls:"i16[a]=b"}],
	"3 pick !"      : [{imm: 3, op: 6}, {ds:-1, a:'s3', b:'s0',                     ls:"i16[a]=b"}],

	"dup c!"        : [{imm: 0, op: 7}, {ds:-1, a:'s0', b:'s0',                     ls:"i8[a]=b"}],
	"over c!"       : [{imm: 1, op: 7}, {ds:-1, a:'s1', b:'s0',                     ls:"i8[a]=b"}],
	"2 pick c!"     : [{imm: 2, op: 7}, {ds:-1, a:'s2', b:'s0',                     ls:"i8[a]=b"}],
	"3 pick c!"     : [{imm: 3, op: 7}, {ds:-1, a:'s3', b:'s0',                     ls:"i8[a]=b"}],
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
