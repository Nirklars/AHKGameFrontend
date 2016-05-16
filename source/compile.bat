taskkill /im AHKGameFrontend_exampleGame.exe
del AHKGameFrontend_exampleGame.exe
"%ProgramFiles%\AutoHotkey\Compiler\Ahk2exe.exe" /in "AHKGameFrontend_exampleGame.ahk" /icon "icon\frontend.ico" /pass "CustomPassword" /NoDecompile