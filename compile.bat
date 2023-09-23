if exist ".\SHELL-CMDS\" (
if exist ".\SHELL-CMDS\neofetch" del .\SHELL-CMDS\neofetch
)
else md SHELL-CMDS
java -jar %PROG8C% neofetch.p8 -target cx16
move neofetch.prg .\SHELL-CMDS\neofetch
