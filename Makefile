.PHONY:  all clean install

all:  neofetch.prg

clean:
	rm -f *.prg *.asm *.vice-* SHELL-FILES/commands/neofetch
	
neofetch.prg: neofetch.p8
	p8compile $< -target cx16
	
install: neofetch.prg
	if [ ! -d ./SHELL-FILES/commands ]; then
		mkdir SHELL-FILES/commands
	fi
	mv ./neofetch.prg ./SHELL-FILES/commands/neofetch
