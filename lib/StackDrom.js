var StackDrom = {
	MaxLen : 0,
	EncodeISA : {},
	InitMaxLen : function () {
		var MaxLen = StackDrom.MaxLen;
		var NewLen;
		for (var name in my.parcels) {
			MaxLen = my.parcels[name][0];
			if (NewLen > MaxLen) {
				MaxLen = NewLen;
			}
		}
		StackDrom.MaxLen = MaxLen;
	},
	RecEncodeISA : function (root, tail) {
		if ("string" === typeof root || "number" === typeof root) {
			StackDrom.EncodeISA[root] = tail;
		} else {
			for (var name in root) {
				var tmp = {};
				tmp[name] = 0;
				tail.push (tmp);
				StackDrom.RecEncodeISA (root[name][0], tail.slice(0));
				tail.pop ();
				tmp = {};
				tmp[name] = 1;
				tail.push (tmp);
				StackDrom.RecEncodeISA (root[name][1], tail.slice(0));
				tail.pop ();
			}
		}
	},
	InitEncodeISA : function () {
		StackDrom.RecEncodeISA (my.isa, [0]);
	},
	PrintParsel : function (text) {
		var dom, x, len;
		len = my.parcels[text][0];

		dom = document.getElementById ('isa').insertRow(-1);
		x = dom.insertCell(0);
		x.innerHTML = text;
		x.setAttribute('class', 'name_f');
		x.colSpan = StackDrom.MaxLen;

		dom = document.getElementById ('isa').insertRow(-1);
		for (var i = 0; i < len; i++) {
			var y = dom.insertCell(0);
			y.innerHTML = i;
			y.setAttribute('class', 'bit_num_f');
		}
		for (var i = 0; i < (StackDrom.MaxLen - len); i++) {
			var y = dom.insertCell(0);
		}

		dom = document.getElementById ('isa').insertRow(-1);
		
		for (var i = (len - 1); i >= 0; i--) {
			var y = dom.insertCell(-1);
			var flds = my.parcels[text][1];
			y.setAttribute('class', 'empty_f');
			for (var name in flds) {
				if ("number" === typeof flds[name]) {
					if (flds[name] === i) {
//						var z = document.createElement("div");
//						y.appendChild(z);
//						z.innerHTML = name;
						y.innerHTML = name;
						y.setAttribute('class', 'valid_f');
						break;
					}
				} else {
					if (flds[name][0] === i) {
						y.innerHTML = name;
						y.setAttribute('class', 'valid_f');
						y.colSpan = flds[name][0] - flds[name][1] + 1;
						i = i - (flds[name][0] - flds[name][1]);
						break;
					}
				}
			}
			var lena = StackDrom.EncodeISA[text].length;
			for (var j = 0; j < lena; j++) {
				for (var k in StackDrom.EncodeISA[text][j]) {
					if (i == k) {
						y.innerHTML = StackDrom.EncodeISA[text][j][k];
						y.setAttribute('class', 'const_f');
					}
				}
			}
		}

		for (var i = 0; i < (StackDrom.MaxLen - len); i++) {
			var y = dom.insertCell(0);
		}
	},
	RecISA : function (root) {
		for (var name in root) {
			var i0 = root[name][0];
			var i1 = root[name][1];
			if ("string" === typeof i0) { StackDrom.PrintParsel (i0); } else { StackDrom.RecISA (i0); }
			if ("string" === typeof i1) { StackDrom.PrintParsel (i1); } else { StackDrom.RecISA (i1); }
		}
	},
	AddISA : function () {
		StackDrom.RecISA (my.isa);
	},
	doAll : function () {
		StackDrom.InitEncodeISA ();
		StackDrom.InitMaxLen ();
		StackDrom.AddISA ();
	}
};

window.onload = StackDrom.doAll;
