/* configuration file */
var my = {
"width":{
	"base"  : 32, // [bit] 2^n
	"fetch" : 64, // [bit] 2^n
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
	}, "Novix-style instruction"],
	"Branch"  : [16, {"addr":[15,8], "pg":[7, 6, "same", "next", "0", "previous"]}, "Unconditional branch"],
	"?Branch" : [16, {"addr":[15,8], "pg":[7, 6, "same", "next", "0", "previous"]}, "(branch & drop) if t == 0"],
	"Next"    : [16, {"addr":[15,8], "pg":[7, 6, "same", "next", "0", "previous"]}, "(branch & decrement i) if i != 0"],
	"Call"    : [24, {"addr":[23,6]}, "Subroutine call"],
	"Literal" : [20, {"literal":[19,4]}, "Long literal"]
},
"liw":[
	{"imm"  : 32},
	{"ds"   : [2, "nop", "push", "pop", "pop-pop"]},
	{"rs"   : [2, "nop", "push", "pop", "pop-pop"]},
	{"a"    : [2, "ps0", "ps1", "ps2", "imm"]},
	{"b"    : [2, "ps0", "ps1", "ps2", "imm"]},
	{"alu"  : [3, "a", "a&b", "a-b", "a|b", "a+b", "a^b", "b-a", "b"]},
	{"goto" : [2, "pc++", "rs0", "imm"]}
],
"Postcard":{
	"exit" : [{"op":0}, {"rs":"pop", "goto":"rs0"}],
	"@"    : [{"op":1}, {}],
	"dup"  : [{"op":2}, {"ps":"push"                    }],
	"+"    : [{"op":3}, {"ps":"pop",  "a":"ps1", "alu":"a+b"}],
	"over" : [{"op":4}, {"ps":"push", "a":"ps1", "alu":"a"  }],
	"swap" : [{"op":5}, {"ps":"push", "a":"imm", "imm":0}],
	"drop" : [{"op":6}, {"ps":"pop"                     }],
	"!"    : [{"op":7}, {"ps":"push", "a":"imm", "imm":1}]
},
"Letter":{
	"swap drop" : [{"op":0 }, {}], // nip
	"swap over" : [{"op":1 }, {}], // tuck
	"2 pick"    : [{"op":2 }, {}],
	"3 pick"    : [{"op":3 }, {}],
	"4 pick"    : [{"op":4 }, {}],
	"5 pick"    : [{"op":5 }, {}],
	"6 pick"    : [{"op":6 }, {}],
	"7 pick"    : [{"op":7 }, {}],

	"r@"        : [{"op":8 }, {}],
	"r1@"       : [{"op":9 }, {}],
	"r2@"       : [{"op":10}, {}],
	"r3@"       : [{"op":11}, {}],
	"r4@"       : [{"op":12}, {}],
	"r5@"       : [{"op":13}, {}],
	"r6@"       : [{"op":14}, {}],
	"r7@"       : [{"op":15}, {}],

	">r"        : [{"op":16}, {}],
	"r>"        : [{"op":17}, {}],
	"c@"        : [{"op":18}, {}],
	"c!"        : [{"op":19}, {}],
	"1 +"       : [{"op":20}, {}],
	"1 -"       : [{"op":21}, {}],
	"or"        : [{"op":22}, {}],
	"xor"       : [{"op":23}, {}],

	"and"       : [{"op":24}, {}],
	"negate"    : [{"op":25}, {}],
	"invert"    : [{"op":26}, {}],
	"*"         : [{"op":27}, {}],
	"m*"        : [{"op":28}, {}],
	"um*"       : [{"op":29}, {}],
	"/"         : [{"op":30}, {}],
	"-"         : [{"op":31}, {}],

	"4 +"       : [{"op":32}, {}],
	"2 *"       : [{"op":33}, {}],
	"2 /"       : [{"op":34}, {}],
	"0 ="       : [{"op":35}, {}],
	"0 <"       : [{"op":36}, {}],
	"abs"       : [{"op":37}, {}]
},
"p12":{
	"[-16:1:15]    @" : [{"op" : 0, "literal" : "$1"}, {}],
	"[-16:1:15]    !" : [{"op" : 1, "literal" : "$1"}, {}],
	"[-16:1:15]   c@" : [{"op" : 2, "literal" : "$1"}, {}],
	"[-16:1:15]   c!" : [{"op" : 3, "literal" : "$1"}, {}],
	"[0:1:31]      +" : [{"op" : 4, "literal" : "$1"}, {}],
	"[0:1:31]      -" : [{"op" : 5, "literal" : "$1"}, {}],
	"[0:1:31] swap -" : [{"op" : 6, "literal" : "$1"}, {}]
}
}
