local g_Window, g_Panel, g_Bar
local g_Rating = false
local g_HideTimer = false
local g_PosX, g_PosY = ( g_ScreenSize[1] - 300 ) / 2 - 205, 5
local g_Anim1, g_Anim2

addEvent("onPlayerRate", true)
addEvent("onClientSetRateGuiVisibleReq", true)
addEvent("onClientMapStopping")

local function RtInitGui()
	g_Window = guiCreateWindow(g_PosX, -80, 300, 80, "Rate this map", false)
	g_Panel = guiCreateLabel(g_PosX, -80+15, 300, 80 - 15, "", false)
	guiSetVisible(g_Window, false)
	guiSetVisible(g_Panel, false)
	guiWindowSetMovable(g_Window, false)
	guiWindowSetSizable(g_Window, false)
	guiSetAlpha(g_Window, 0.3)
	
	guiCreateLabel(5, 5, 290, 20, "Press 0-9 to rate this map", false, g_Panel)
	
	local rafalh_shared = getResourceFromName("rafalh_shared")
	if(rafalh_shared) then
		g_Bar = call(rafalh_shared, "createAnimatedProgressBar", 5, 30, 290, 20, false, false, false, g_Panel)
	end
	
	if(not g_Bar) then
		g_Bar = guiCreateProgressBar(5, 30, 290, 20, false, g_Panel)
	end
	guiSetVisible(g_Bar, false)
end

local function RtUpdateBar()
	if(g_Bar and g_Rating) then
		local rafalh_shared = getResourceFromName("rafalh_shared")
		if(getElementType(g_Bar) == "gui-progressbar") then
			guiProgressBarSetProgress(g_Bar, g_Rating * 10)
		elseif(rafalh_shared) then
			call(rafalh_shared, "setAnimatedProgressBarProgress", g_Bar, g_Rating * 10, 500)
		end
		guiSetVisible(g_Bar, true)
	end
end

local function RtKeyUp(key)
	if(g_Bar) then
		g_Rating = touint(key) + 1
		RtUpdateBar()
		resetTimer(g_HideTimer)
	end
end

local function RtSetBinds(enabled)
	if(enabled) then
		for i = 0, 9, 1 do
			bindKey(tostring ( i ), "up", RtKeyUp)
		end
	else
		for i = 0, 9, 1 do
			unbindKey(tostring ( i ), "up", RtKeyUp)
		end
	end
end

local function RtDestroyGui()
	g_Rating = false
	
	if(g_Anim1) then
		g_Anim1:remove()
		g_Anim2:remove()
	end
	
	RtSetBinds(false)
	if (g_Window) then
		destroyElement(g_Window)
		destroyElement(g_Panel)
	end
	g_Window, g_Panel, g_Bar = false, false, false
end

local function RtHideGui()
	if(g_HideTimer) then
		killTimer(g_HideTimer)
		g_HideTimer = false
	end
	
	if(not g_Window or not guiGetVisible(g_Window)) then return end
	
	if(g_Anim1) then
		g_Anim1:remove()
		g_Anim2:remove()
	end
	
	g_Anim1 = Animation.createAndPlay(g_Window,
		Animation.presets.guiMoveEx(g_PosX, -80, 500, "InQuad"),
		Animation.presets.guiSetVisible(false))
	g_Anim2 = Animation.createAndPlay(g_Panel,
		Animation.presets.guiMoveEx(g_PosX, -80+15, 500, "InQuad"),
		Animation.presets.guiSetVisible(false))
	
	RtSetBinds(false)
	
	if(g_Rating) then
		triggerServerEvent("onPlayerRate", g_Me, g_Rating)
		g_Rating = false
	end
end

local function RtShowGui()
	if(not g_Window) then
		RtInitGui()
	end
	
	if(g_Anim1) then
		g_Anim1:remove()
		g_Anim2:remove()
	end
	
	guiSetVisible(g_Window, true)
	guiSetVisible(g_Panel, true)
	
	g_Anim1 = Animation.createAndPlay(g_Window, Animation.presets.guiMoveEx(g_PosX, g_PosY, 500, "InOutQuad"))
	g_Anim2 = Animation.createAndPlay(g_Panel, Animation.presets.guiMoveEx(g_PosX, g_PosY+15, 500, "InOutQuad"))
	
	RtSetBinds(true)
	
	if(g_HideTimer) then
		resetTimer(g_HideTimer)
	else
		g_HideTimer = setTimer(RtHideGui, 15000, 1)
	end
end

local function RtSetVisible(visible)
	if(visible) then
		RtShowGui()
	else
		RtHideGui()
	end
end

local function RtMapStop()
	RtDestroyGui()
end

------------
-- Events --
------------

addEventHandler("onClientSetRateGuiVisibleReq", g_Root, RtSetVisible)
addEventHandler("onClientMapStopping", g_Root, RtMapStop)
