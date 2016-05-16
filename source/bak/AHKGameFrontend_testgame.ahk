; ---------- PUBLIC VARIABLES AND DECLARATION ----------
#SingleInstance force 
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Persistent
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

AppVersion = 0.1

INIFile = %A_ScriptDir%\AHKGameFrontend.ini
GamePath = %A_ScriptDir%\%A_ScriptName%
StringReplace GamePath, GamePath, AHKGameFrontend_, , All)

if A_IsCompiled= ;Remove .ahk
{
	GamePath = %A_ScriptDir%\%A_ScriptName%
	StringReplace GamePath, GamePath, AHKGameFrontend_, , All)
	StringReplace GamePath, GamePath, .ahk, .exe, All)
}
StringReplace GameFile, GamePath, %A_ScriptDir%\, , All)


;Disable LWindows Key
IniRead, DisableLeftWindowsKey, %INIFile%, WindowsKey, DisableLeftWindowsKey, 0
IniWrite, %DisableLeftWindowsKey%, %INIFile%, WindowsKey, DisableLeftWindowsKey 
if DisableLeftWindowsKey = 1
{
	Hotkey LWin, Disabled, On
}

;Disable RWindows Key
IniRead, DisableRightWindowsKey, %INIFile%, WindowsKey, DisableRightWindowsKey, 0
IniWrite, %DisableRightWindowsKey%, %INIFile%, WindowsKey, DisableRightWindowsKey 
if DisableRightWindowsKey = 1
{
	Hotkey RWin, Disabled, On
}

; Translate JoyPad
; IniRead, TranslateJoypadToKeyboard, %INIFile%, JoyPad, TranslateJoypadToKeyboard, 0
; IniWrite, %TranslateJoypadToKeyboard%, %INIFile%, JoyPad, TranslateJoypadToKeyboard 

;Process Priority
IniRead, ProcessPriority, %INIFile%, System, ProcessPriority, NORMAL
IniWrite, %ProcessPriority%, %INIFile%, System, ProcessPriority 

; DebugMode
IniRead, DebugMode, %INIFile%, System, DebugMode, 0
IniWrite, %DebugMode%, %INIFile%, System, DebugMode 

; ExecuteOnLaunch
IniRead, LaunchAppStart, %INIFile%, LaunchOptions, LaunchAppStart, %A_Space%
IniWrite, %LaunchAppStart%, %INIFile%, LaunchOptions, LaunchAppStart 

IniRead, LaunchAppStartDelaySeconds, %INIFile%, LaunchOptions, LaunchAppStartDelaySeconds, 0
IniWrite, %LaunchAppStartDelaySeconds%, %INIFile%, LaunchOptions, LaunchAppStartDelaySeconds 
LaunchAppStartDelaySeconds := LaunchAppStartDelaySeconds * 1000

; ExecuteOnExit
IniRead, LaunchAppQuit, %INIFile%, LaunchOptions, LaunchAppQuit, %A_Space%
IniWrite, %LaunchAppQuit%, %INIFile%, LaunchOptions, LaunchAppQuit 

IniRead, LaunchAppQuitDelaySeconds, %INIFile%, LaunchOptions, LaunchAppQuitDelaySeconds, 0
IniWrite, %LaunchAppQuitDelaySeconds%, %INIFile%, LaunchOptions, LaunchAppQuitDelaySeconds 
LaunchAppQuitDelaySeconds := LaunchAppQuitDelaySeconds * 1000

; Exit script after starting
IniRead, TerminateScriptDelaySeconds, %INIFile%, LaunchOptions, TerminateScriptDelaySeconds, %A_Space%
IniWrite, %TerminateScriptDelaySeconds%, %INIFile%, LaunchOptions, TerminateScriptDelaySeconds 

; Maximized Windowed
IniRead, MaximizedWindowed, %INIFile%, Display, MaximizedWindowed, 0
IniWrite, %MaximizedWindowed%, %INIFile%, Display, MaximizedWindowed 

; Maximized Windowed Delay
IniRead, MaximizedWindowedDelaySeconds, %INIFile%, Display, MaximizedWindowedDelaySeconds, 2
IniWrite, %MaximizedWindowedDelaySeconds%, %INIFile%, Display, MaximizedWindowedDelaySeconds 
MaximizedWindowedDelaySeconds := MaximizedWindowedDelaySeconds * -1000 ;Negative value runs timer only once

SetTimer GameRunning, 50 ;Check if the game is still running, if not then quit

; Check if game exists and make sure it doesnt get stuck in a loop
if GameFile = AHKGameFrontend.exe
{
	GoSub ShowWelcome
}
else if GameFile=
{
	GoSub ShowWelcome
}
else
{
	; Check if game exists
	IfNotExist %GameFile%
		GoSub ShowWelcome
		
	; APPLY SETTINGS
	;Run before launching
	RunWaitCheck(LaunchAppStart)
	if LaunchAppStartDelaySeconds > 0
		Sleep %LaunchAppStartDelaySeconds%
	
	;Start Game
	Run %GameFile%, , , GamePID
	
	;Set process priority
	Process priority, %GamePID%, %ProcessPriority%
	
	; Set window maximized
	if MaximizedWindowed = 1
	{
		SetTimer MaximizedWindowedDelay, %MaximizedWindowedDelaySeconds%
	}
	
	if TerminateScriptDelaySeconds =
	{
		;do nothing
	}
	else
	{
		TerminateScriptDelaySeconds := TerminateScriptDelaySeconds * 1000
		SetTimer TerminateScript, %TerminateScriptDelaySeconds%
	}
}

; ----- TRAY ICON COSMETICS -----
if A_IsCompiled
	Menu Tray, Icon, %A_ScriptDir%\%A_ScriptName%
Menu tray, NoStandard
Menu Tray, Tip, GameFrontend V%AppVersion% by Nicklas Hult
Menu tray, add, Exit, MenuHandlerExit  ; instead of default exit

; ---------------- END OF PUBLIC VARS -------
return

; Welcome message if improperly configured
ShowWelcome:
	msgbox 32, AHKGameFrontend V%AppVersion%, Welcome to AHKGameFrontend by Nicklas Hult! `n`nThis is probably the first time you are starting this program.`n`nINSTRUCTIONS HOW TO CONFIGURE`n`nTo set the game you wish to launch with GameFrontend you need to name the executable to point in the right direction by adding the EXE after an underscore "_".`n`nAHKGameFrontend_NameOfTheGame.exe`nAHKGameFrontend_hl2.exe`nAHKGameFrontend_oblivion.exe`n`nFor example if you wish to launch the game Skyrim you need to find the name of the executable (.EXE) for the game rename AHKGameFrontend.exe and place it in the same folder as the game.`nIt should look like this:`nAHKGameFrontend_TESV.EXE`n`nTo configure the available settings for the frontend run it once to create AHKGameFrontend.ini. Open this file in your favorite text editor and change the settings you wish to use!`n`nThis program will now exit!`n`nThats it! Happy Gaming!`n`nBest Regards`nNicklas Hult
	exitapp
return

; Set game to "fake" windowed fullscreen
MaximizedWindowedDelay:
	WinSet Style, -0xC40000, ahk_pid %GamePID%
	WinMove ahk_pid %GamePID%, , 0, 0, A_ScreenWidth, A_ScreenHeight
return

; Quit app
QuitApp:
	if LaunchAppQuitDelaySeconds > 0
		Sleep %LaunchAppQuitDelaySeconds%
	RunWaitCheck(LaunchAppQuit)
	exitapp
return

; TIMERS

; Is the game running?
GameRunning:
Process Exist, %GamePID%
if GamePID = 0
{
	GoSub QuitApp
}
if ErrorLevel = 0
{
	GoSub QuitApp
}
else
{
	if DebugMode = 1
		tooltip The game %GameFile% is running under PID %GamePID%
	return
}
return

; Terminate timer

TerminateScript:
	GoSub QuitApp
return

; FUNCTIONS

; Validate that the program exists before starting it
RunWaitCheck(Program)
{
	if Program =
	{
		; do nothing if data is blank
	}
	else
	{
		if FileExist(Program)
			RunWait %Program%
	}
	return
}

; Tray Icon menus
MenuHandlerExit:
	ExitApp
return

; Hotkey bindings
Disabled: ; Disable this key
Return

; 0Joy1::
; if TranslateJoypadToKeyboard = 1
; {
	; Send {G down}
	; KeyWait 2Joy1
	; Send {G up}
; }
; return
