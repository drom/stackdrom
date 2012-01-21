/* configuration file */
var my = {
"width":{
	"base"  : 16, // [bit] 2^n
	"fetch" : 32, // [bit] 2^n
	"ir"    : 8   // [fetch words] 2^n
},
"isa":{ // instruction format tree
	"0": [
		"Postcard",
		{"1": [
			"Letter",
			{"2": [
				{"3": ["p12", "p16"]},
				{"3": [
					{"4": [
						{"5": ["Call", "Branch"]},
						{"5": ["?Branch", "Next"]}
					]},
					"Literal"
				]}
			]}
		]}
	]
},
"parcels":{ // all instuction formats
	"Postcard" : [4,  {"op" : [3,1]}, "Most common 0-operand words"],
	"Letter"   : [8,  {"op" : [7,2]}, "Bigger set of common words"],
	"p12"      : [12, {"op" : [6,4],  "literal" : [11,7]}, "common sequences with literal"],
	"p16"      : [16, {
		"rs&#xB1;"   : [15, 14, "0", "+1", "-2", "-1"],
		"ds&#xB1;"   : [13, 12, "0", "+1", "-2", "-1"],
		"alu"        : [11, 8, "t", "n", "t+n", "t&n", "t|n", "t^n", "~t", "n==t", "n<t", "n>>t", "t-1", "r", "[t]", "n<<t", "depth", "nu<t"],
		"pc\u2190r"  : 7,
		"n\u2190t"   : 6,
		"r\u2190t"   : 5,
		"[t]\u2190n" : 4
	}, "Novix-style instruction. (Fix me!)"],
	"Branch"  : [16, {"addr":[15,8], "pg":[7, 6, "same", "next", "0", "previous"]}, "Unconditional branch"],
	"?Branch" : [16, {"addr":[15,8], "pg":[7, 6, "same", "next", "0", "previous"]}, "Branch if (s0 == 0), drop ds"],
	"Next"    : [16, {"addr":[15,8], "pg":[7, 6, "same", "next", "0", "previous"]}, "Branch if r0 != 0"],
	"Call"    : [24, {"addr":[23,6]}, "Subroutine call"],
	"Literal" : [36, {"literal":[35,4]}, "Long literal"]
},
"liw":[
	{"a"    : [2, "ps0", "ps1", "ps2", "imm"]},
	{"b"    : [2, "ps0", "ps1", "ps2", "imm"]},
	{"(d)"  : [3, "a", "a&b", "a-b", "a|b", "a+b", "a^b", "b-a", "b"]},
	{"d"    : [2, "ps0", "ps1", "ps2", "imm"]},
	{"(c)"  : [3, "a", "a&b", "a-b", "a|b", "a+b", "a^b", "b-a", "b"]},
	{"c"    : [2, "ps0", "ps1", "ps2", "imm"]},
	{"ds"   : [2, "nop", "push", "pop", "pop-pop"]},
	{"rs"   : [2, "nop", "push", "pop", "pop-pop"]},
	{"lit"  : 32},
	{"goto" : [2, "pc++", "rs0", "imm"]}
],
"Postcard":{
	"exit"      : [{"op":0 }, {         "rs":-1,                                                                "goto":"r0"}],
	"drop"      : [{"op":1 }, {"ds":-1 }],
	"+"         : [{"op":2 }, {"ds":-1, "a":"s1", "b":"s0",            "(d)":"a+b",           "d":"s0"}],
	"dup"       : [{"op":3 }, {"ds": 1,           "b":"s0",            "(d)":"b",             "d":"s0"}],
	"over"      : [{"op":4 }, {"ds": 1, "a":"s1",                      "(d)":"a",             "d":"s0"}],
	"swap"      : [{"op":5 }, {         "a":"s1", "b":"s0", "(c)":"b", "(d)":"a",   "c":"s1", "d":"s0"}],
	"i32@"      : [{"op":6 }, {         "a":"s0",                      "(d)":"i32[a]",        "d":"s0"}],
	"i32!"      : [{"op":7 }, {"ds":-2, "a":"s1", "b":"s0",            "(d)":"i32[a]=b",      "d":"s0"}]
},
"Letter":{
	"r@"        : [{"op":0 }, {"ds": 1, "a":"r0",                      "(d)":"a",             "d":"s0"}],
	"r1@"       : [{"op":1 }, {"ds": 1, "a":"r1",                      "(d)":"a",             "d":"s0"}],
	"r2@"       : [{"op":2 }, {"ds": 1, "a":"r2",                      "(d)":"a",             "d":"s0"}],
	"r3@"       : [{"op":3 }, {"ds": 1, "a":"r3",                      "(d)":"a",             "d":"s0"}],
	"r4@"       : [{"op":4 }, {"ds": 1, "a":"r4",                      "(d)":"a",             "d":"s0"}],
	"r5@"       : [{"op":5 }, {"ds": 1, "a":"r5",                      "(d)":"a",             "d":"s0"}],
	"r6@"       : [{"op":6 }, {"ds": 1, "a":"r6",                      "(d)":"a",             "d":"s0"}],
	"r7@"       : [{"op":7 }, {"ds": 1, "a":"r7",                      "(d)":"a",             "d":"s0"}],

	"r>"        : [{"op":8 }, {"ds": 1, "a":"r0",                      "(d)":"a",             "d":"s0", "rs":-1}],
	">r"        : [{"op":9 }, {"ds":-1, "a":"s0",                      "(d)":"a",             "d":"r0", "rs": 1}],
	"2 pick"    : [{"op":10}, {"ds": 1, "a":"s2",                      "(d)":"a",             "d":"s0"}],
	"3 pick"    : [{"op":11}, {"ds": 1, "a":"s3",                      "(d)":"a",             "d":"s0"}],
	"4 pick"    : [{"op":12}, {"ds": 1, "a":"s4",                      "(d)":"a",             "d":"s0"}],
	"5 pick"    : [{"op":13}, {"ds": 1, "a":"s5",                      "(d)":"a",             "d":"s0"}],
	"6 pick"    : [{"op":14}, {"ds": 1, "a":"s6",                      "(d)":"a",             "d":"s0"}],
	"7 pick"    : [{"op":15}, {"ds": 1, "a":"s7",                      "(d)":"a",             "d":"s0"}],


	"i8@"       : [{"op":18}, {         "a":"s0",                      "(d)":"i8[a]",         "d":"s0"}],
	"i16@"      : [{"op":18}, {         "a":"s0",                      "(d)":"i16[a]",        "d":"s0"}],
	"1 +"       : [{"op":20}, {         "a":"lit","b":"s0", "d":"s0",  "(d)":"a+b", "lit" : 1}],
	"4 +"       : [{"op":32}, {         "a":"lit","b":"s0", "d":"s0",  "(d)":"a+b", "lit" : 1}],
	"1 -"       : [{"op":21}, {         "a":"lit","b":"s0", "d":"s0",  "(d)":"a+b", "lit" : -1}],

	"negate"    : [{"op":25}, {"b":"s0", "(d)":"-b",    "d":"s0"}],
	"invert"    : [{"op":26}, {"b":"s0", "(d)":"~b",    "d":"s0"}],
	"2 *"       : [{"op":33}, {"b":"s0", "(d)":"b<<1",  "d":"s0"}],
	"2 /"       : [{"op":34}, {"b":"s0", "(d)":"b>>1",  "d":"s0"}],
	"0 ="       : [{"op":35}, {"b":"s0", "(d)":"b=0",   "d":"s0"}],
	"0 <"       : [{"op":36}, {"b":"s0", "(d)":"b>>32", "d":"s0"}],
	"abs"       : [{"op":37}, {"b":"s0", "(d)":"|b|",   "d":"s0"}],

	"swap drop" : [{"op":0 }, {"ds":-1,          "b":"s0",             "(d)":"b",             "d":"s0"}], // nip

	"i8!"       : [{"op":19}, {"ds":-2, "a":"s1", "b":"s0",            "(d)":"i8[a]=b",       "d":"s0"}],
	"i16!"      : [{"op":19}, {"ds":-2, "a":"s1", "b":"s0",            "(d)":"i16[a]=b",      "d":"s0"}],

	"or"        : [{"op":22}, {"ds":-1, "a":"s1", "b":"s0", "d":"s0",  "(d)":"a|b"}],
	"xor"       : [{"op":23}, {"ds":-1, "a":"s1", "b":"s0", "d":"s0",  "(d)":"a^b"}],
	"and"       : [{"op":24}, {"ds":-1, "a":"s1", "b":"s0", "d":"s0",  "(d)":"a&b"}],
	"*"         : [{"op":27}, {"ds":-1, "a":"s1", "b":"s0", "d":"s0",  "(d)":"a*b"}],
	"-"         : [{"op":31}, {"ds":-1, "a":"s1", "b":"s0", "d":"s0",  "(d)":"a-b"}],
	"m*"        : [{"op":28}, {"ds":-1, "a":"s1", "b":"s0", "d":"s0",  "(d)":"a*b"}],
	"um*"       : [{"op":29}, {"ds":-1, "a":"s1", "b":"s0", "d":"s0",  "(d)":"a*b"}],
	"/"         : [{"op":30}, {"ds":-1, "a":"s1", "b":"s0", "d":"s0",  "(d)":"a/b"}],
},
"p12":{
	"[0:1:31> + i32@" : [{"op" : 0, "literal" : "$1"}, {"lit" : "literal", "ds": 1}],
	"[0:1:31] + i32!" : [{"op" : 1, "literal" : "$1"}, {"lit" : "literal", "ds":-1}],
	"[0:1:31] + i16@" : [{"op" : 2, "literal" : "$1"}, {"lit" : "literal", "ds": 1}],
	"[0:1:31] + i16!" : [{"op" : 3, "literal" : "$1"}, {"lit" : "literal", "ds":-1}],
	"[0:1:31] +  i8@" : [{"op" : 4, "literal" : "$1"}, {"lit" : "literal", "ds": 1}],
	"[0:1:31] +  i8!" : [{"op" : 5, "literal" : "$1"}, {"lit" : "literal", "ds":-1}],
	"[-16:1:15]    +" : [{"op" : 6, "literal" : "$1"}, {"lit" : "literal"}],
	"[-16:1:15]     " : [{"op" : 7, "literal" : "$1"}, {"lit" : "literal"}]
},
"Branch":{
	"[0:1:255]         branch" : [{"addr":"$1", "pg":0}, {"goto":"addr"}],
	"[0:1:255]+pg_cur  branch" : [{"addr":"$1", "pg":1}, {"goto":"{pg_cur,addr}"}],
	"[0:1:255]+pg_nxt  branch" : [{"addr":"$1", "pg":2}, {"goto":"{pg_nxt,addr}"}],
	"[0:1:255]+pg_pre  branch" : [{"addr":"$1", "pg":3}, {"goto":"{pg_prv,addr}"}]
},
"?Branch":{
	"[0:1:255]        ?branch" : [{"addr":"$1", "pg":0}, {"ds":-1, "goto":"s0 ? pc_nxt : addr"}],
	"[0:1:255]+pg_cur ?branch" : [{"addr":"$1", "pg":1}, {"ds":-1, "goto":"s0 ? pc_nxt : {pg_cur,addr}"}],
	"[0:1:255]+pg_nxt ?branch" : [{"addr":"$1", "pg":2}, {"ds":-1, "goto":"s0 ? pc_nxt : {pg_nxt,addr}"}],
	"[0:1:255]+pg_pre ?branch" : [{"addr":"$1", "pg":3}, {"ds":-1, "goto":"s0 ? pc_nxt : {pg_prv,addr}"}]
},
"Next":{
	"[0:1:255]        Next" : [{"addr":"$1", "pg":0}, {"a":"r0", "(d)":"a-1", "d":"r0", "goto":"r0 ? addr : pc_nxt"}],
	"[0:1:255]+pg_cur Next" : [{"addr":"$1", "pg":1}, {"a":"r0", "(d)":"a-1", "d":"r0", "goto":"r0 ? {pg_cur,addr} : pc_nxt"}],
	"[0:1:255]+pg_nxt Next" : [{"addr":"$1", "pg":2}, {"a":"r0", "(d)":"a-1", "d":"r0", "goto":"r0 ? {pg_nxt,addr} : pc_nxt"}],
	"[0:1:255]+pg_pre Next" : [{"addr":"$1", "pg":3}, {"a":"r0", "(d)":"a-1", "d":"r0", "goto":"r0 ? {pg_prv,addr} : pc_nxt"}]
},
"Call":{
	"[0:1:262143] call" : [{"addr" : "$1"}, {"goto":"addr", "a":"pc_nxt", "(d)":"a", "d":"r0", "rs":1}]
},
"Literal":{
	"[-2147483648:1:2147483647]" : [{"literal" : "$1"}, {"ds":1, "a":"literal", "(d)":"a", "d":"s0"}]
}
}