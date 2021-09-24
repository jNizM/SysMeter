; SCRIPT DIRECTIVES =============================================================================================================

#Requires AutoHotkey v2.0-beta.1
#DllLoad "gdiplus.dll"


; GLOBALS =======================================================================================================================

app := Map("name", "SysMeter", "version", "0.5", "release", "2021-09-14", "author", "jNizM", "licence", "MIT")

GuiBG     := 0xFF303030

CircleBG  := 0x33DDDDDD
CircleFG  := 0xFFBEFF08

PieBG     := 0x33DDDDDD
PieFG     := 0xFFBEFF08

FontDark  := 0xC0E7E7E7
FontLight := 0xFFBEFF08

Animation := false

/*
[Settings]
LocationX=
LocationY=
*/

; INITIAL =======================================================================================================================

GDIPToken := GdiplusStartup()


DLC  := DriveList().Count
GuiWidth    :=  30 + (120 *   2) + 5 + 10 + 30
GuiHeight   := 200 + (120 * DLC) + 5 + 10 + 30
Location    := LoadLocation()
GuiX        := Location["X"]
GuiY        := Location["Y"]


; GUI ===========================================================================================================================

OnMessage 0x0201, WM_LBUTTONDOWN

Main := Gui("-Caption")
Main.MarginX := 0
Main.MarginY := 0
Main.SetFont("s10", "Segoe UI")

Main.OnEvent("Close", Gui_Close)
Main.OnEvent("Escape", Gui_Close)
if (GuiX != "") && (GuiY != "")
	Main.Show("w" GuiWidth " h" GuiHeight " x" GuiX " y" GuiY)
else
	Main.Show("w" GuiWidth " h" GuiHeight)


hGraphics     := GdipCreateFromHWND(Main.hWnd)
hBitmap       := GdipCreateBitmapFromGraphics(hGraphics, GuiWidth, GuiHeight)
hGraphicsCtxt := GdipGetImageGraphicsContext(hBitmap)

hCircleBG     := GdipCreatePen1(CircleBG, 5, 2)
hCircleFG     := GdipCreatePen1(CircleFG, 5, 2)

hPieBG        := GdipCreateSolidFill(PieBG)
hPieFG        := GdipCreateSolidFill(PieFG)

hFontDark     := GdipCreateSolidFill(FontDark)
hFontLight    := GdipCreateSolidFill(FontLight)

hFormatC      := GdipCreateStringFormat(0)
hFormatL      := GdipCreateStringFormat(0)
hFamily       := GdipCreateFontFamilyFromName("Tahoma")
hFontB        := GdipCreateFont(hFamily, 12, 0)
hFontM        := GdipCreateFont(hFamily, 11, 0)
hFontS        := GdipCreateFont(hFamily,  7, 0)

rCPU          := GdipCreateRectF( 30, 120, 120, 20)
rCPU_Usage    := GdipCreateRectF( 30,  84, 120, 20)
rRAM          := GdipCreateRectF(165, 120, 120, 20)
rRAM_Usage    := GdipCreateRectF(165,  84, 120, 20)


GdipSetStringFormatAlign(hFormatC, 1)
GdipSetStringFormatAlign(hFormatL, 0)
GdipSetSmoothingMode(hGraphics, 2)
GdipSetSmoothingMode(hGraphicsCtxt, 2)


if (Animation)
{
	DllCall("winmm\timeBeginPeriod", "uint", 3)
	loop 200
	{
		Init := (A_Index <= 100) ? (0 + A_Index) : (200 - A_Index)
		GdipGraphicsClear(hGraphicsCtxt, GuiBG)
		
		GdipDrawArc(hGraphicsCtxt, hCircleBG, 30, 30, 120, 120,  0, 360)
		GdipDrawArc(hGraphicsCtxt, hCircleFG, 30, 30, 120, 120, 90, 360 / 100 * Init)
		GdipDrawString(hGraphicsCtxt, "CPU", hFontB, rCPU, hFormatC, hFontLight)
		GdipDrawString(hGraphicsCtxt, Init "%", hFontM, rCPU_Usage, hFormatC, hFontDark)

		GdipDrawArc(hGraphicsCtxt, hCircleBG, 165, 30, 120, 120,  0, 360)
		GdipDrawArc(hGraphicsCtxt, hCircleFG, 165, 30, 120, 120, 90, 360 / 100 * Init)
		GdipDrawString(hGraphicsCtxt, "RAM", hFontB, rRAM, hFormatC, hFontLight)
		GdipDrawString(hGraphicsCtxt, Init "%", hFontM, rRAM_Usage, hFormatC, hFontDark)

		loop DLC
		{
			offset := 200 + ((A_Index - 1) * 135)
			GdipFillPie(hGraphicsCtxt, hPieBG, 30, offset, 120, 120,  0, 360)
			GdipFillPie(hGraphicsCtxt, hPieFG, 30, offset, 120, 120, 90, 360 / 100 * Init)
		}

		GdipDrawImage(hGraphics, hBitmap, 0, 0)
		DllCall("kernel32\Sleep", "uint", 1)
	}
	DllCall("winmm\timeEndPeriod", "uint", 3)
}


loop
{
	CPU := CPULoad()
	RAM := GlobalMemoryStatusEx()
	DL  := DriveList()
	if (DLC != DL.Count)
		Reload

	GdipGraphicsClear(hGraphicsCtxt, GuiBG)

	GdipDrawArc(hGraphicsCtxt, hCircleBG, 30, 30, 120, 120,  0, 360)
	GdipDrawArc(hGraphicsCtxt, hCircleFG, 30, 30, 120, 120, 90, 360 / 100 * CPU)
	GdipDrawString(hGraphicsCtxt, "CPU", hFontB, rCPU, hFormatC, hFontLight)
	GdipDrawString(hGraphicsCtxt, CPU "%", hFontM, rCPU_Usage, hFormatC, hFontDark)

	GdipDrawArc(hGraphicsCtxt, hCircleBG, 165, 30, 120, 120,  0, 360)
	GdipDrawArc(hGraphicsCtxt, hCircleFG, 165, 30, 120, 120, 90, 360 / 100 * RAM)
	GdipDrawString(hGraphicsCtxt, "RAM", hFontB, rRAM, hFormatC, hFontLight)
	GdipDrawString(hGraphicsCtxt, RAM "%", hFontM, rRAM_Usage, hFormatC, hFontDark)

	for i, v in DL
	{
		offset := 200 + ((A_Index - 1) * 135)
		GdipFillPie(hGraphicsCtxt, hPieBG, 30, offset, 120, 120,  0, 360)
		GdipFillPie(hGraphicsCtxt, hPieFG, 30, offset, 120, 120, 90, 360 / 100 * DL[i]["Perc"])

		rLetter := GdipCreateRectF(157, offset + 20, 80, 20)
		GdipDrawString(hGraphicsCtxt, DL[i]["Letter"], hFontM, rLetter, hFormatL, hFontLight)

		GdipFillRectangle(hGraphicsCtxt, hPieFG, 160, offset + 45, 6, 6)
		rUsed := GdipCreateRectF(170, offset + 43, 80, 10)
		GdipDrawString(hGraphicsCtxt, "Used: " DL[i]["Used"], hFontS, rUsed, hFormatL, hFontDark)

		GdipFillRectangle(hGraphicsCtxt, hPieBG, 160, offset + 65, 6, 6)
		rFree := GdipCreateRectF(170, offset + 63, 80, 10)
		GdipDrawString(hGraphicsCtxt, "Free: " DL[i]["Free"], hFontS, rFree, hFormatL, hFontDark)
	}

	GdipDrawImage(hGraphics, hBitmap, 0, 0)
	sleep 500
}


; WINDOW EVENTS =================================================================================================================

Gui_Close(*)
{
	Main.GetPos(&NewX, &NewY)
	SaveLocation(NewX, NewY, GuiX, GuiY)

	GdipDeleteFont(hFontB)
	GdipDeleteFont(hFontM)
	GdipDeleteFont(hFontS)

	GdipDeleteBrush(hPieBG)
	GdipDeleteBrush(hPieFG)
	GdipDeleteBrush(hFontDark)
	GdipDeleteBrush(hFontLight)

	GdipDeletePen(hCircleBG)
	GdipDeletePen(hCircleFG)

	GdipDeleteFontFamily(hFamily)
	GdipDeleteStringFormat(hFormatC)
	GdipDeleteStringFormat(hFormatL)

	GdipDeleteGraphics(hGraphicsCtxt)
	GdipDisposeImage(hBitmap)
	GdipDeleteGraphics(hGraphics)
	GdiplusShutdown(GDIPToken)
	ExitApp
}


WM_LBUTTONDOWN(wParam, lParam, msg, hwnd)
{
	static WM_NCLBUTTONDOWN := 0x00A1
	static HTCAPTION := 2

	if (hWnd = Main.Hwnd)
		PostMessage WM_NCLBUTTONDOWN, HTCAPTION,,, "A"
}


; GDI+ ==========================================================================================================================

GdiplusStartup()
{
	GDIPSTARTUPINPUT := Buffer(24, 0)
	NumPut("uint", 1, GDIPSTARTUPINPUT)
	if (STATUS := DllCall("gdiplus\GdiplusStartup", "uptr*", &GDIPToken := 0, "ptr", GDIPSTARTUPINPUT, "ptr", 0, "uint"))
	{
		MsgBox("GDI+ could not be startet!`n`nThe program will exit!", STATUS)
		ExitApp
	}
	return GDIPToken
}


GdiplusShutdown(GDIPToken)
{
	if (GDIPToken)
		DllCall("gdiplus\GdiplusShutdown", "uptr", GDIPToken)
	return
}


GdipCreateBitmapFromGraphics(hGraphics, Width, Height)
{
	if !(DllCall("gdiplus\GdipCreateBitmapFromGraphics", "int",  Width
	                                                   , "int",  Height
	                                                   , "ptr",  hGraphics
	                                                   , "ptr*", &hBitmap := 0))
		return hBitmap
	throw Error("GdipCreateBitmapFromGraphics failed", -1)
}


GdipCreateFont(hFamily, Size, Style := 0, Unit := 3)
{
	if !(DllCall("gdiplus\GdipCreateFont", "ptr",   hFamily
	                                     , "float", Size
	                                     , "int",   Style
	                                     , "int",   Unit
	                                     , "ptr*",  &hFont := 0))
		return hFont
	throw Error("GdipCreateFont failed", -1)
}


GdipCreateFontFamilyFromName(Family, Collection := 0)
{
	if !(DllCall("gdiplus\GdipCreateFontFamilyFromName", "wstr", Family
	                                                   , "ptr",  Collection
	                                                   , "ptr*", &hFamily := 0))
		return hFamily
	throw Error("GdipCreateFontFamilyFromName failed", -1)
}


GdipCreateFromHWND(hWnd)
{
	if !(DllCall("gdiplus\GdipCreateFromHWND", "ptr",  hWnd
	                                         , "ptr*", &hGraphics := 0))
		return hGraphics
	throw Error("GdipCreateFromHWND failed", -1)
}


GdipCreatePen1(ARGB := 0xFF000000, Width := 1, Unit := 2)
{
	if !(DllCall("gdiplus\GdipCreatePen1", "uint",  ARGB
	                                     , "float", Width
	                                     , "int",   Unit
	                                     , "ptr*",  &hPen := 0))
		return hPen
	throw Error("GdipCreatePen1 failed", -1)
}


GdipCreateRectF(X := 0, Y := 0, Width := 0, Height := 0)
{
	RectF := Buffer(16)
	NumPut("float", X, "float", Y, "float", Width, "float", Height, RectF)
	return RectF
}


GdipCreateSolidFill(ARGB := 0xFF000000)
{
	if !(DllCall("gdiplus\GdipCreateSolidFill", "int",  ARGB
	                                          , "ptr*", &hBrush := 0))
		return hBrush
	throw Error("GdipCreateSolidFill failed", -1)
}


GdipCreateStringFormat(Format := 0, LangID := 0)
{
	if !(DllCall("gdiplus\GdipCreateStringFormat", "int",  Format
	                                             , "int",  LangID
	                                             , "ptr*", &hFormat := 0))
		return hFormat
	throw Error("GdipCreateStringFormat failed", -1)
}


GdipDeleteBrush(hBrush)
{
	if !(DllCall("gdiplus\GdipDeleteBrush", "ptr", hBrush))
		return true
	throw Error("GdipDeleteBrush failed", -1)
}


GdipDeleteFont(hFont)
{
	if !(DllCall("gdiplus\GdipDeleteFont", "ptr", hFont))
		return true
	throw Error("GdipDeleteFont failed", -1)
}


GdipDeleteFontFamily(hFamily)
{
	if !(DllCall("gdiplus\GdipDeleteFontFamily", "ptr", hFamily))
		return true
	throw Error("GdipDeleteFontFamily failed", -1)
}


GdipDeleteGraphics(hGraphics)
{
	if !(DllCall("gdiplus\GdipDeleteGraphics", "ptr", hGraphics))
		return true
	throw Error("GdipDeleteGraphics failed", -1)
}


GdipDeletePen(hPen)
{
	if !(DllCall("gdiplus\GdipDeletePen", "ptr", hPen))
		return true
	throw Error("GdipDeletePen failed", -1)
}


GdipDeleteStringFormat(hFormat)
{
	if !(DllCall("gdiplus\GdipDeleteStringFormat", "ptr", hFormat))
		return true
	throw Error("GdipDeleteStringFormat failed", -1)
}


GdipDisposeImage(hImage)
{
	if !(DllCall("gdiplus\GdipDisposeImage", "ptr", hImage))
		return true
	throw Error("GdipDisposeImage failed", -1)
}


GdipDrawArc(hGraphics, hPen, X, Y, Width, Height, StartAngle, SweepAngle)
{
	if !(DllCall("gdiplus\GdipDrawArc", "ptr",   hGraphics
	                                  , "ptr",   hPen
	                                  , "float", X
	                                  , "float", Y
	                                  , "float", Width
	                                  , "float", Height
	                                  , "float", StartAngle
	                                  , "float", SweepAngle))
		return true
	throw Error("GdipDrawArc failed", -1)
}


GdipDrawImage(hGraphics, hImage, X, Y)
{
	if !(DllCall("gdiplus\GdipDrawImage", "ptr",   hGraphics
	                                    , "ptr",   hImage
	                                    , "float", X
	                                    , "float", Y))
		return true
	throw Error("GdipDrawImage failed", -1)
}


GdipDrawLine(hGraphics, hPen, X1, Y1, X2, Y2)
{
	if !(DllCall("gdiplus\GdipDrawLine", "ptr",   hGraphics
	                                   , "ptr",   hPen
	                                   , "float", X1
	                                   , "float", Y1
	                                   , "float", X2
	                                   , "float", Y2))
		return true
	throw Error("GdipDrawLine failed", -1)
}


GdipDrawString(hGraphics, String, hFont, Layout, hFormat, hBrush)
{
	if !(DllCall("gdiplus\GdipDrawString", "ptr",  hGraphics
	                                     , "wstr", String
	                                     , "int",  -1
	                                     , "ptr",  hFont
	                                     , "ptr",  Layout
	                                     , "ptr",  hFormat
	                                     , "ptr",  hBrush))
		return true
	throw Error("GdipDrawString failed", -1)
}


GdipFillPie(hGraphics, hBrush, X, Y, Width, Height, StartAngle, SweepAngle)
{
	if !(DllCall("gdiplus\GdipFillPie", "ptr",   hGraphics
	                                  , "ptr",   hBrush
	                                  , "float", X
	                                  , "float", Y
	                                  , "float", Width
	                                  , "float", Height
	                                  , "float", StartAngle
	                                  , "float", SweepAngle))
		return true
	throw Error("GdipFillPie failed", -1)
}


GdipFillRectangle(hGraphics, hBrush, X, Y, Width, Height)
{
	if !(DllCall("gdiplus\GdipFillRectangle", "ptr",   hGraphics
	                                        , "ptr",   hBrush
	                                        , "float", X
	                                        , "float", Y
	                                        , "float", Width
	                                        , "float", Height))
		return true
	throw Error("GdipFillRectangle failed", -1)
}


GdipGetImageGraphicsContext(hImage)
{
	if !(DllCall("gdiplus\GdipGetImageGraphicsContext", "ptr",  hImage
	                                                  , "ptr*", &hGraphics := 0))
		return hGraphics
	throw Error("GdipGetImageGraphicsContext failed", -1)
}


GdipGraphicsClear(hGraphics, ARGB := 0xFF000000)
{
	if !(DllCall("gdiplus\GdipGraphicsClear", "ptr",  hGraphics
	                                        , "uint", ARGB))
		return true
	throw Error("GdipGraphicsClear failed", -1)
}


GdipSetSmoothingMode(hGraphics, SmoothingMode)
{
	if !(DllCall("gdiplus\GdipSetSmoothingMode", "ptr", hGraphics
	                                           , "int", SmoothingMode))
		return true
	throw Error("GdipSetSmoothingMode failed", -1)
}


GdipSetStringFormatAlign(hStringFormat, Flag)
{
	if !(DllCall("gdiplus\GdipSetStringFormatAlign", "ptr", hStringFormat
	                                               , "int", Flag))
		return true
	throw Error("GdipSetStringFormatAlign failed", -1)
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
