%launcher none
%option no_sysinit
%zeropage dontuse
%import shellroutines
%import conv ;sadly, i really needed to import this this time 3-(
%import strings ;for some reason it asks me to import it, I've never had to 
               ;implicitly import this lib up to this point
%encoding iso
%address $4000

main {
	%option force_output
	
	sub start(){
		
		shellcolors=$bf00 ;ahh yes, repurposing vars as much as we can B-)
		
		ubyte resx=0
		ubyte resy=0
		%asm {{  
			jsr cx16.get_screen_mode
			sta p8b_logo.p8v_id
			stx p8v_resx
			sty p8v_resy 
			}}
		cx16.rambank(0)
		if strings.length(shellcolors)>0{
			while strings.isspace(shellcolors[0]){
				shellcolors++
			}
			j=conv.str2ubyte(shellcolors)
			if cx16.r15==0{
				shell.err_set("Command argument wasn't readable")
			}
			else if j>=len(logo.list){
				shell.err_set("We don't have that many layout variants...")
			}
			else{
				logo.id=j
			}
		}
		if logo.id==7{
			logo.m7_remove_padding()
		}
		tmp_ctrl=logo.listb[logo.id]
		logo.load()
		if tmp_ctrl&logo.type.above!=0{
			logo.printall()
			logo.id=4
			logo.load()
		}
		if tmp_ctrl&1!=0{
			sys.exit(0)
		}

		uword shellcolors=shell.get_text_colors()
		uword JDspeed=hertz_check()

		logo.print()

		color(shellcolors[2])
		shell.print("OS")
		color(shellcolors[0])
		shell.print(": Commander X16 KERNAL ")
		cx16.rombank(0)
		byte ver = @($ff80) as byte
		if ver == -1
			shell.print("unstable") 
		else{
			if ver < 0 {
				ver *= -1
				shell.print("pre-") 
			}
			shell.chrout('R')
			shell.print_ub(ver as ubyte)
		}
		
		logo.print()
		
		color(shellcolors[2])
		shell.print("Host")
		color(shellcolors[0])
		shell.print(": Commander X16 ")
		if (@($9FBE)==$31) and (@($9FBF) == $36) 
			shell.print("Emulator") 
		else shell.print("gen1 board")
		; TODO add functionality to distinguish gen2 and gen3 if it's going to be possible. 
		
		logo.print()
		
		color(shellcolors[2])
		shell.print("Shell")
		color(shellcolors[0])
		shell.print(": SHELL.PRG ") ;are version numbers even a thing there?
		shell.print(shell.version()) ;yes, there are now!
		
		logo.print()
		
		color(shellcolors[2])
		shell.print("Resolution")
		color(shellcolors[0])
		shell.print(": ")
		shell.print_uw((resx as uword)*8)
		shell.chrout('x')
		shell.print_uw((resy as uword)*8)
		
		logo.print()
		
		color(shellcolors[2])
		shell.print("CPU")
		color(shellcolors[0])
		shell.print(": WDC ")
		if cputype()
			shell.print("65c816")
		else shell.print("65c02")
		shell.print(" (1) @ ")
		;shell.print_uwhex(JDspeed,true)
		;shell.chrout(' ')
		print_hertz(msb(JDspeed))
		shell.print("MHz")
		
		logo.print()
		
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
		
		logo.print()
		
		color(shellcolors[2])
		shell.print("Memory")
		color(shellcolors[0])
		shell.print(": ")
		shell.print_uw((sys.progend()-737) / 1024) ; 735 bytes of free golden ram + 2 bank registers = 737
		shell.print("KiB / ")
		shell.print_uw((MEMTOP()-2) / 1024)
		shell.print("KiB")
		
		logo.print()
		
		color(shellcolors[2])
		shell.print("Hi-Memory")
		color(shellcolors[0])
		shell.print(": ")
		shell.print_uw(cx16.numbanks() * $0008)
		shell.print("KiB (")
		shell.print_uw(cx16.numbanks())
		shell.print(" banks)")
		
		logo.print()
		logo.print()
		
		ubyte j
		for j in 0 to 15{
			color(j)
			shell.print("\xad#")
		}
		
		logo.printall()
		
		color(shellcolors[0])
		shell.chrout('\r')
		sys.exit(0)
	}
	
	asmsub color(ubyte txtcol @X) clobbers(A){
		%asm{{
			lda color_to_charcode,x
			jmp cbm.CHROUT
		color_to_charcode	.byte  $90, $05, $1c, $9f, $9c, $1e, $1f, $9e, $81, $95, $96, $97, $98, $99, $9a, $9b
			; !notreached!
		}}
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
		+	lda #0
			plp
			rts
		}}
	}

	; function, that checks how fast is the cpu (bigger number = faster cpu)
	; created bt JimmyDansbo. Og code here: https://gist.github.com/JimmyDansbo/bbbf8d9da8916d995af689248a266d9a
	asmsub hertz_check() -> uword @R0{
		%asm{{
			stz	cx16.r0		; Ensure our cx16.r0 variable is zero
			stz	cx16.r0+1
			stz	P8ZP_SCRATCH_REG	; Ensure trigger variable is zero

			; Save original interrupt vector address
			lda	cbm.CINV
			sta	P8ZP_SCRATCH_W1
			lda	cbm.CINV+1
			sta	P8ZP_SCRATCH_W1+1

			; Install new interrupt handler
			sei
			lda	#<vera_tick
			sta	cbm.CINV
			lda	#>vera_tick
			sta	cbm.CINV+1
			cli
			
			; Wait for an interrupt to ensure that we start the timing at
			; the beginning of an interrupt
		firstwait
			wai
			lda	P8ZP_SCRATCH_REG
			beq	firstwait
			stz	P8ZP_SCRATCH_REG

			; Now we do as many counts as we can until next interrupt
		timing
			inc	cx16.r0
			bne	+
			inc	cx16.r0+1
		+	lda	P8ZP_SCRATCH_REG
			beq	timing

			; Uninstall interrupt handler
			sei			; Disable interrupts
			lda	P8ZP_SCRATCH_W1
			sta	cbm.CINV
			lda	P8ZP_SCRATCH_W1+1
			sta	cbm.CINV+1
			cli			; Enable interrupts

			; use print_hertz() function to print the hertz value

			rts

			; Ensure P8ZP_SCRATCH_REG is non-zero when irq happens
		vera_tick
			lda	cx16.VERA_ISR
			and	#1		; Is this VSYNC?
			beq	+		; if not, end
			sta	P8ZP_SCRATCH_REG
		+	jmp	(P8ZP_SCRATCH_W1)
		}}
	}
	asmsub print_hertz(ubyte j @A) clobbers(A){
		%asm{{
			cmp	#$59	; If highbyte of counter >= $59 then 20 MHz or more
			bcc +
			jmp	_do20
		+	cmp	#$55	; If highbyte of counter >= $55 then 19 MHz 
			bcc +
			jmp	_do19
		+	cmp	#$50	; If highbyte of counter >= $50 then 18 MHz
			bcc +
			jmp	_do18
		+	cmp	#$4B	; If highbyte of counter >= $4B then 17 MHz
			bcc +
			jmp	_do17
		+	cmp	#$47	; If highbyte of counter >= $47 then 16 MHz
			bcc +
			jmp	_do16
		+	cmp	#$42	; If highbyte of counter >= $42 then 15 MHz
			bcc +
			jmp	_do15
		+	cmp	#$3D	; If highbyte of counter >= $3D then 14 MHz
			bcc +
			jmp	_do14
		+	cmp	#$39	; If highbyte of counter >= $39 then 13 MHz
			bcc +
			jmp	_do13
		+	cmp	#$34	; If highbyte of counter >= $34 then 12 MHz
			bcc +
			jmp	_do12
		+	cmp	#$2F	; If highbyte of counter >= $2F then 11 MHz
			bcc +
			jmp	_do11
		+	cmp	#$2B	; If highbyte of counter >= $2B then 10 MHz
			bcc +
			jmp	_do10
		+	cmp	#$26	; If highbyte of counter >= $26 then 9 MHz
			bcc	+
			lda	#$39
			jmp	_endstr
		+	cmp	#$21	; If highbyte of counter >= $21 then 8 MHz
			bcc	+
			lda	#$38
			jmp	_endstr
		+	cmp	#$1D	; If highbyte of counter >= $1D then 7 MHz
			bcc	+
			lda	#$37
			jmp	_endstr
		+	cmp	#$18	; If highbyte of counter >= $18 then 6 MHz
			bcc	+
			lda	#$36
			jmp	_endstr
		+	cmp	#$13	; If highbyte of counter >= $13 then 5 MHz
			bcc	+
			lda	#$35
			bra	_endstr
		+	cmp	#$0F	; If highbyte of counter >= $0F then 4 MHz
			bcc	+
			lda	#$34
			bra	_endstr
		+	cmp	#$0A	; If highbyte of counter >= $0A then 3 MHz
			bcc	+
			lda	#$33
			bra	_endstr
		+	cmp	#$05	; If highbyte of counter >= $05 then 2 MHz
			bcc	+
			lda	#$32
			bra	_endstr
		+	lda	#$31	; Otherwise system is most likely running at 1 MHz
			bra	_endstr
		_do20	lda	#$3e
			jsr	cbm.CHROUT
		_do19	lda	#$31
			jsr	cbm.CHROUT
			lda	#$39
			bra	_endstr
		_do18	lda	#$31
			jsr	cbm.CHROUT
			lda	#$38
			bra	_endstr
		_do17	lda	#$31
			jsr	cbm.CHROUT
			lda	#$37
			bra	_endstr
		_do16	lda	#$31
			jsr	cbm.CHROUT
			lda	#$36
			bra	_endstr
		_do15	lda	#$31
			jsr	cbm.CHROUT
			lda	#$35
			bra	_endstr
		_do14	lda	#$31
			jsr	cbm.CHROUT
			lda	#$34
			bra	_endstr
		_do13	lda	#$31
			jsr	cbm.CHROUT
			lda	#$33
			bra	_endstr
		_do12	lda	#$31
			jsr	cbm.CHROUT
			lda	#$32
			bra	_endstr
		_do11	lda	#$31
			jsr	cbm.CHROUT
			bra	_endstr
		_do10	lda	#$31
			jsr	cbm.CHROUT
			lda	#$30

		_endstr
			jmp	cbm.CHROUT	; Write the calculated MHz number
		}}
	}
	inline asmsub MEMTOP() -> uword @ XY{
		%asm{{
			sec
			jsr cbm.MEMTOP
		}}
	}
}
logo{
	uword[] list=[
		&square,	;0
		&original,	;1
		&square,	;2
		&original,	;3
		&empty,		;4
		&smallsq,	;5
		&smallsq,	;6
		&square,	;7
		&square,	;8
		&original,	;9
		&square,	;10
		&original,	;11
		&smallsq,	;12
		&smallsq,	;13
		&original	;14
	]
	ubyte[] listh=[
		len(square),	;0
		len(original),	;1
		len(square),	;2
		len(original),	;3
		len(empty),		;4
		len(smallsq),	;5
		len(smallsq),	;6
		len(square),	;7
		len(square),	;8
		len(original),	;9
		len(square),	;10
		len(original),	;11
		len(smallsq),	;12
		len(smallsq),	;13
		len(original)	;14
	]
	ubyte[] listb=[
		logo.type.normal,	;0
		logo.type.normal,	;1
		logo.type.above,	;2
		logo.type.above,	;3
		logo.type.normal,	;4
		logo.type.onlylogo,	;5
		logo.type.onlylogo,	;6
		logo.type.onlylogo,	;7
		logo.type.normal,	;8
		logo.type.normal,	;9
		logo.type.above,	;10
		logo.type.above,	;11
		logo.type.normal,	;12
		logo.type.above,	;13
		logo.type.onlylogo	;14
	]
	sub type(){
		const ubyte normal=0
		const ubyte onlylogo=3
		const ubyte above=2
	}
	str[] original=[
		"\r\x9c  o                   o  ",
		"\r\x9c  M@\\               /@M  ",
		"\r\x9a  M@@@\\           /@@@M  ",
		"\r\x9a  :@@@@@\\       /@@@@@:  ",
		"\r\x9f   \\@@@@@@\\   /@@@@@@/   ",
		"\r\x1e     \'\'\"\"**N N**\"\"\'\'     ",
		"\r\x9e           N N           ",
		"\r\x9e       ..-*N N*-..       ",
		"\r\x81    :@@@@@/   \\@@@@@:    ",
		"\r\x1c    M@@@/       \\@@@M    ",
		"\r\x1c    M@/           \\@M    "
	]
	str[] empty=[
		"\r","\r","\r","\r","\r","\r","\r","\r","\r","\r",""
	]
	str[] square=[
		"\r\x9c  o                   o  ",
		"\r\x9c  M\\                 /M  ",
		"\r\x9c  M@\\               /@M  ",
		"\r\x9c  M@@\\             /@@M  ",
		"\r\x9a  M@@@\\           /@@@M  ",
		"\r\x9a  M@@@@\\         /@@@@M  ",
		"\r\x9a  [@@@@@\\       /@@@@@]  ",
		"\r\x9f  :@@@@@@\\     /@@@@@@:  ",
		"\r\x9f   [@@@@@@\\   /@@@@@@]   ",
		"\r\x9f   \\@@@@@@@\\ /@@@@@@@/   ",
		"\r\x1e     \"\"@@@@N N@@@@\"\"     ",
		"\r\x1e         --N N--         ",
		"\r\x1e           N N           ",
		"\r\x9e           N N           ",
		"\r\x9e         .-N N-.         ",
		"\r\x9e     ..--@@N N@@--..     ",
		"\r\x81    :@@@@@@/ \\@@@@@@:    ",
		"\r\x81    [@@@@@/   \\@@@@@]    ",
		"\r\x1c    M@@@@/     \\@@@@M    ",
		"\r\x1c    M@@@/       \\@@@M    ",
		"\r\x1c    M@@/         \\@@M    ",
		"\r\x1c    M@/           \\@M    "
	]
	str[] smallsq=[
		"\r\x9c  o           o  ",
		"\r\x9c  M\\         /M  ",
		"\r\x9a  M@\\       /@M  ",
		"\r\x9a  :@@\\     /@@:  ",
		"\r\x9f   \\@@\\   /@@/   ",
		"\r\x1e    \'\"*N N*\"\'    ",
		"\r\x9e       N N       ",
		"\r\x9e    .-*N N*-.    ",
		"\r\x81   :@@/   \\@@:   ",
		"\r\x1c   M@/     \\@M   ",
		"\r\x1c   M/       \\M   "
	]

	ubyte id
	ubyte i=0
	uword current
	sub load(){
		current = list[id]
		i=0
	}
	sub print(){
		cx16.r0L=current[i]
		cx16.r0H=current[i+listh[logo.id]]
		shell.print(cx16.r0)
		;shell.print_ub(strings.length(cx16.r0))
		;shell.chrout('\r')
		i+=1
	}
	sub printall(){
		while i<= (listh[logo.id]-1){
			print()
		}
	}
	sub m7_remove_padding(){
		ubyte n
		for n in 0 to 7{
			@(square[n]+25)=0
		}
		@(square[8]+24)=0
		@(square[9]+24)=0
		@(square[10]+22)=0
		@(square[11]+18)=0
		@(square[12]+16)=0
		@(square[13]+16)=0
		@(square[14]+18)=0
		@(square[15]+22)=0
		for n in 16 to len(square)-1{
			@(square[n]+23)=0
		}
		for n in 0 to len(square)-1{
			void strings.copy(square[n]+4,square[n]+2)
		}
	}
	
}