%launcher none
%option no_sysinit
%zeropage basicsafe
%import shellroutines
%encoding iso
%address $4000

main $4000 {
    %option force_output
	
	sub start(){
	
		uword shellcolors=shell.get_text_colors()
		
		color(4)
		shell.print("\r  o                   o  ")
		
		color(shellcolors[2])
		shell.print("OS")
		color(shellcolors[0])
		shell.print(": Commander X16 KERNAL ROM ")
		cx16.rombank(0)
		byte ver = @($ff80) as byte
		if ver == -1
			shell.print("unstable") 
		else{
			shell.chrout('R')
			if ver < 0 ver *= -1
			shell.print_ub(ver as ubyte)
		}
		
		color(4)
		shell.print("\r  M@\\               /@M  ")
		
		color(shellcolors[2])
		shell.print("Host")
		color(shellcolors[0])
		shell.print(": Commander X16 ")
		if (@($9FBE)==$31) and (@($9FBF) == $36) 
			shell.print("Official Emulator") 
		else shell.print("gen1 board")
		; TODO add functionality to distinguish gen2 and gen3 if it's going to be possible. 
		; Additionally add support for distinguishing Box16
		
		color(14)
		shell.print("\r  M@@@\\           /@@@M  ")
		
		color(shellcolors[2])
		shell.print("Shell")
		color(shellcolors[0])
		shell.print(": SHELL.PRG ") ;are version numbers even a thing there?
		shell.print(shell.version()) ;yes, there are now!
		
		color(14)
		shell.print("\r  :@@@@@\\       /@@@@@:  ")
		
		color(shellcolors[2])
		shell.print("Resolution")
		color(shellcolors[0])
		ubyte resx=0
		ubyte resy=0
		%asm {{  
			jsr cx16.get_screen_mode
			stx p8v_resx
			sty  p8v_resy 
			}}
		shell.print(": ")
		shell.print_uw((resx as uword)*8)
		shell.chrout('x')
		shell.print_uw((resy as uword)*8)
		
		color(3)
		shell.print("\r   \\@@@@@@\\   /@@@@@@/   ")
		
		color(shellcolors[2])
		shell.print("CPU")
		color(shellcolors[0])
		shell.print(": WDC ")
		if cputype()
			shell.print("65c816")
		else shell.print("65c02")
		shell.print(" (1) @ 8MHz")
		
		color(5)
		shell.print("\r     \'\'\"\"**N N**\"\"\'\'     ")
		
		color(shellcolors[2])
		shell.print("GPU")
		color(shellcolors[0])
		shell.print(": VERA module ")
		ubyte tmp_ctrl = cx16.VERA_CTRL
		cx16.VERA_CTRL = $7e
		if cx16.VERA_DC_VER0 == $56 {
			shell.chrout('v')
			shell.print_ub(cx16.VERA_DC_VER1)
			shell.chrout('.')
			shell.print_ub(cx16.VERA_DC_VER2)
			shell.chrout('.')
			shell.print_ub(cx16.VERA_DC_VER3)
		}
		cx16.VERA_CTRL = tmp_ctrl
		
		color(7)
		shell.print("\r           N N           ")
		
		color(shellcolors[2])
		shell.print("Memory")
		color(shellcolors[0])
		shell.print(": ")
		shell.print_uw((sys.progend()-737) / 1024) ; 735 bytes of free golden ram + 2 bank registers = 737
		shell.print("KiB / ")
		shell.print_uw((cbm.MEMTOP(0, true)-2) / 1024)
		shell.print("KiB")
		
		color(7)
		shell.print("\r       ..-*N N*-..       ")
		
		color(shellcolors[2])
		shell.print("Hi-Memory")
		color(shellcolors[0])
		shell.print(": ")
		shell.print_uw(cx16.numbanks() * $0008)
		shell.print("KiB (")
		shell.print_uw(cx16.numbanks())
		shell.print(" banks)")
		
		color(8)
		shell.print("\r    :@@@@@/   \\@@@@@:    ")
		color(2)
		shell.print("\r    M@@@/       \\@@@M    ")
		
		ubyte j
		for j in 0 to 15{
			color(j)
			shell.print("\xad#")
		}
		
		color(2)
		shell.print("\r    M@/           \\@M    ")
		
		shell.chrout('\r')
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
			clv
			.byte $e2, $ea ; should be interpreted as 2 NOPs by 65c02. 65c816 will set the Negative flag
			bvc +
			lda #1
			plp
			rts
+			lda #0
			plp
			rts
		}}
	}
}