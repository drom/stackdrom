onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/DUT/clk
add wave -noupdate /tb/DUT/reset_n
add wave -noupdate /tb/DUT/mem_req
add wave -noupdate -radix unsigned /tb/DUT/mem_adr
add wave -noupdate /tb/DUT/mem_ack
add wave -noupdate -radix hexadecimal /tb/DUT/mem_sda
add wave -noupdate -radix hexadecimal /tb/DUT/i
add wave -noupdate -radix unsigned /tb/DUT/p
add wave -noupdate -radix unsigned /tb/DUT/p_nxt
add wave -noupdate -radix unsigned /tb/DUT/slot
add wave -noupdate -radix unsigned /tb/DUT/slot0
add wave -noupdate -radix unsigned /tb/DUT/slot1
add wave -noupdate -radix unsigned /tb/DUT/slot2
add wave -noupdate -radix unsigned /tb/DUT/slot3
add wave -noupdate -radix unsigned /tb/DUT/instr
add wave -noupdate -divider Stacks
add wave -noupdate -radix decimal -childformat {{{/tb/DUT/t[17]} -radix decimal} {{/tb/DUT/t[16]} -radix decimal} {{/tb/DUT/t[15]} -radix decimal} {{/tb/DUT/t[14]} -radix decimal} {{/tb/DUT/t[13]} -radix decimal} {{/tb/DUT/t[12]} -radix decimal} {{/tb/DUT/t[11]} -radix decimal} {{/tb/DUT/t[10]} -radix decimal} {{/tb/DUT/t[9]} -radix decimal} {{/tb/DUT/t[8]} -radix decimal} {{/tb/DUT/t[7]} -radix decimal} {{/tb/DUT/t[6]} -radix decimal} {{/tb/DUT/t[5]} -radix decimal} {{/tb/DUT/t[4]} -radix decimal} {{/tb/DUT/t[3]} -radix decimal} {{/tb/DUT/t[2]} -radix decimal} {{/tb/DUT/t[1]} -radix decimal} {{/tb/DUT/t[0]} -radix decimal}} -subitemconfig {{/tb/DUT/t[17]} {-height 16 -radix decimal} {/tb/DUT/t[16]} {-height 16 -radix decimal} {/tb/DUT/t[15]} {-height 16 -radix decimal} {/tb/DUT/t[14]} {-height 16 -radix decimal} {/tb/DUT/t[13]} {-height 16 -radix decimal} {/tb/DUT/t[12]} {-height 16 -radix decimal} {/tb/DUT/t[11]} {-height 16 -radix decimal} {/tb/DUT/t[10]} {-height 16 -radix decimal} {/tb/DUT/t[9]} {-height 16 -radix decimal} {/tb/DUT/t[8]} {-height 16 -radix decimal} {/tb/DUT/t[7]} {-height 16 -radix decimal} {/tb/DUT/t[6]} {-height 16 -radix decimal} {/tb/DUT/t[5]} {-height 16 -radix decimal} {/tb/DUT/t[4]} {-height 16 -radix decimal} {/tb/DUT/t[3]} {-height 16 -radix decimal} {/tb/DUT/t[2]} {-height 16 -radix decimal} {/tb/DUT/t[1]} {-height 16 -radix decimal} {/tb/DUT/t[0]} {-height 16 -radix decimal}} /tb/DUT/t
add wave -noupdate -radix decimal /tb/DUT/s
add wave -noupdate -radix decimal /tb/DUT/dsq
add wave -noupdate -radix decimal /tb/DUT/r
add wave -noupdate -radix decimal /tb/DUT/rsq
add wave -noupdate /tb/DUT/a
add wave -noupdate -divider rest
add wave -noupdate /tb/DUT/t_nxt
add wave -noupdate /tb/DUT/s_nxt
add wave -noupdate /tb/DUT/r_nxt
add wave -noupdate /tb/DUT/r_dec
add wave -noupdate /tb/DUT/a_nxt
add wave -noupdate /tb/DUT/i_nxt
add wave -noupdate /tb/DUT/ts
add wave -noupdate /tb/DUT/tsa
add wave -noupdate /tb/DUT/p_inca
add wave -noupdate /tb/DUT/b
add wave -noupdate /tb/DUT/b_nxt
add wave -noupdate /tb/DUT/slot_nxt
add wave -noupdate /tb/DUT/p_inc
add wave -noupdate /tb/DUT/cf
add wave -noupdate /tb/DUT/jumpa
add wave -noupdate /tb/DUT/q_rom
add wave -noupdate /tb/DUT/addr_rom
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {10000 ns} 0}
configure wave -namecolwidth 150
configure wave -valuecolwidth 161
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {72319 ns}
