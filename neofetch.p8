%launcher none
%option no_sysinit
%zeropage basicsafe
%address $4000

shell {
    romsub $06e0 = print(str string @AY) clobbers(A,Y)
    romsub $06e3 = print_uw(uword value @AY) clobbers(A,Y)
    romsub $06e6 = print_uwhex(uword value @ AY, bool prefix @ Pc) clobbers(A,Y)
    romsub $06e9 = print_uwbin(uword value @ AY, bool prefix @ Pc) clobbers(A,Y)
    romsub $06ec = input_chars(uword buffer @ AY) clobbers(A) -> ubyte @Y
    romsub $06ef = err_set(str message @AY) clobbers(Y) -> bool @A

    ; input registers set by shell upon calling your command:
    ;    cx16.r0 = command address
    ;    cx16.r1 = length of command (byte)
    ;    cx16.r2 = arguments address
    ;    cx16.r3 = length of arguments (byte)

    ; command should return error status in A. You can use err_set() to set a specific error message for the shell.
    ; command CAN use the FREE zero page locations.
    ; command CANNOT use memory below $4000 (the shell sits there)
    ; command CAN use Ram $0400-$06df.
}

main $4000 {
    %option force_output
	
	sub start(){
	
		const ubyte COLOR_NORMAL = 1
		const ubyte COLOR_HIGHLIGHT = 14 ; sadly it doesn't seem like those numbers can be fetched directly from shell.prg
		
		color(4)
		shell.print(iso:"\r  o                   o  ")
		
		color(COLOR_HIGHLIGHT)
		shell.print(iso:"OS")
		color(COLOR_NORMAL)
		shell.print(iso:": Commander X16 BASIC v2 Rom ")
		byte ver = @($ff80) as byte
		if ver == -1
			shell.print(iso:"unstable") 
		else{
			shell.print(iso:"R")
			if ver < 0 ver *= -1
			shell.print_uw(ver as uword)
		}
		
		color(4)
		shell.print(iso:"\r  M@\\               /@M  ")
		
		color(COLOR_HIGHLIGHT)
		shell.print(iso:"Host")
		color(COLOR_NORMAL)
		shell.print(iso:": Commander X16 ")
		if (@($9FBE)==$31) and (@($9FBF) == $36) 
			shell.print(iso:"Official Emulator") 
		else shell.print(iso:"gen1 board")
		; TODO add functionality to distinguish gen2 and gen3 if it's going to be possible. 
		; Additionally add support for distinguishing Box16
		
		color(14)
		shell.print(iso:"\r  M@@@\\           /@@@M  ")
		
		color(COLOR_HIGHLIGHT)
		shell.print(iso:"Shell")
		color(COLOR_NORMAL)
		shell.print(iso:": SHELL.PRG") ;are version numbers even a thing there?
		
		color(14)
		shell.print(iso:"\r  :@@@@@\\       /@@@@@:  ")
		
		color(COLOR_HIGHLIGHT)
		shell.print(iso:"Resolution")
		color(COLOR_NORMAL)
		ubyte resx=0
		ubyte resy=0
		%asm {{  
			jsr cx16.get_screen_mode
			stx p8_main.p8_start.p8_resx
			sty  p8_main.p8_start.p8_resy 
			}}
		shell.print(iso:": ")
		shell.print_uw((resx as uword)*8)
		shell.print(iso:"x")
		shell.print_uw((resy as uword)*8)
		
		color(3)
		shell.print(iso:"\r   \\@@@@@@\\   /@@@@@@/   ")
		
		color(COLOR_HIGHLIGHT)
		shell.print(iso:"CPU")
		color(COLOR_NORMAL)
		shell.print(iso:": WDC ")
		if cputype()
			shell.print(iso:"65c816")
		else shell.print(iso:"65c02")
		shell.print(iso:" (1) @ 8MHz")
		
		color(5)
		shell.print(iso:"\r     \'\'\"\"**N N**\"\"\'\'     ")
		
		color(COLOR_HIGHLIGHT)
		shell.print(iso:"GPU")
		color(COLOR_NORMAL)
		shell.print(iso:": VERA module ")
		ubyte tmp_ctrl = cx16.VERA_CTRL
		cx16.VERA_CTRL = $7e
		if cx16.VERA_DC_VER0 == $56 {
			shell.print(iso:"v")
			shell.print_uw(cx16.VERA_DC_VER1 as uword)
			shell.print(iso:".")
			shell.print_uw(cx16.VERA_DC_VER2 as uword)
			shell.print(iso:".")
			shell.print_uw(cx16.VERA_DC_VER3 as uword)
		}
		cx16.VERA_CTRL = tmp_ctrl
		
		color(7)
		shell.print(iso:"\r           N N           ")
		
		color(COLOR_HIGHLIGHT)
		shell.print(iso:"Memory")
		color(COLOR_NORMAL)
		shell.print(iso:": ")
		shell.print_uw((sys.progend()-737) / 1024) ; 735 bytes of free golden ram + 2 bank registers = 737
		shell.print(iso:"KiB / ")
		shell.print_uw((cbm.MEMTOP(0, true)-2) / 1024)
		shell.print(iso:"KiB")
		
		color(7)
		shell.print(iso:"\r       ..-*N N*-..       ")
		
		color(COLOR_HIGHLIGHT)
		shell.print(iso:"Hi-Memory")
		color(COLOR_NORMAL)
		shell.print(iso:": ")
		shell.print_uw(cx16.numbanks() * $0008)
		shell.print(iso:"KiB (")
		shell.print_uw(cx16.numbanks())
		shell.print(iso:" banks)")
		
		color(8)
		shell.print(iso:"\r    :@@@@@/   \\@@@@@:    ")
		color(2)
		shell.print(iso:"\r    M@@@/       \\@@@M    ")
		
		ubyte j
		for j in 0 to 15{
			color(j)
			shell.print(iso:"\xad#")
		}
		
		color(2)
		shell.print(iso:"\r    M@/           \\@M    ")
		
		shell.print(iso:"\r")
		sys.exit(0)
	}
	
	sub color (ubyte txtcol) {
		ubyte[16] color_to_charcode = [$90,$05,$1c,$9f,$9c,$1e,$1f,$9e,$81,$95,$96,$97,$98,$99,$9a,$9b]
		txtcol &= 15
		cbm.CHROUT(color_to_charcode[txtcol])
	}
	asmsub cputype() ->bool @A{
		%asm {{
			php
			bit #0
			.byte $e2, $ea ; should be interpreted as 2 NOPs by 65c02. 65c816 will set the Negative flag
			bpl +
			lda #1
			plp
			rts
+			lda #0
			plp
			rts
		}}
	}
}