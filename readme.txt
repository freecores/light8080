
The test programs have been assembled with TASM (Telemark Cross Assembler), 
a free assembler available for DOS and Linux.


FILE LIST
==========

vhdl\light8080.vhdl                     Core source (single file)

vhdl\test\light8080_tb0.vhdl            Test bench 0 (Kelly test)
vhdl\test\light8080_tb1.vhdl            Test bench 1 (Interrupts)

vhdl\demo\cs2b_light8080_demo.vhd       Demo for Cyclone 2 starter board
vhdl\demo\rs232_tx.vhdl                 Serial tx code for demo
vhdl\demo\rs232_rx.vhdl                 Serial rx code for demo
vhdl\demo\cs2b_demo.csv                 Pin assignment file for Quartus II

util\uasm.pl                            Microcode assembler
util\microrom.bat                       Sample DOS bat file for assembler

ucode\light8080.m80                     Microcode source file

synthesis\tb0_modelsim_wave.do          Modelsim macro for test bench 0
synthesis\tb1_modelsim_wave.do          Modelsim macro for test bench 1

doc\designNotes.tex                     Core documentation in LaTeX format
doc\designNotes.pdf                     Core documentation in PDF format
doc\IMSAI SCS-1 Manual.pdf              IMSAI SCS-1 original documentation

asm\tb0.asm                             Test bench 0 program assembler source
asm\tb1.asm                             Test bench 1 program assembler source
asm\hexconv.pl                          Intel HEX to VHDL converter
asm\tasmtb.bat                          BATCH script to build the test benches
asm\readme.txt                          How to assemble the sources