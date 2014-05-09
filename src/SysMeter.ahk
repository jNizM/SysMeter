; ===================================================================================
; AHK Version ...: AHK_L 1.1.15.00 x64 Unicode
; Win Version ...: Windows 7 Professional x64 SP1
; Description ...: Shows Info about Total, Free, Used Memory in MB;
;                  Total Memory in Percentage & Clear unused Memory Function
; Version .......: v0.1
; Modified ......: 2014.05.08-2027
; Author ........: jNizM
; ===================================================================================
;@Ahk2Exe-SetName SysMeter
;@Ahk2Exe-SetDescription SysMeter
;@Ahk2Exe-SetVersion v0.1
;@Ahk2Exe-SetCopyright Copyright (c) 2013-2014`, jNizM
;@Ahk2Exe-SetOrigFilename SysMeter.ahk
; ===================================================================================

; GLOBAL SETTINGS ===================================================================

;#Warn
#NoEnv
#SingleInstance Force
SetBatchLines -1

global name      := "sysmeter"
global version   := "v0.1"
global varPerc   := 0

; MENU ==============================================================================

Menu, Tray, DeleteAll
Menu, Tray, NoStandard
Menu, Tray, Add, Toggle Percentage, Menu_Percentage
Menu, Tray, Add,
Menu, Tray, Add, Toggle Transparency, Menu_Transparency
Menu, Tray, Add, Toggle AlwaysOnTop, Menu_AlwaysOnTop
Menu, Tray, Add, Show/Hide, Menu_ShowHide
Menu, Tray, Add,
Menu, Tray, Add, Exit, Close
Menu, Tray, Default, Show/Hide
Menu, Tray, ToggleCheck, Toggle Transparency

; GUI MAIN ==========================================================================

Gui +LastFound -Caption +ToolWindow +hwndhMain
Gui, Margin, 10, 10
Gui, Color, 464646
Gui, Font, s10 cFFFFFF bold, Agency FB
Gui, Add, Text, xm ym w75 0x200, % "CPU Usage:"
Gui, Add, Text, x+5 yp w120 0x202 vTCPU,
Gui, Add, Progress, xm y+2 w200 h6 c13a7c7 Background686868 vPCPU,
Gui, Add, Text, xm y+7 w75 0x200, % "RAM Usage:"
Gui, Add, Text, x+5 yp w120 0x202 vTRAM,
Gui, Add, Progress, xm y+2 w200 h6 c13a7c7 Background686868 vPRAM,
Gui, Add, Text, xm y+7 w75 0x200, % "SWAP Usage:"
Gui, Add, Text, x+5 yp w120 0x202 vTSWP,
Gui, Add, Progress, xm y+2 w200 h6 c13a7c7 Background686868 vPSWP,
DriveGet, DrvLstFxd, List, FIXED
loop, Parse, DrvLstFxd
{
    Gui, Add, Text, xm y+7 w75 0x200, %A_Loopfield%:\
    Gui, Add, Text, x+5 yp w120 0x202 vP%A_Loopfield%RV,
    Gui, Add, Progress, xm y+2 w200 h6 c13a7c7 Background686868 vT%A_Loopfield%RV,
}
Gui, Show, AutoSize, % name
WinSet, Transparent, 150, % name
OnMessage(0x201, "WM_LBUTTONDOWN")
SetTimer, Update, 2000
return

; SCRIPT ============================================================================

Update:
    CPU := CPULoad()
    GuiControl,, TCPU, % CPU " %"
    GuiControl,, PCPU, % CPU
    
    GMSEx := GlobalMemoryStatusEx()
    GMSExM01 := GMSEx[1]                                   ; MemoryLoad in %
    GMSExM02 := Round(GMSEx[2] / 1024**2, 2)               ; Total Physical Memory in MB
    GMSExM03 := Round(GMSEx[3] / 1024**2, 2)               ; Available Physical Memory in MB
    GMSExM04 := Round(GMSExM02 - GMSExM03, 2)              ; Used Physical Memory in MB
    GMSExM05 := Round(GMSExM04 / GMSExM02 * 100, 2)        ; Used Physical Memory in %
    GMSExS01 := Round(GMSEx[4] / 1024**2, 2)               ; Total PageFile in MB
    GMSExS02 := Round(GMSEx[5] / 1024**2, 2)               ; Available PageFile in MB
    GMSExS03 := Round(GMSExS01 - GMSExS02, 2)              ; Used PageFile in MB
    GMSExS04 := Round(GMSExS03 / GMSExS01 * 100, 2)        ; Used PageFile in %
    GuiControl,, TRAM, % (varPerc = "1") ? GMSExM05 " %" : GMSExM04 "/" GMSExM02 " MB"
    GuiControl,, PRAM, % GMSExM01
    GuiControl,, TSWP, % (varPerc = "1") ? GMSExS04 " %" : GMSExS03 "/" GMSExS01 " MB"
    GuiControl,, PSWP, % GMSExS04
    
    loop, Parse, DrvLstFxd
    {
        i := A_LoopField
        DriveGet, cap%i%, Capacity, %i%:\
        DriveSpaceFree, free%i%, %i%:\
        used%i% := cap%i% - free%i%
        perc%i% := used%i% / cap%i% * 100
        GuiControl,, P%i%RV, % (varPerc = "1") ? round(perc%i%, 2) " %" : round((used%i% / 1024), 2) "/" round((cap%i% / 1024), 2) " GB"
        GuiControl,, T%i%RV, % perc%i%
    }
return

Menu_Percentage:
    varPerc := (varPerc = "0") ? "1" : "0"
    Menu, Tray, ToggleCheck, Toggle Percentage
return

Menu_Transparency:
    WinGet, ct, Transparent, % name
    WinSet, Transparent, % ct = "150" ? "Off" : "150", % name
    Menu, Tray, ToggleCheck, Toggle Transparency
return

Menu_AlwaysOnTop:
    WinSet, AlwaysOnTop, Toggle, % name
    Menu, Tray, ToggleCheck, Toggle AlwaysOnTop
return

Menu_ShowHide:
    WinGet, winStyle, Style, % name
    if (winStyle & 0x10000000)
    {
        WinHide, % name
    }
    else
    {
        WinShow, % name
        WinSet, AlwaysOnTop, Toggle, % name
        WinSet, AlwaysOnTop, Toggle, % name
    }
return

; FUNCTIONS =========================================================================

WM_LBUTTONDOWN(wParam, lParam, msg, hwnd)
{
    global hMain
    if (hwnd = hMain)
    {
        PostMessage, 0xA1, 2,,, % name
    }
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
    if (DllCall("Kernel32.dll\GlobalMemoryStatusEx", "Ptr", &MSEX))
    {
        return { 1 : NumGet(MSEX,  4, "UInt")
               , 2 : NumGet(MSEX,  8, "UInt64"), 3 : NumGet(MSEX, 16, "UInt64")
               , 4 : NumGet(MSEX, 24, "UInt64"), 5 : NumGet(MSEX, 32, "UInt64") }
    }
}

; FUNCTIONS =========================================================================

Close:
GuiClose:
GuiEscape:
    ExitApp