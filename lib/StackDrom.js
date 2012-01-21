var StackDrom = {
	MaxLen : 0,
	EncodeISA : {},
	InitMaxLen : function () {
		var MaxLen = StackDrom.MaxLen;
		var NewLen;
		for (var name in my.parcels) {
			NewLen = my.parcels[name][0];
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
	PrintParcel : function (text, pot) {
		var dom, x, len;
		len = my.parcels[text][0];

		dom = document.getElementById (pot).insertRow(-1);
		x = dom.insertCell(0);
		x.innerHTML = '<a href="#' + text + '">' + text + '</a>';
		x.setAttribute('class', 'name_f');
		x.colSpan = StackDrom.MaxLen;

		dom = document.getElementById (pot).insertRow(-1);
		for (var i = 0; i < len; i++) {
			var y = dom.insertCell(0);
			y.innerHTML = i;
			y.setAttribute('class', 'bit_num_f');
		}
		for (var i = 0; i < (StackDrom.MaxLen - len); i++) {
			var y = dom.insertCell(0);
		}

		dom = document.getElementById (pot).insertRow(-1);
		
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
		dom = document.getElementById (pot).insertRow(-1);
		var y = dom.insertCell(0);

	},
	RecISA : function (root) {
		for (var name in root) {
			var i0 = root[name][0];
			var i1 = root[name][1];
			if ("string" === typeof i0) { StackDrom.PrintParcel (i0, 'isa'); } else { StackDrom.RecISA (i0); }
			if ("string" === typeof i1) { StackDrom.PrintParcel (i1, 'isa'); } else { StackDrom.RecISA (i1); }
		}
	},
	AddISA : function () {
		StackDrom.RecISA (my.isa);
	},
	AddParcels : function () {
		var dom, mod, x;
		for (var name in my.parcels) {
			dom = document.getElementById ('parcels').innerHTML += '<h3><a name=' + name +'>' + name + '</h3>';
			dom = document.getElementById ('parcels').innerHTML += my.parcels[name][2];
			dom = document.getElementById ('parcels').innerHTML += '<table id=div\_' + name + '></table>';
			StackDrom.PrintParcel (name, ('div\_' + name));
			dom = document.getElementById ('parcels').innerHTML += '<table class="sortable" id=ops\_' + name + '></table>';

			mod = document.getElementById ('ops\_' + name).insertRow(-1);

			x = mod.insertCell(0);

			for (var i in my.parcels[name][1]) {
				x = mod.insertCell(-1);
				x.innerHTML = i;
				x.setAttribute('class', 'op_fld_f');
			}
			for (var i in my.liw) {
				for (var j in my.liw[i]) {
					x = mod.insertCell(-1);
					x.innerHTML = j;
					x.setAttribute('class', 'liw_fld_f');
				}
			}

			for (var op in my[name]) {

				mod = document.getElementById ('ops\_' + name).insertRow(-1);

				x = mod.insertCell(0);
				x.innerHTML = op;
				x.setAttribute('class', 'forth');

				var fld;
				for (var i in my.parcels[name][1]) {
					x = mod.insertCell(-1);
					x.innerHTML = my[name][op][0][i];
					x.setAttribute('class', 'valid_f');
				}
				for (var i in my.liw) {
					for (var j in my.liw[i]) {
						x = mod.insertCell(-1);
						fld = my[name][op][1][j];
						if (fld) { x.innerHTML = fld; }
						x.setAttribute('class', 'liw_f');
					}
				}
			}
		}
	},
	doAll : function () {
		StackDrom.InitEncodeISA ();
		StackDrom.InitMaxLen ();
		StackDrom.AddISA ();
		StackDrom.AddParcels ();
	}
};

window.onload = StackDrom.doAll;
