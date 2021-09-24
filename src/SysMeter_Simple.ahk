; SCRIPT DIRECTIVES =============================================================================================================

#Requires AutoHotkey v2.0-beta.1


; GLOBALS =======================================================================================================================

app := Map("name", "SysMeter", "version", "0.1", "release", "2021-09-14", "author", "jNizM", "licence", "MIT")


GuiBG      := "303030"
GuiFont    := "CCCCCC"

ProgressBG := "686868"
ProgressFG := "BEFF08"

/*
[Settings]
LocationX=
LocationY=
*/


; INITIAL =======================================================================================================================

DLC      := DriveList()
Location := LoadLocation()
GuiX     := Location["X"]
GuiY     := Location["Y"]


; GUI ===========================================================================================================================

OnMessage 0x0201, WM_LBUTTONDOWN

Main := Gui("-Caption")
Main.MarginX := 10
Main.MarginY := 10
Main.SetFont("s10 c" GuiFont, "Segoe UI")
Main.BackColor := GuiBG

Main.AddText("xm ym w100 0x200", "CPU")
TxtCPU := Main.AddText("x+0 yp w100 0x202", "1%")
Main.AddProgress("xm y+1 w200 h6 vPgrCPU Background" ProgressBG " c" ProgressFG)
Main.AddText("xm y+5 w100 0x200", "RAM")
TxtRAM := Main.AddText("x+0 yp w100 0x202", "1%")
Main.AddProgress("xm y+1 w200 h6 vPgrRAM Background" ProgressBG " c" ProgressFG)

for i, v in DLC
{
	Main.AddText("xm y+5 w100 0x200", DLC[i]["Letter"])
	Main.AddText("x+0 yp w100 0x202 vTxtDR" i, "1%")
	Main.AddProgress("xm y+1 w200 h6 vPgrDR" i " Background" ProgressBG " c" ProgressFG)
}

Main.OnEvent("Close", Gui_Close)
Main.OnEvent("Escape", Gui_Close)
if (GuiX != "") && (GuiY != "")
	Main.Show(" x" GuiX " y" GuiY)
else
	Main.Show()
SetTimer Refresh, 500


; WINDOW EVENTS =================================================================================================================

Gui_Close(*)
{
	Main.GetPos(&NewX, &NewY)
	SaveLocation(NewX, NewY, GuiX, GuiY)
	ExitApp
}


WM_LBUTTONDOWN(wParam, lParam, msg, hwnd)
{
	static WM_NCLBUTTONDOWN := 0x00A1
	static HTCAPTION := 2

	if (hWnd = Main.Hwnd)
		PostMessage WM_NCLBUTTONDOWN, HTCAPTION,,, "A"
}


Refresh()
{
	CPU := CPULoad()
	RAM := GlobalMemoryStatusEx()
	DL  := DriveList()
	if (DLC.Count != DL.Count)
		Reload

	TxtCPU.Text := CPU "%"
	Main["PgrCPU"].Value := CPU
	TxtRAM.Text := RAM "%"
	Main["PgrRAM"].Value := RAM

	for i, v in DL
	{
		Main["TxtDR" i].Text  := DL[i]["Perc"] "%"
		Main["PgrDR" i].Value := DL[i]["Perc"]
	}
}


; FUNCTIONS =====================================================================================================================

CPULoad() ; thx to SKAN
{
	static PIT := 0, PKT := 0, PUT := 0

	DllCall("kernel32\GetSystemTimes", "int64*", &CIT := 0, "int64*", &CKT := 0, "int64*", &CUT := 0)
	IdleTime := PIT - CIT, KernelTime := PKT - CKT, UserTime := PUT - CUT
	SystemTime := KernelTime + UserTime

	PIT := CIT, PKT := CKT, PUT := CUT
	return ((SystemTime - IdleTime) * 100) // SystemTime
}


DriveList()
{
	DRIVES := Map()
	for v in StrSplit(DriveGetList())
	{
		DriveLetter := v ":"
		DriveType   := DriveGetType(DriveLetter)
		if (DriveType != "Fixed") && (DriveType != "Removable")
			continue
		try {
			DRIVE := Map()
			DRIVE["Letter"] := DriveLetter
			DriveCapacity   := DriveGetCapacity(DriveLetter)
			DriveFreeSpace  := DriveGetSpaceFree(DriveLetter)
			DRIVE["Cap"]    := Round(DriveCapacity / 1024, 2) " GB"
			DRIVE["Free"]   := Round(DriveFreeSpace / 1024, 2) " GB"
			DRIVE["Used"]   := Round((DriveCapacity - DriveFreeSpace) / 1024, 2) " GB"
			DRIVE["Perc"]   := Round((1 - DriveFreeSpace / DriveCapacity) * 100, 0)
		} catch {
			continue	; skip full encrypted drives (bitlocker / veracrypt / ...)
		}
		DRIVES[A_Index] := DRIVE
	}
	return DRIVES
}


GlobalMemoryStatusEx()
{
	MEMORYSTATUSEX := Buffer(64, 0)
	NumPut("uint", 64, MEMORYSTATUSEX)
	if (DllCall("kernel32\GlobalMemoryStatusEx", "ptr", MEMORYSTATUSEX))
		return NumGet(MEMORYSTATUSEX, 4, "uint")
		;return Round(100 - NumGet(MEMORYSTATUSEX, 16, "uint64") / NumGet(MEMORYSTATUSEX, 8, "uint64") * 100, 2)
	return false
}


SaveLocation(NewX, NewY, OldX, OldY)
{
	if (A_IsCompiled)
		return

	if (NewX != OldX)
		IniWrite NewX, A_ScriptFullPath, "Settings", "LocationX"
	if (NewY != OldY)
		IniWrite NewY, A_ScriptFullPath, "Settings", "LocationY"
}


LoadLocation()
{
	if (A_IsCompiled)
		return MapX("X", "", "Y", "")

	X := IniRead(A_ScriptFullPath, "Settings", "LocationX", "")
	Y := IniRead(A_ScriptFullPath, "Settings", "LocationY", "")
	return MapX("X", X, "Y", Y)
}


class MapX extends Map {
	CaseSense := "Off"
	Default   := ""
}

; ===============================================================================================================================
