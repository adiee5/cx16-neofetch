.PHONY:  all clean install

all:  neofetch.prg

clean:
	rm -f *.prg *.asm *.vice-* SHELL-CMDS/neofetch
	
neofetch.prg: neofetch.p8
	p8compile $< -target cx16
	
install: neofetch.prg
	if [ ! -d ./SHELL-CMDS ]; then
		mkdir SHELL-CMDS
	fi
	mv ./neofetch.prg ./SHELL-CMDS/neofetch
