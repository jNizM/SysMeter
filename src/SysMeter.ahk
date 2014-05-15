; ===================================================================================
; AHK Version ...: AHK_L 1.1.15.00 x64 Unicode
; Win Version ...: Windows 7 Professional x64 SP1
; Description ...: Shows Info about Total, Free, Used Memory in MB;
;                  Total Memory in Percentage & Clear unused Memory Function
; Version .......: v0.5
; Modified ......: 2014.05.14-1908
; Author ........: jNizM
; ===================================================================================
;@Ahk2Exe-SetName SysMeter
;@Ahk2Exe-SetDescription SysMeter
;@Ahk2Exe-SetVersion v0.5
;@Ahk2Exe-SetCopyright Copyright (c) 2013-2014`, jNizM
;@Ahk2Exe-SetOrigFilename SysMeter.ahk
; ===================================================================================

; GLOBAL SETTINGS ===================================================================

;#Warn
#NoEnv
#SingleInstance Force
SetBatchLines -1

global name      := "sysmeter"            ; gui name
global version   := "v0.5"                ; version number
global inifile   := "sysmeter.ini"        ; filename of .ini
global showPerc  := 1                     ; toggle between % and GB (0 = GB  | 1 = % )
global aot       := 0                     ; toggle alwaysontop (0 = Off | 1 = On)
global cgbg      := "464646"              ; gui background color
global cpcpu     := "13a7c7"              ; progressbar color cpu
global cpmem     := "13a7c7"              ; progressbar color ram & swp
global cphdd     := "13a7c7"              ; progressbar color hdd
global cpbg      := "686868"              ; progressbar background color

; LOAD INI SETTINGS =================================================================

if FileExist(inifile)
{
    IniRead, winx, % inifile, settings, winPosX
    IniRead, winy, % inifile, settings, winPosY
    IniRead, showPerc, % inifile, settings, showPerc
    IniRead, aot, % inifile, settings, alwaysOnTop
    IniRead, tran, % inifile, settings, transparency
    IniRead, cgbg, % inifile, colors, color_guibg
    IniRead, cpcpu, % inifile, colors, color_pgbar_cpu
    IniRead, cpmem, % inifile, colors, color_pgbar_mem
    IniRead, cphdd, % inifile, colors, color_pgbar_hdd
    IniRead, cpbg, % inifile, colors, color_pgbg
}

; MENU ==============================================================================

Menu, Tray, DeleteAll
Menu, Tray, NoStandard
Menu, Tray, Add, Save Settings, Menu_SaveSettings
Menu, Tray, Add,
Menu, Menu_color, Add, Blue, Menu_Color_Blue
Menu, Menu_color, Add, Lime, Menu_Color_Lime
Menu, Menu_color, Add, Red, Menu_Color_Red
Menu, Menu_color, Add, Purple, Menu_Color_Purple
Menu, Menu_color, Add, Mix, Menu_Color_Mix
Menu, Tray, Add, Color Scheme, :Menu_Color
Menu, Tray, Add,
Menu, Tray, Add, Toggle Percentage, Menu_Percentage
Menu, Tray, % ((showPerc = "1") ? "Check" : "Uncheck"), Toggle Percentage
Menu, Tray, Add,
Menu, Tray, Add, Reset Transparency, Menu_Transparency
Menu, Tray, Add, Toggle AlwaysOnTop, Menu_AlwaysOnTop
Menu, Tray, % ((aot = "1") ? "Check" : "Uncheck"), Toggle AlwaysOnTop
Menu, Tray, Add, Show/Hide, Menu_ShowHide
Menu, Tray, Add,
Menu, Tray, Add, Exit, Close
Menu, Tray, Default, Show/Hide

; GUI MAIN ==========================================================================

Create_Gui:
Gui +LastFound -Caption +ToolWindow +hwndhMain
Gui, Margin, 10, 10
Gui, Color, % cgbg
Gui, Font, s10 cFFFFFF bold, Agency FB
Gui, Add, Text, xm ym w50 0x200, % "CPU"
Gui, Add, Text, x+5 yp w145 0x202 vTCPU,
Gui, Add, Progress, xm y+2 w200 h6 c%cpcpu% Background%cpbg% vPCPU,
Gui, Add, Text, xm y+7 w50 0x200, % "RAM"
Gui, Add, Text, x+5 yp w145 0x202 vTRAM,
Gui, Add, Progress, xm y+2 w200 h6 c%cpmem% Background%cpbg% vPRAM,
Gui, Add, Text, xm y+7 w50 0x200, % "SWAP"
Gui, Add, Text, x+5 yp w145 0x202 vTSWP,
Gui, Add, Progress, xm y+2 w200 h6 c%cpmem% Background%cpbg% vPSWP,
DriveGet, DrvLstFxd, List, FIXED
loop, Parse, DrvLstFxd
{
    Gui, Add, Text, xm y+7 w50 0x200, %A_Loopfield%:\
    Gui, Add, Text, x+5 yp w145 0x202 vP%A_Loopfield%RV,
    Gui, Add, Progress, xm y+2 w200 h6 c%cphdd% Background%cpbg% vT%A_Loopfield%RV,
}
Gui, Show, % ((winX != "") ? winX : "") ((winY != "") ? winY : "") AutoSize, % name
WinSet, Transparent, % ((tran != "") ? tran : 200), % name
WinSet, AlwaysOnTop, % ((aot = "1") ? "On" : "Off"), % name 
OnMessage(0x201, "WM_LBUTTONDOWN")
SetTimer, Update, 1000
return

; SCRIPT ============================================================================

Update:
    CPU := CPULoad()
    GuiControl,, TCPU, % CPU " %"
    GuiControl,, PCPU, % CPU
    
    GMSEx := GlobalMemoryStatusEx()
    GMSExM01 := GMSEx[1]                                   ; MemoryLoad in %
    GMSExM02 := Round(GMSEx[2] / 1024**3, 2)               ; Total Physical Memory in MB
    GMSExM03 := Round(GMSEx[3] / 1024**3, 2)               ; Available Physical Memory in MB
    GMSExM04 := Round(GMSExM02 - GMSExM03, 2)              ; Used Physical Memory in MB
    GMSExM05 := Round(GMSExM04 / GMSExM02 * 100, 2)        ; Used Physical Memory in %
    GMSExS01 := Round(GMSEx[4] / 1024**3, 2)               ; Total PageFile in MB
    GMSExS02 := Round(GMSEx[5] / 1024**3, 2)               ; Available PageFile in MB
    GMSExS03 := Round(GMSExS01 - GMSExS02, 2)              ; Used PageFile in MB
    GMSExS04 := Round(GMSExS03 / GMSExS01 * 100, 2)        ; Used PageFile in %
    GuiControl,, TRAM, % ((showPerc = "1") ? GMSExM05 " %" : GMSExM04 "/" GMSExM02 " GB")
    GuiControl,, PRAM, % GMSExM05
    GuiControl,, TSWP, % ((showPerc = "1") ? GMSExS04 " %" : GMSExS03 "/" GMSExS01 " GB")
    GuiControl,, PSWP, % GMSExS04
    
    loop, Parse, DrvLstFxd
    {
        i := A_LoopField
        DriveGet, cap%i%, Capacity, %i%:\
        DriveSpaceFree, free%i%, %i%:\
        used%i% := cap%i% - free%i%
        perc%i% := used%i% / cap%i% * 100
        GuiControl,, P%i%RV, % ((showPerc = "1") ? round(perc%i%, 2) " %" : round((used%i% / 1024), 2) "/" round((cap%i% / 1024), 2) " GB")
        GuiControl,, T%i%RV, % perc%i%
    }
return

Menu_SaveSettings:
    IniSettings(showPerc, cgbg, cpcpu, cpmem, cphdd, cpbg)
return

Menu_Color_Blue:
    cgbg  := "464646"
    cpcpu := "13a7c7"
    cpmem := "13a7c7"
    cphdd := "13a7c7"
    cpbg  := "686868"
    Gui, Destroy
    gosub Create_Gui
return

Menu_Color_Lime:
    cgbg  := "464646"
    cpcpu := "b7fe36"
    cpmem := "b7fe36"
    cphdd := "b7fe36"
    cpbg  := "686868"
    Gui, Destroy
    gosub Create_Gui
return

Menu_Color_Red:
    cgbg  := "464646"
    cpcpu := "ff4444"
    cpmem := "ff4444"
    cphdd := "ff4444"
    cpbg  := "686868"
    Gui, Destroy
    gosub Create_Gui
return

Menu_Color_Purple:
    cgbg  := "464646"
    cpcpu := "aa66cc"
    cpmem := "aa66cc"
    cphdd := "aa66cc"
    cpbg  := "686868"
    Gui, Destroy
    gosub Create_Gui
return

Menu_Color_Mix:
    cgbg  := "464646"
    cpcpu := "32cd32"
    cpmem := "ff8c00"
    cphdd := "1e90ff"
    cpbg  := "686868"
    Gui, Destroy
    gosub Create_Gui
return

Menu_Percentage:
    showPerc := (showPerc = "0") ? "1" : "0"
    Menu, Tray, ToggleCheck, Toggle Percentage
return

Menu_Transparency:
    WinSet, Transparent, 200, % name
return

Menu_AlwaysOnTop:
    ToggleAlwaysOnTop()
return

Menu_ShowHide:
    ToggleShowHide()
return

^WheelUp::GUITrans(1)
^WheelDown::GUITrans(0)

; FUNCTIONS =========================================================================

WM_LBUTTONDOWN(wParam, lParam, msg, hwnd) ; WM_LBUTTONDOWN() by an AHK-Member
{
    global hMain
    if (hwnd = hMain)
    {
        PostMessage, 0xA1, 2,,, % name
    }
}

GUITrans(b := 1) ; GUITrans() by jNizM
{
    WinGet, ct, Transparent, % name
    WinSet, Transparent, % ((b = 1) ? ct + 1 : ct - 1), % name
}

ToggleAlwaysOnTop() ; ToggleAlwaysOnTop() by jNizM
{
    WinGet, WS_EX_TOPMOST, ExStyle, % name
    if (WS_EX_TOPMOST & 0x8)
    {
        WinSet, AlwaysOnTop, Off, % name
        Menu, Tray, Uncheck, Toggle AlwaysOnTop
        aot := 0
    }
    else
    {
        WinSet, AlwaysOnTop, On, % name
        Menu, Tray, Check, Toggle AlwaysOnTop
        aot := 1
    }
}

ToggleShowHide()
{
    WinGet, WS_VISIBLE, Style, % name
    if (WS_VISIBLE & 0x10000000)
    {
        WinHide, % name
    }
    else
    {
        WinShow, % name
        WinSet, AlwaysOnTop, Toggle, % name
        WinSet, AlwaysOnTop, Toggle, % name
    }
}

IniSettings(showPerc, cgbg, cpcpu, cpmem, cphdd, cpbg) ; IniSettings() by jNizM
{
    WinGetPos, winX, winY,,, % name
    IniWrite, % "X" winX, % inifile, settings, winPosX
    IniWrite, % "Y" winY, % inifile, settings, winPosY
    IniWrite, % showPerc, % inifile, settings, showPerc
    WinGet, ct, Transparent, % name
    IniWrite, % ct, % inifile, settings, transparency
    IniWrite, % aot, % inifile, settings, alwaysontop

    IniWrite, % cgbg,  % inifile, colors, color_guibg
    IniWrite, % cpcpu, % inifile, colors, color_pgbar_cpu
    IniWrite, % cpmem, % inifile, colors, color_pgbar_mem
    IniWrite, % cphdd, % inifile, colors, color_pgbar_hdd
    IniWrite, % cpbg,  % inifile, colors, color_pgbg
}

CPULoad() ; CPULoad() by SKAN
{
    static PIT, PKT, PUT
    if (Pit = "")
    {
        return 0, DllCall("GetSystemTimes", "Int64P", PIT, "Int64P", PKT, "Int64P", PUT)
    }
    DllCall("GetSystemTimes", "Int64P", CIT, "Int64P", CKT, "Int64P", CUT)
    IdleTime := PIT - CIT, KernelTime := PKT - CKT, UserTime := PUT - CUT
    SystemTime := KernelTime + UserTime 
    return ((SystemTime - IdleTime) * 100) // SystemTime, PIT := CIT, PKT := CKT, PUT := CUT 
}

GlobalMemoryStatusEx() ; GlobalMemoryStatusEx() by jNizM
{
    static MSEX, init := VarSetCapacity(MSEX, 64, 0) && NumPut(64, MSEX, "UInt")
    if (DllCall("GlobalMemoryStatusEx", "Ptr", &MSEX))
    {
        return { 1 : NumGet(MSEX,  4, "UInt")
               , 2 : NumGet(MSEX,  8, "UInt64"), 3 : NumGet(MSEX, 16, "UInt64")
               , 4 : NumGet(MSEX, 24, "UInt64"), 5 : NumGet(MSEX, 32, "UInt64") }
    }
}

; EXIT ==============================================================================

Close:
GuiClose:
GuiEscape:
    ExitApp