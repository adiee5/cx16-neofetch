if exist ".\SHELL-FILES\commands\" (
if exist ".\SHELL-FILES\commands\neofetch" del .\SHELL-FILES\commands\neofetch
)
else md SHELL-FILES\commands
java -jar %PROG8C% neofetch.p8 -target cx16
move neofetch.prg .\SHELL-FILES\commands\neofetch
