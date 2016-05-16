; ---------- PUBLIC VARIABLES AND DECLARATION ----------
#SingleInstance force 
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Persistent
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

AppVersion = 0.3

INIFile = %A_ScriptDir%\AHKGameFrontend.ini
Count := 0
; Retrieve screen height and width before launching to make sure the game doesnt mess with them
DisplayHeight = %A_ScreenHeight%
DisplayWidth = %A_ScreenWidth%

; Translate JoyPad
; IniRead, TranslateJoypadToKeyboard, %INIFile%, JoyPad, TranslateJoypadToKeyboard, 0
; IniWrite, %TranslateJoypadToKeyboard%, %INIFile%, JoyPad, TranslateJoypadToKeyboard 

;Process Priority
IniRead, ProcessPriority, %INIFile%, System, ProcessPriority, NORMAL
IniWrite, %ProcessPriority%, %INIFile%, System, ProcessPriority 

; DebugMode
IniRead, DebugMode, %INIFile%, System, DebugMode, 0
IniWrite, %DebugMode%, %INIFile%, System, DebugMode 

; PrimaryLauncher
IniRead, PrimaryLauncher, %INIFile%, Game, PrimaryLauncher, %A_Space%
IniWrite, %PrimaryLauncher%, %INIFile%, Game, PrimaryLauncher 

; Exit script after starting
IniRead, TerminateFrontendDelaySeconds, %INIFile%, Game, TerminateFrontendDelaySeconds, %A_Space%
IniWrite, %TerminateFrontendDelaySeconds%, %INIFile%, Game, TerminateFrontendDelaySeconds 

; Read path
IniRead, Path, %INIFile%, Game, Path, %A_Space%
IniWrite, %Path%, %INIFile%, Game, Path 

GoSub DetectGamePath
	
; Maximized Windowed
IniRead, MaximizedWindowed, %INIFile%, Display, MaximizedWindowed, 1
IniWrite, %MaximizedWindowed%, %INIFile%, Display, MaximizedWindowed 

; Maximized Windowed retries
IniRead, MaximizedWindowedRetry, %INIFile%, Display, MaximizedWindowedRetry, 0
IniWrite, %MaximizedWindowedRetry%, %INIFile%, Display, MaximizedWindowedRetry 

; Maximized Windowed Delay
IniRead, MaximizedWindowedDelaySeconds, %INIFile%, Display, MaximizedWindowedDelaySeconds, 2
IniWrite, %MaximizedWindowedDelaySeconds%, %INIFile%, Display, MaximizedWindowedDelaySeconds 
if MaximizedWindowedRetry = 0
{
	MaximizedWindowedDelaySeconds := MaximizedWindowedDelaySeconds * -1000 ;Negative value runs timer only once
}
else
{
	MaximizedWindowedDelaySeconds := MaximizedWindowedDelaySeconds * 1000 ;Negative value runs timer only once
}

; Hide Mouse
IniRead, HideMouseCursor, %INIFile%, Display, HideMouseCursor, 0
IniWrite, %HideMouseCursor%, %INIFile%, Display, HideMouseCursor 

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

; ExecuteOnLaunch
IniRead, LaunchAppStart, %INIFile%, ExtraLaunch, LaunchAppStart, %A_Space%
IniWrite, %LaunchAppStart%, %INIFile%, ExtraLaunch, LaunchAppStart 

IniRead, LaunchAppStartDelaySeconds, %INIFile%, ExtraLaunch, LaunchAppStartDelaySeconds, 0
IniWrite, %LaunchAppStartDelaySeconds%, %INIFile%, ExtraLaunch, LaunchAppStartDelaySeconds 
LaunchAppStartDelaySeconds := LaunchAppStartDelaySeconds * 1000

; ExecuteOnExit
IniRead, LaunchAppQuit, %INIFile%, ExtraLaunch, LaunchAppQuit, %A_Space%
IniWrite, %LaunchAppQuit%, %INIFile%, ExtraLaunch, LaunchAppQuit 

IniRead, LaunchAppQuitDelaySeconds, %INIFile%, ExtraLaunch, LaunchAppQuitDelaySeconds, 0
IniWrite, %LaunchAppQuitDelaySeconds%, %INIFile%, ExtraLaunch, LaunchAppQuitDelaySeconds 
LaunchAppQuitDelaySeconds := LaunchAppQuitDelaySeconds * 1000


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
	IfNotExist %GamePath%
		GoSub ShowWelcome
		
	; APPLY SETTINGS
	;Run before launching
	RunWaitCheck(LaunchAppStart)
	if LaunchAppStartDelaySeconds > 0
		Sleep %LaunchAppStartDelaySeconds%
	
	if PrimaryLauncher = ;Start game using another launcher?
	{
		;Start Game Normally
		Run %GameFile%, , , GamePID
	}
	else
	{
		IfNotExist %PrimaryLauncher% ;Make sure the primary launcher exists
			GoSub ShowWelcome
		;Start game using a launcher
		Run %PrimaryLauncher%, , , LauncherPID
		if DebugMode = 1
			tooltip Starting %PrimaryLauncher% using PID %LauncherPID% and waiting for %GameFile% to start...
		
		loop ;wait/loop until the game starts...
		{
			sleep 500
			Process Exist, %GameFile%
			if ErrorLevel = 0
			{
				; do nothing
			}
			else
			{
				GamePID = %ErrorLevel%
				if DebugMode = 1
					tooltip The game %GameFile% was found using PID %GamePID% proceeding...
				sleep 500
				break
			}
		}
	}
	
	;Check if the game is still running, if not then quit
	if DebugMode = 1
	{
		SetTimer GameRunning, 500 ; run slower if the debug mode is active so its easier to read the tooltip
	}
	else
	{
		SetTimer GameRunning, 50 
	}
	
	;Set process priority
	Process priority, %GamePID%, %ProcessPriority%
	
	; Set window maximized
	if MaximizedWindowed = 1
	{
		SetTimer MaximizedWindowedDelay, %MaximizedWindowedDelaySeconds%
	}
	
	if TerminateFrontendDelaySeconds =
	{
		;do nothing
	}
	else if TerminateFrontendDelaySeconds = 0
	{
		;do nothing
	}
	else
	{
		TerminateFrontendDelaySeconds := TerminateFrontendDelaySeconds * 1000
		SetTimer TerminateScript, %TerminateFrontendDelaySeconds%
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
	
	WinGet Style, Style, ahk_pid %GamePID% ; retrieve window data
	if (Style & 0xC00000) ; check if object is available
		WinSet Style, -0xC00000, ahk_pid %GamePID% ; hide title bar
	if (Style & 0x800000) ; check if object is available
		WinSet Style, -0x800000, ahk_pid %GamePID% ; hide thin-line border
	if (Style & 0x400000) ; check if object is available
		WinSet Style, -0x400000, ahk_pid %GamePID% ; hide dialog frame
	if (Style & 0x40000) ; check if object is available
		WinSet Style, -0x40000, ahk_pid %GamePID% ; hide thickframe/sizebox
	
	
	;WinGetPos WinPosX, WinPosY, WindowWidth, WindowHeight, ahk_pid %GamePID% ; Retrieve window information
	;if (WindowHeight != A_ScreenHeight) ; Make sure that the window height is not already equal screen size
	;{
	;	if DebugMode = 1
	;		Tooltip Window height is not equal screen
		WinMove ahk_pid %GamePID%, , 0, 0, DisplayWidth, DisplayHeight
	;}
	;else
	;{
	;	if DebugMode = 1
	;		Tooltip Window height is equal screen
	;}
	
	Count := Count + 1 ;Count number of loops (retries)
	if Count >= %MaximizedWindowedRetry%
	{
		SetTimer MaximizedWindowedDelay, off
	}
return

; Quit app
QuitApp:
	SystemCursor("On")
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
	}

	if HideMouseCursor = 1 ; Hide cursor if this option is enabled
	{
		IfWinActive ahk_pid %GamePID%
		{
			SystemCursor("Off")
		}
		else
		{
			SystemCursor("On")
		}
	}
	return

	#Persistent
		OnExit, ShowCursor  ; Ensure the cursor is made visible when the script exits.
return

ShowCursor:
	SystemCursor("On")
ExitApp

; Terminate timer

TerminateScript:
	GoSub QuitApp
return

; FUNCTIONS AND SUBS

DetectGamePath:
	; Get game filename and remove the Script name in the beginning
	TextToRemove = AHKGameFrontend_
	StringReplace GameFile, A_ScriptName, %TextToRemove%, , All)
	; Remove .ahk if the script isnt compiled yet
	if A_IsCompiled= 
	{
		StringReplace GameFile, GameFile, .ahk, .exe, All)
	}

	if Path = ;if the path isnt specified then get the script path
	{
		; Get game path & file name
		GamePath = %A_ScriptDir%\%GameFile%
	}
	else ; the path is specified in the ini
	{
		SplitPath Path,, dir
		GamePath = %dir%\%GameFile%
	}
	
	if A_IsCompiled= ;Remove .ahk
	{
		StringReplace GamePath, GamePath, .ahk, .exe, All)
	}
return
	
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

SystemCursor(OnOff=1)   ; INIT = "I","Init"; OFF = 0,"Off"; TOGGLE = -1,"T","Toggle"; ON = others
{
    static AndMask, XorMask, $, h_cursor
        ,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13 ; system cursors
        , b1,b2,b3,b4,b5,b6,b7,b8,b9,b10,b11,b12,b13   ; blank cursors
        , h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13   ; handles of default cursors
    if (OnOff = "Init" or OnOff = "I" or $ = "")       ; init when requested or at first call
    {
        $ = h                                          ; active default cursors
        VarSetCapacity( h_cursor,4444, 1 )
        VarSetCapacity( AndMask, 32*4, 0xFF )
        VarSetCapacity( XorMask, 32*4, 0 )
        system_cursors = 32512,32513,32514,32515,32516,32642,32643,32644,32645,32646,32648,32649,32650
        StringSplit c, system_cursors, `,
        Loop %c0%
        {
            h_cursor   := DllCall( "LoadCursor", "uint",0, "uint",c%A_Index% )
            h%A_Index% := DllCall( "CopyImage",  "uint",h_cursor, "uint",2, "int",0, "int",0, "uint",0 )
            b%A_Index% := DllCall("CreateCursor","uint",0, "int",0, "int",0
                , "int",32, "int",32, "uint",&AndMask, "uint",&XorMask )
        }
    }
    if (OnOff = 0 or OnOff = "Off" or $ = "h" and (OnOff < 0 or OnOff = "Toggle" or OnOff = "T"))
        $ = b  ; use blank cursors
    else
        $ = h  ; use the saved cursors

    Loop %c0%
    {
        h_cursor := DllCall( "CopyImage", "uint",%$%%A_Index%, "uint",2, "int",0, "int",0, "uint",0 )
        DllCall( "SetSystemCursor", "uint",h_cursor, "uint",c%A_Index% )
    }
}