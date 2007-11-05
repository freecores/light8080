;*******************************************************************************
; light8080 core test bench 1
; interrupt & halt test
;*******************************************************************************
; When used in the test bench vhdl\test\light8080_tb1.vhdl, this program 
; should take 410 clock cycles to compplete, ending in halt state.
; At that moment, a 055h value in ACC means success and a 0aah  means failure.
;*******************************************************************************

        org     0H
        jmp     start
        
        ; this will be used as interrupt routine
        org     20H
        adi     7H
        ei
        ret
        
        ; used as rst test
        org     28H
        mov     b,a
        ret
                
start:  org     40H
        lxi     sp,stack
        ei
        mvi     a,0H      ; a=0, b=?
        rst     5         ; rst 28h -> a=00h, b=00h 
        adi     1H        ; a = 08h (interrupt 1 hits here: a = a + 07h)
        adi     1H        ; a = 09h
        adi     1H        ; a = 0ah
        adi     1H        ; a = 0bh
        adi     1H        ; a = 0ch (interrupt 2 hits here: c = 0ch)
        adi     1H        ; a = 0dh
        adi     1H        ; a = 0eh
        ei
        adi     1H        ; a = 0fh
        adi     1H        ; a = 10h
        adi     1H        ; a = 11h
        ei
        hlt               ; (interrupt 3 hits when in halt: nop )
        cpi     11h
        jnz     fail
        mov     a,b
        cpi     0
        jnz     fail
        mov     a,c 
        cpi     0ch
        jnz     fail
        mov     a,d 
        cpi     12h
        mov     a,e 
        cpi     34h
        jnz     fail
        mvi     a,55h
        hlt
fail:   mvi     a,0aah
        hlt        
        
        org     100H
        adi     9h
        mvi     b,77h
        ei
        ret
        
        ; data space
        ds      256
stack:  dw      0        
