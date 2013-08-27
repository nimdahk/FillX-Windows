ignoreClasses = Progman,DV2ControlHost,Button
ignoreTitles  = 
hotkey = #MButton ; Place the shape-switching symbol in front if using multiple modifiers.
toggle := False ; Use False for move-while-holding and True for one click to start, one to finish
; End Config


#NoEnv
#Warn
#SingleInstance Force
CoordMode Mouse


modifier := SubStr(Hotkey, 1, 1)
modifierName := {"!": "Alt", "+": "Shift", "#": "Win", "^": "Ctrl"}[modifier]
buttonName := RegExReplace(Hotkey, "[!+*#<>]", "")
Hotkey, %Hotkey%, Start
return

Start:
	MouseGetPos,,, targetID
	targetID := "ahk_id " . targetID
	WinGet, list, List
	winList := []
	Loop % list
	{
		id := "ahk_id " . list%A_Index%
		If (id == targetID)
			continue
		WinGet, state, MinMax, % id
		If (state == 1) ; Maximized, ignore all windows below it because the user can't see them
			break
		If (state == -1) ; Minimized, ignore it entirely
			continue
		WinGetClass, class, % id
		If class in %ignoreClasses%
			continue
		WinGetTitle, title, % id
		If title in %ignoreTitles%
			continue
		WinGetPos, x, y, width, height, % id
		winList.insert({"id": id, "x": x, "y": y
						,"right": x + width, "bottom": y + height, "title": title})
	}
	WinRestore, % targetID ; Resizing maximized windows causes size issues with manual restoring
        If InStr(Hotkey, "#")
	{
		Hotkey, LWin Up, BreakStartMenu, On
		Hotkey, RWin Up, BreakStartMenu, On
	}
	If toggle
		KeyWait, %buttonName%
	While GetKeyState(buttonName, "P") ^ toggle
	{
		MouseGetPos, mouseX, mouseY
		For each, window in winList ; wait until the mouse isn't over another window
			If (window.X <= mouseX and mouseX <= window.right)
				and (window.Y <= mouseY and mouseY <= window.bottom)
					continue 2
		
		
		rect := monitorDimensionsAtMouse()
		mouse := {x: mouseX, y: mouseY}
		; Hack around 'Win' not being valid, though 'Ctrl' is,
		; by using explicit keyboard sides ('LWin', 'RCtrl') for everything
		If GetKeyState("L" . modifierName, "P") || GetKeyState("R" . modifierName, "P")
			xy1 := "Y", xy2 := "X", s1 := "top", s2 := "left", s3 := "bottom", s4 := "right"
		Else
			xy1 := "X", xy2 := "Y", s1 := "left", s2 := "top", s3 := "right", s4 := "bottom"
		
		; Search either horizontally from the mouse for the closest rights and lefts of windows
		; (These will become the left and right of the new window position, respectively)
		; Or vertically for the nearest bottoms and tops -> top and bottom of the new position
		For each, window in winList
			If (window[xy1] <= mouse[xy1] and mouse[xy1] <= window[s3])
				If (mouse[xy2] < window[xy2] and window[xy2] < rect[s4])
					rect[s4] := window[xy2]
				Else If (mouse[xy2] > window[s4] and window[s4] > rect[s2])
					rect[s2] := window[s4]
		
		; Now that we have two opposing sides - a line - we fill the line out into a rectangle
		; by finding the other sides. This is trickier because a window can bound anywhere
		; on the line, rather than just in a straight line from the mouse.
		For each, window in winList
			If (window[xy2] <= rect[s2] and rect[s2] <= window[s4]) 
				or (rect[s2] <= window[xy2] and window[xy2] <= rect[s4])
					If (mouse[xy1] < window[xy1] and window[xy1] < rect[s3])
						rect[s3] := window[xy1]
					Else If (mouse[xy1] > window[s3] and window[s3] > rect[s1])
						rect[s1] := window[s3]
		
		WinMove, % targetID,, % rect.left, % rect.top
				, % rect.right - rect.left, % rect.bottom - rect.top
	}
	Hotkey, LWin Up, Off
	Hotkey, RWin Up, Off
return

BreakStartMenu:
return

monitorDimensionsAtMouse(){
	VarSetCapacity(monitorInfo, 40, 0)
	NumPut(40, monitorInfo)
	VarSetCapacity(point, 8, 0)
	DllCall("GetCursorPos", "UPtr", &point)
	hmonitor := DllCall("MonitorFromPoint", "int64", point, "Uint", 2)
	DllCall("GetMonitorInfo"
		, "UPtr", hmonitor
		, "UPtr", &monitorInfo)
	return {left: NumGet(monitorInfo, 4, "int")
		, top: NumGet(monitorInfo, 8, "int")
		, right: NumGet(monitorInfo, 12, "int")
		, bottom: NumGet(monitorInfo, 16, "int")}
}