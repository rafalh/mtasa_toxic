local DEBUG = false
local g_Window, g_Panel
local g_Stars = {}
local g_Rating = false
local g_HideTimer = false
local g_PosX, g_PosY = (g_ScreenSize[1] - 250) / 2 - 205, 5
local g_Anim1, g_Anim2

addEvent("onPlayerRate", true)
addEvent("onClientSetRateGuiVisibleReq", true)
addEvent("onClientMapStopping")

local function RtInitGui()
	g_Window = guiCreateWindow(g_PosX, -80, 250, 80, "Rate this map", false)
	g_Panel = guiCreateLabel(g_PosX, -80+15, 250, 80 - 15, "", false)
	guiSetVisible(g_Window, false)
	guiSetVisible(g_Panel, false)
	guiWindowSetMovable(g_Window, false)
	guiWindowSetSizable(g_Window, false)
	guiSetAlpha(g_Window, 0.3)
	
	guiCreateLabel(5, 5, 240, 20, "Press 1-5 to rate this map", false, g_Panel)
	
	for i = 1, 5 do
		g_Stars[i] = {}
		g_Stars[i].el = guiCreateStaticImage(5 + 35*(i - 1), 25, 32, 32, "img/star.png", false, g_Panel)
		guiSetAlpha(g_Stars[i].el, 0.3)
		g_Stars[i].anim = false
	end
end

local function RtUpdateRating()
	assert(g_Rating)
	
	for i, star in ipairs(g_Stars) do
		local alpha = g_Rating >= i and 1 or 0.3
		local curAlpha = guiGetAlpha(star.el)
		if(curAlpha ~= alpha) then
			if(star.anim) then
				star.anim:remove()
			end
			star.anim = Animation.createAndPlay(star.el, { from = curAlpha, to = alpha, time = 200, fn = guiSetAlpha })
		end
	end
end

local function RtKeyUp(key)
	g_Rating = touint(key)
	RtUpdateRating()
	resetTimer(g_HideTimer)
end

local function RtSetBinds(enabled)
	if(enabled) then
		for i = 1, 5 do
			bindKey(tostring(i), "up", RtKeyUp)
		end
	else
		for i = 1, 5 do
			unbindKey(tostring(i), "up", RtKeyUp)
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
	g_Window, g_Panel = false, false
	
	for i, star in ipairs(g_Stars) do
		if(star.anim) then
			star.anim:remove()
		end
	end
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

local function RtInit()
	if(DEBUG) then
		RtSetVisible(true)
	end
end

------------
-- Events --
------------

addEventHandler("onClientSetRateGuiVisibleReq", g_Root, RtSetVisible)
addEventHandler("onClientMapStopping", g_Root, RtMapStop)
addEventHandler("onClientResourceStart", g_ResRoot, RtInit)
