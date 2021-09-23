; SCRIPT DIRECTIVES =============================================================================================================

#Requires AutoHotkey v2.0-beta.1
#DllLoad "gdiplus.dll"


; GLOBALS =======================================================================================================================

app := Map("name", "SysMeter", "version", "0.1", "release", "2021-09-23", "author", "jNizM", "licence", "MIT")

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
LocationX=243
LocationY=379
*/

; INITIAL =======================================================================================================================

SI := Buffer(24, 0)
NumPut("uint", 1, SI)
if (DllCall("gdiplus\GdiplusStartup", "ptr*", &GdipToken := 0, "ptr", SI, "ptr", 0, "uint"))
{
	MsgBox("GDI+ could not be startet!`n`nThe program will exit!")
	ExitApp
}


DLC  := DriveList().Count
GuiWidth   :=  30 + (120 * 2) + 5 + 10 + 30
GuiHeight  := 200 + (120 * DLC) + 5 + 10 + 30
GuiLocaion := LoadLocation()


; GUI ===========================================================================================================================

Main := Gui()
Main.MarginX := 0
Main.MarginY := 0
Main.SetFont("s10", "Segoe UI")

Main.OnEvent("Close", Gui_Close)
Main.Show("w" GuiWidth " h" GuiHeight " x" GuiLocaion["X"] " y" GuiLocaion["Y"])


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
GdipSetStringFormatAlign(hFormatL, 1)
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

		for i, v in DL
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

		GdipFillRectangle(hGraphicsCtxt, hPieFG, 160, offset + 45, 6, 6)
		rUsed := GdipCreateRectF(165, offset + 43, 80, 10)
		GdipDrawString(hGraphicsCtxt, "Used: " DL[i]["Used"], hFontS, rUsed, hFormatL, hFontDark)

		GdipFillRectangle(hGraphicsCtxt, hPieBG, 160, offset + 65, 6, 6)
		rFree := GdipCreateRectF(165, offset + 63, 80, 10)
		GdipDrawString(hGraphicsCtxt, "Free: " DL[i]["Free"], hFontS, rFree, hFormatL, hFontDark)
	}

	GdipDrawImage(hGraphics, hBitmap, 0, 0)
	sleep 500
}


; WINDOW EVENTS =================================================================================================================

Gui_Close(*)
{
	Main.GetPos(&X, &Y)
	SaveLocation(X, Y)
	DllCall("gdiplus\GdipDeleteFont", "ptr", hFontB)
	DllCall("gdiplus\GdipDeleteFont", "ptr", hFontM)
	DllCall("gdiplus\GdipDeleteFont", "ptr", hFontS)

	DllCall("gdiplus\GdipDeleteBrush", "ptr", hPieBG)
	DllCall("gdiplus\GdipDeleteBrush", "ptr", hPieFG)
	DllCall("gdiplus\GdipDeleteBrush", "ptr", hFontDark)
	DllCall("gdiplus\GdipDeleteBrush", "ptr", hFontLight)

	DllCall("gdiplus\GdipDeletePen", "ptr", hCircleBG)
	DllCall("gdiplus\GdipDeletePen", "ptr", hCircleFG)

	DllCall("gdiplus\GdipDeleteFontFamily", "ptr", hFamily)
	DllCall("gdiplus\GdipDeleteStringFormat", "ptr", hFormatC)
	DllCall("gdiplus\GdipDeleteStringFormat", "ptr", hFormatL)

	DllCall("gdiplus\GdipDeleteGraphics", "ptr", hGraphicsCtxt)
	DllCall("gdiplus\GdipDisposeImage", "ptr", hBitmap)
	DllCall("gdiplus\GdipDeleteGraphics", "ptr", hGraphics)
	if (GdipToken)
		DllCall("gdiplus\GdiplusShutdown", "ptr", GdipToken)
	ExitApp
}


; FUNCTIONS =====================================================================================================================

GdipCreateBitmapFromGraphics(hGraphics, Width, Height)
{
	if !(DllCall("gdiplus\GdipCreateBitmapFromGraphics", "int",  Width
	                                                   , "int",  Height
													   , "ptr",  hGraphics
													   , "ptr*", &hBitmap := 0))
		return hBitmap
	MsgBox "GdipCreateBitmapFromGraphics"
}


GdipCreateFont(hFamily, Size, Style := 0, Unit := 3)
{
	if !(DllCall("gdiplus\GdipCreateFont", "ptr",   hFamily
	                                     , "float", Size
										 , "int",   Style
										 , "int",   Unit
										 , "ptr*", &hFont := 0))
		return hFont
	MsgBox "GdipCreateBitmapFromGraphics"
}


GdipCreateFontFamilyFromName(Family, Collection := 0)
{
	if !(DllCall("gdiplus\GdipCreateFontFamilyFromName", "wstr", Family
	                                                   , "ptr",  Collection
													   , "ptr*", &hFamily := 0))
		return hFamily
	MsgBox "GdipCreateBitmapFromGraphics"
}


GdipCreateFromHWND(hwnd)
{
	if !(DllCall("gdiplus\GdipCreateFromHWND", "ptr",  hwnd
	                                         , "ptr*", &hGraphics := 0))
		return hGraphics
	MsgBox "GdipCreateFromHWND"
}


GdipCreatePen1(ARGB, Width, Unit := 2)
{
	if !(DllCall("gdiplus\GdipCreatePen1", "uint",  ARGB
	                                     , "float", Width
										 , "int",   Unit
										 , "ptr*",  &hPen := 0))
		return hPen
	MsgBox "GdipCreatePen1"
}


GdipCreateRectF(X, Y, Width, Height)
{
	RectF := Buffer(16)
	NumPut("float", X, "float", Y, "float", Width, "float", Height, RectF)
	return RectF
}


GdipCreateSolidFill(ARGB)
{
	if !(DllCall("gdiplus\GdipCreateSolidFill", "int",  ARGB
	                                          , "ptr*", &hBrush := 0))
		return hBrush
	MsgBox "GdipCreateSolidFill"
}


GdipCreateStringFormat(Format := 0, LangID := 0)
{
	if !(DllCall("gdiplus\GdipCreateStringFormat", "int",  Format
	                                             , "int",  LangID
												 , "ptr*", &hFormat := 0))
		return hFormat
	MsgBox "GdipCreateStringFormat"
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
	MsgBox "GdipDrawArc"
}


GdipDrawImage(hGraphics, hImage, X, Y)
{
	if !(DllCall("gdiplus\GdipDrawImage", "ptr",   hGraphics
	                                    , "ptr",   hImage
										, "float", X
										, "float", Y))
		return true
	MsgBox "GdipDrawImage"
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
	MsgBox "GdipDrawLine"
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
	MsgBox "GdipDrawString"
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
	MsgBox "GdipFillPie"
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
	MsgBox "GdipFillRectangle"
}


GdipGetImageGraphicsContext(hImage)
{
	if !(DllCall("gdiplus\GdipGetImageGraphicsContext", "ptr",  hImage
	                                                  , "ptr*", &hGraphics := 0))
		return hGraphics
	MsgBox "GdipGetImageGraphicsContext"
}


GdipGraphicsClear(hGraphics, ARGB)
{
	if !(DllCall("gdiplus\GdipGraphicsClear", "ptr",  hGraphics
	                                        , "uint", ARGB))
		return true
	MsgBox "GdipGraphicsClear"
}


GdipSetSmoothingMode(hGraphics, SmoothingMode)
{
	if !(DllCall("gdiplus\GdipSetSmoothingMode", "ptr", hGraphics
	                                           , "int", SmoothingMode))
		return true
	MsgBox "GdipSetSmoothingMode"
}


GdipSetStringFormatAlign(hStringFormat, Flag)
{
	if !(DllCall("gdiplus\GdipSetStringFormatAlign", "ptr", hStringFormat
	                                               , "int", Flag))
		return true
	MsgBox "GdipSetStringFormatAlign"
}


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
	Drives := Map()
	for v in StrSplit(DriveGetList())
	{
		GT := DriveGetType(v ":")
		if (GT != "Fixed") && (GT != "Removable")
			continue
		try {
			DR := Map()
			DR["Letter"] := v
			GC := DriveGetCapacity(v ":")
			DR["Cap"]    := Round(GC / 1024, 2) " GB"
			GF := DriveGetSpaceFree(v ":")
			DR["Free"]   := Round(GF / 1024, 2) " GB"
			DR["Used"]   := Round((GC - GF) / 1024, 2) " GB"
			DR["Perc"]   := Round((1 - GF / GC) * 100, 0)
		} catch {
			continue	; skip full encrypted drives (bitlocker / veracrypt / ...)
		}
		Drives[A_Index] := DR
	}
	return Drives
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


SaveLocation(X, Y)
{
	if (A_IsCompiled)
		return
	IniWrite X, A_ScriptFullPath, "Settings", "LocationX"
	IniWrite Y, A_ScriptFullPath, "Settings", "LocationY"
}


LoadLocation()
{
	if (A_IsCompiled)
		return
	X := IniRead(A_ScriptFullPath, "Settings", "LocationX", 10)
	Y := IniRead(A_ScriptFullPath, "Settings", "LocationY", 10)
	return Map("X", X, "Y", Y)
}

