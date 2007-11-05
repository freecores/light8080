onerror {resume}
quietly WaveActivateNextPane {} 0
quietly virtual signal -install /light8080_tb0/uut { (context /light8080_tb0/uut )(rbank(14) &rbank(15) )} SP
quietly virtual signal -install /light8080_tb0/uut { (context /light8080_tb0/uut )(rbank(8) &rbank(9) )} PC004
quietly virtual signal -install /light8080_tb0/uut { (context /light8080_tb0/uut )(rbank(0) &rbank(1) )} BC
quietly virtual signal -install /light8080_tb0/uut { (context /light8080_tb0/uut )(rbank(2) &rbank(3) )} DE
quietly virtual signal -install /light8080_tb0/uut { (context /light8080_tb0/uut )(rbank(4) &rbank(5) )} HL
add wave -noupdate -format Logic /light8080_tb0/clk
add wave -noupdate -format Logic /light8080_tb0/halt_o
add wave -noupdate -format Literal -radix hexadecimal /light8080_tb0/data_i
add wave -noupdate -format Literal -radix hexadecimal /light8080_tb0/data_o
add wave -noupdate -format Literal -radix hexadecimal /light8080_tb0/addr_o
add wave -noupdate -format Logic /light8080_tb0/vma_o
add wave -noupdate -format Logic /light8080_tb0/rd_o
add wave -noupdate -format Logic /light8080_tb0/wr_o
add wave -noupdate -color {Medium Slate Blue} -format Literal -label SP -radix hexadecimal /light8080_tb0/uut/SP
add wave -noupdate -color {Indian Red} -format Literal -label PC -radix hexadecimal /light8080_tb0/uut/PC004
add wave -noupdate -color Yellow -format Literal -itemcolor Yellow -label PSW -radix binary /light8080_tb0/uut/flag_reg
add wave -noupdate -color {Dark Green} -format Literal -label ACC -radix hexadecimal /light8080_tb0/uut/rbank(7)
add wave -noupdate -color Pink -format Literal -itemcolor Pink -label BC -radix hexadecimal /light8080_tb0/uut/BC
add wave -noupdate -color {Indian Red} -format Literal -itemcolor {Indian Red} -label DE -radix hexadecimal /light8080_tb0/uut/DE
add wave -noupdate -color {Yellow Green} -format Literal -itemcolor {Yellow Green} -label HL -radix hexadecimal /light8080_tb0/uut/HL
add wave -noupdate -format Literal -radix hexadecimal /light8080_tb0/uut/rbank_data
add wave -noupdate -format Literal -radix hexadecimal /light8080_tb0/uut/rbank_rd_addr
add wave -noupdate -format Literal -radix hexadecimal /light8080_tb0/uut/rbank_wr_addr
add wave -noupdate -format Logic /light8080_tb0/uut/we_rb
add wave -noupdate -format Literal -radix hexadecimal /light8080_tb0/uut/uc_addr
add wave -noupdate -format Literal -radix hexadecimal /light8080_tb0/uut/next_uc_addr
add wave -noupdate -format Literal /light8080_tb0/uut/uc_addr_sel
add wave -noupdate -format Literal -radix hexadecimal /light8080_tb0/uut/uc_jmp_addr
add wave -noupdate -format Literal -radix hexadecimal /light8080_tb0/uut/uc_ret_addr
add wave -noupdate -format Literal -radix hexadecimal /light8080_tb0/uut/t1
add wave -noupdate -format Literal -radix hexadecimal /light8080_tb0/uut/t2
add wave -noupdate -format Literal /light8080_tb0/uut/uc_flags1
add wave -noupdate -format Literal /light8080_tb0/uut/uc_flags2
add wave -noupdate -format Literal /light8080_tb0/uut/rb_addr_sel
add wave -noupdate -format Logic /light8080_tb0/uut/cy_in
add wave -noupdate -format Logic /light8080_tb0/uut/cy_in_sgn
add wave -noupdate -format Literal -radix hexadecimal /light8080_tb0/uut/alu_output
add wave -noupdate -format Literal /light8080_tb0/uut/alu_fn
add wave -noupdate -format Literal /light8080_tb0/uut/mux_fn
add wave -noupdate -format Logic /light8080_tb0/uut/use_logic
add wave -noupdate -format Literal -radix hexadecimal /light8080_tb0/uut/arith_op1
add wave -noupdate -format Literal -radix hexadecimal /light8080_tb0/uut/arith_op2
add wave -noupdate -format Literal -radix hexadecimal /light8080_tb0/uut/arith_op2_sgn
add wave -noupdate -format Literal -radix hexadecimal /light8080_tb0/uut/arith_res8
add wave -noupdate -format Literal -radix hexadecimal /light8080_tb0/uut/arith_res
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {351700000 ps} 0}
configure wave -namecolwidth 150
configure wave -valuecolwidth 70
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
update
WaveRestoreZoom {369173243 ps} {370911916 ps}
