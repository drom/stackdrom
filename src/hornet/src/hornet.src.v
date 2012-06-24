//; use strict;
//; use Hornet;
module hornet (
	input  clk, reset_n,
	
	output logic [17:0] s, r, t,
	input  logic [17:0] rsq, dsq
/*
	output logic [17:0] i_com_n_dat, i_com_s_dat, i_com_w_dat, i_com_e_dat,
	output logic        i_com_n_req, i_com_s_req, i_com_w_req, i_com_e_req,
	input  logic        i_com_n_ack, i_com_s_ack, i_com_w_ack, i_com_e_ack,

	input  logic [17:0] t_com_n_dat, t_com_s_dat, t_com_w_dat, t_com_e_dat,
	input  logic        t_com_n_req, t_com_s_req, t_com_w_req, t_com_e_req,
	output logic        t_com_n_ack, t_com_s_ack, t_com_w_ack, t_com_e_ack
*/
);

logic [8:0] mem_adr;
logic       mem_req, mem_ack;

always_ff @ (posedge clk or negedge reset_n) if (~reset_n) mem_req <= 0; else mem_req <= 1;
always_ff @ (posedge clk or negedge reset_n) if (~reset_n) mem_ack <= 0; else mem_ack <= mem_req;

logic [17:0] t_nxt, s_nxt, r_nxt, r_dec, a, a_nxt, i, i_nxt, mem_sda;
logic [18:0] ts, tsa;
logic  [9:0] p, p_nxt, p_inca;
logic  [8:0] b, b_nxt;
logic  [1:0] slot, slot_nxt;
logic  [6:0] p_inc;
logic cf;



logic  [4:0] slot0, slot1, slot2, slot3, instr;

assign slot0 =   i [17:13] ^ 5'b01010;
assign slot1 =   i [12: 8] ^ 5'b10101;
assign slot2 =   i [ 7: 3] ^ 5'b01010;
assign slot3 = {(i [ 2: 0] ^   3'b101), 2'b00};

always_comb
	case (slot)
		    0 : instr = slot0;
		    1 : instr = slot1;
		    2 : instr = slot2;
		default instr = slot3;
	endcase

logic [7:0] jumpa;

always_comb
	case (slot)
		    0 : jumpa = {           i [ 9: 0]};
		    1 : jumpa = {p [ 9: 8], i [ 7: 0]};
		    2 : jumpa = {p [ 9: 3], i [ 2: 0]};
		default jumpa = {           i [ 9: 0]}; // as slot 0
	endcase

assign p_inc = p[6:0] + 6'b000001;
assign r_dec = r - 1;

assign p_inca = {p [9:7], p_inc};

assign ts  = {t[17], t} + {s[17], s};
assign tsa = a[0] ? ts : {t[17], t};


always_comb
	case (instr) // r_nxt
		/* ;     */  0 : r_nxt = rsq;
		/* ex    */  1 : r_nxt = {7'b0000000, p};
//		/* jump  */  2 : r_nxt =
		/* call  */  3 : r_nxt = {7'b0000000, p};
		/* unext */  4 : r_nxt = |r ? r_dec : rsq;
		/* next  */  5 : r_nxt = |r ? r_dec : rsq;
//		/* if    */  6 : r_nxt =
//		/* -if   */  7 : r_nxt =
//		/* @ p   */  8 : r_nxt =
//		/* @ +   */  9 : r_nxt =
//		/* @ b   */ 10 : r_nxt =
//		/* @     */ 11 : r_nxt =
//		/* !p    */ 12 : r_nxt =
//		/* !+    */ 13 : r_nxt =
//		/* !b    */ 14 : r_nxt =
//		/* !     */ 15 : r_nxt =
//		/* +*    */ 16 : r_nxt =
//		/* 2*    */ 17 : r_nxt =
//		/* 2/    */ 18 : r_nxt =
//		/* -     */ 19 : r_nxt =
//		/* +     */ 20 : r_nxt =
//		/* and   */ 21 : r_nxt =
//		/* or    */ 22 : r_nxt =
//		/* drop  */ 23 : r_nxt =
//		/* dup   */ 24 : r_nxt =
		/* pop   */ 25 : r_nxt = rsq;
//		/* over  */ 26 : r_nxt =
//		/* a     */ 27 : r_nxt =
//		/* .     */ 28 : r_nxt =
		/* push  */ 29 : r_nxt = t;
//		/* b!    */ 30 : r_nxt =
//		/* a!    */ 31 : r_nxt =
		default          r_nxt = r;
	endcase

always_comb
	case (instr) // p_nxt
		/* ;     */  0 : p_nxt = r [9:0];
		/* ex    */  1 : p_nxt = r [9:0];
		/* jump  */  2 : p_nxt = jumpa;
		/* call  */  3 : p_nxt = jumpa;
//		/* unext */  4 : p_nxt =
		/* next  */  5 : p_nxt = |r           ? jumpa : p;
		/* if    */  6 : p_nxt = (t     == 0) ? jumpa : p_inca;
		/* -if   */  7 : p_nxt = (t[17] == 0) ? jumpa : p_inca;
		/* @ p   */  8 : p_nxt = p_inca;
//		/* @ +   */  9 : p_nxt =
//		/* @ b   */ 10 : p_nxt =
//		/* @     */ 11 : p_nxt =
		/* !p    */ 12 : p_nxt = p_inca;
//		/* !+    */ 13 : p_nxt =
//		/* !b    */ 14 : p_nxt =
//		/* !     */ 15 : p_nxt =
//		/* +*    */ 16 : p_nxt =
//		/* 2*    */ 17 : p_nxt =
//		/* 2/    */ 18 : p_nxt =
//		/* -     */ 19 : p_nxt =
//		/* +     */ 20 : p_nxt =
//		/* and   */ 21 : p_nxt =
//		/* or    */ 22 : p_nxt =
//		/* drop  */ 23 : p_nxt =
//		/* dup   */ 24 : p_nxt =
//		/* pop   */ 25 : p_nxt =
//		/* over  */ 26 : p_nxt =
//		/* a     */ 27 : p_nxt =
//		/* .     */ 28 : p_nxt =
//		/* push  */ 29 : p_nxt =
//		/* b!    */ 30 : p_nxt =
//		/* a!    */ 31 : p_nxt =
		default          p_nxt = (slot == 0) ? p_inca : p;
	endcase

always_comb
	case (instr) // t_nxt
//		/* ;     */  0 : t_nxt = 
//		/* ex    */  1 : t_nxt = 
//		/* jump  */  2 : t_nxt = 
//		/* call  */  3 : t_nxt = 
//		/* unext */  4 : t_nxt = 
//		/* next  */  5 : t_nxt = 
//		/* if    */  6 : t_nxt = 
//		/* -if   */  7 : t_nxt = 
		/* @ p   */  8 : t_nxt = mem_sda;
		/* @ +   */  9 : t_nxt = mem_sda;
		/* @ b   */ 10 : t_nxt = mem_sda;
		/* @     */ 11 : t_nxt = mem_sda;
		/* !p    */ 12 : t_nxt = s;
		/* !+    */ 13 : t_nxt = s;
		/* !b    */ 14 : t_nxt = s;
		/* !     */ 15 : t_nxt = s;
		/* +*    */ 16 : t_nxt = tsa[18:1];
		/* 2*    */ 17 : t_nxt = {t [16: 0], t [    0]};
		/* 2/    */ 18 : t_nxt = {t [17   ], t [17: 1]};
		/* -     */ 19 : t_nxt = ~t;
		/* +     */ 20 : t_nxt = p [9] ? (t + s + cf) : ts;
		/* and   */ 21 : t_nxt = t & s;
		/* or    */ 22 : t_nxt = t ^ s;
		/* drop  */ 23 : t_nxt = s;
//		/* dup   */ 24 : t_nxt = 
		/* pop   */ 25 : t_nxt = r;
		/* over  */ 26 : t_nxt = mem_sda;
		/* a     */ 27 : t_nxt = a;
//		/* .     */ 28 : t_nxt = 
//		/* push  */ 29 : t_nxt = 
//		/* b!    */ 30 : t_nxt = 
//		/* a!    */ 31 : t_nxt = 
		default          t_nxt = t;
	endcase

always_comb
	case (instr) // a_nxt
//		/* ;     */  0 : a_nxt =
//		/* ex    */  1 : a_nxt =
//		/* jump  */  2 : a_nxt =
//		/* call  */  3 : a_nxt =
//		/* unext */  4 : a_nxt =
//		/* next  */  5 : a_nxt =
//		/* if    */  6 : a_nxt =
//		/* -if   */  7 : a_nxt =
//		/* @ p   */  8 : a_nxt =
//		/* @ +   */  9 : a_nxt =
//		/* @ b   */ 10 : a_nxt =
//		/* @     */ 11 : a_nxt =
//		/* !p    */ 12 : a_nxt =
//		/* !+    */ 13 : a_nxt =
//		/* !b    */ 14 : a_nxt =
//		/* !     */ 15 : a_nxt =
		/* +*    */ 16 : a_nxt = {tsa[0], a[17:1]};
//		/* 2*    */ 17 : a_nxt =
//		/* 2/    */ 18 : a_nxt =
//		/* -     */ 19 : a_nxt =
//		/* +     */ 20 : a_nxt =
//		/* and   */ 21 : a_nxt =
//		/* or    */ 22 : a_nxt =
//		/* drop  */ 23 : a_nxt =
//		/* dup   */ 24 : a_nxt =
//		/* pop   */ 25 : a_nxt =
//		/* over  */ 26 : a_nxt =
//		/* a     */ 27 : a_nxt =
//		/* .     */ 28 : a_nxt =
//		/* push  */ 29 : a_nxt =
//		/* b!    */ 30 : a_nxt =
		/* a!    */ 31 : a_nxt = t;
		default          a_nxt = a;
	endcase

always_comb
	case (instr) // b_nxt
//		/* ;     */  0 : b_nxt =
//		/* ex    */  1 : b_nxt =
//		/* jump  */  2 : b_nxt =
//		/* call  */  3 : b_nxt =
//		/* unext */  4 : b_nxt =
//		/* next  */  5 : b_nxt =
//		/* if    */  6 : b_nxt =
//		/* -if   */  7 : b_nxt =
//		/* @ p   */  8 : b_nxt =
//		/* @ +   */  9 : b_nxt =
//		/* @ b   */ 10 : b_nxt =
//		/* @     */ 11 : b_nxt =
//		/* !p    */ 12 : b_nxt =
//		/* !+    */ 13 : b_nxt =
//		/* !b    */ 14 : b_nxt =
//		/* !     */ 15 : b_nxt =
//		/* +*    */ 16 : b_nxt =
//		/* 2*    */ 17 : b_nxt =
//		/* 2/    */ 18 : b_nxt =
//		/* -     */ 19 : b_nxt =
//		/* +     */ 20 : b_nxt =
//		/* and   */ 21 : b_nxt =
//		/* or    */ 22 : b_nxt =
//		/* drop  */ 23 : b_nxt =
//		/* dup   */ 24 : b_nxt =
//		/* pop   */ 25 : b_nxt =
//		/* over  */ 26 : b_nxt =
//		/* a     */ 27 : b_nxt =
//		/* .     */ 28 : b_nxt =
//		/* push  */ 29 : b_nxt =
		/* b!    */ 30 : b_nxt = t [8:0];
//		/* a!    */ 31 : b_nxt =
		default          b_nxt = b;
	endcase

always_comb
	case (instr) // s_nxt
//		/* ;     */  0 : s_nxt = 
//		/* ex    */  1 : s_nxt = 
//		/* jump  */  2 : s_nxt = 
//		/* call  */  3 : s_nxt = 
//		/* unext */  4 : s_nxt = 
//		/* next  */  5 : s_nxt = 
//		/* if    */  6 : s_nxt = 
//		/* -if   */  7 : s_nxt = 
		/* @ p   */  8 : s_nxt = t;
		/* @ +   */  9 : s_nxt = t;
		/* @ b   */ 10 : s_nxt = t;
		/* @     */ 11 : s_nxt = t;
		/* !p    */ 12 : s_nxt = dsq;
		/* !+    */ 13 : s_nxt = dsq;
		/* !b    */ 14 : s_nxt = dsq;
		/* !     */ 15 : s_nxt = dsq;
//		/* +*    */ 16 : s_nxt =
//		/* 2*    */ 17 : s_nxt =
//		/* 2/    */ 18 : s_nxt =
//		/* -     */ 19 : s_nxt =
		/* +     */ 20 : s_nxt = dsq;
		/* and   */ 21 : s_nxt = dsq;
		/* or    */ 22 : s_nxt = dsq;
		/* drop  */ 23 : s_nxt = dsq;
		/* dup   */ 24 : s_nxt = t;
		/* pop   */ 25 : s_nxt = t;
		/* over  */ 26 : s_nxt = t;
		/* a     */ 27 : s_nxt = t;
//		/* .     */ 28 : s_nxt = 
		/* push  */ 29 : s_nxt = dsq;
		/* b!    */ 30 : s_nxt = dsq;
		/* a!    */ 31 : s_nxt = dsq;
		default          s_nxt = s;
	endcase

always_comb
	case (instr) // mem_adr
		/* ;     */  0 : mem_adr  = r [8:0];
//		/* ex    */  1 : mem_adr  =
		/* jump  */  2 : mem_adr  = jumpa;
		/* call  */  3 : mem_adr  = jumpa;
//		/* unext */  4 : mem_adr  =
		/* next  */  5 : mem_adr  = |r           ? jumpa : p;
		/* if    */  6 : mem_adr  = (t     == 0) ? jumpa : p;
		/* -if   */  7 : mem_adr  = (t[17] == 0) ? jumpa : p;
//		/* @ p   */  8 : mem_adr  =
		/* @ +   */  9 : mem_adr  = a;
		/* @ b   */ 10 : mem_adr  = b;
		/* @     */ 11 : mem_adr  = a;
//		/* !p    */ 12 : mem_adr  =
		/* !+    */ 13 : mem_adr  = a;
		/* !b    */ 14 : mem_adr  = b;
		/* !     */ 15 : mem_adr  = a;
//		/* +*    */ 16 : mem_adr  =
//		/* 2*    */ 17 : mem_adr  =
//		/* 2/    */ 18 : mem_adr  =
//		/* -     */ 19 : mem_adr  =
//		/* +     */ 20 : mem_adr  =
//		/* and   */ 21 : mem_adr  =
//		/* or    */ 22 : mem_adr  =
//		/* drop  */ 23 : mem_adr  =
//		/* dup   */ 24 : mem_adr  =
//		/* pop   */ 25 : mem_adr  =
//		/* over  */ 26 : mem_adr  =
//		/* a     */ 27 : mem_adr  =
//		/* .     */ 28 : mem_adr  =
//		/* push  */ 29 : mem_adr  =
//		/* b!    */ 30 : mem_adr  =
//		/* a!    */ 31 : mem_adr  =
		default          mem_adr  = p;
	endcase

always_comb
	case (slot)
		    3 : i_nxt = mem_sda;
		default i_nxt = i;
	endcase

always_comb
	case (slot)
		    0 : slot_nxt = 1;
		    1 : slot_nxt = 2;
		    2 : slot_nxt = 3;
		default slot_nxt = mem_ack ? 0 : slot;
	endcase

always_ff @ (posedge clk or negedge reset_n)
	if (~reset_n)     i <= 18'b 101100100110110010;
	else if (mem_ack) i <= i_nxt;

always_ff @ (posedge clk or negedge reset_n)
	if (~reset_n)     p <= 0;
	else if (mem_ack) p <= p_nxt;

always_ff @ (posedge clk or negedge reset_n)
	if (~reset_n) slot <= 3;
	else          slot <= slot_nxt;

always_ff @ (posedge clk) t <= t_nxt;
always_ff @ (posedge clk) s <= s_nxt;
always_ff @ (posedge clk) r <= r_nxt;
always_ff @ (posedge clk) a <= a_nxt;
always_ff @ (posedge clk) b <= b_nxt;

logic [17:0] q_rom;
logic  [5:0] addr_rom;

always_ff @ (posedge clk) if (mem_req) addr_rom <= mem_adr [5:0];



always_comb
	case (addr_rom) // ROM
//; print Hornet::asm2case ("f/gcd.f");
		default q_rom = 18'b 101100100110110010; // 2C9B2 --- 00C . . . .
	endcase

assign mem_sda = q_rom;

endmodule // hornet
