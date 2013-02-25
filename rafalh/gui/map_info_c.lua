--------------
-- Includes --
--------------

#include "include/internal_events.lua"

---------------------
-- Local variables --
---------------------

local TEXT_COLOR = tocolor(255, 255, 255)
local MYSELF_COLOR = tocolor(180, 255, 255)
local BACKGROUND_COLOR = tocolor(0, 0, 0, 64)
local ENABLED_STAR_CLR = tocolor(255, 255, 255)
local DISABLED_STAR_CLR = tocolor(255, 255, 255, 64)
local USE_RENDER_TARGER = true

local g_MapInfo = {name = "", author = false, rating = 0, rates_count = 0, played = 0}
local g_Toptimes = {}
local g_MyBestTime = false
local g_HideTimer = false
local g_Visible, g_AnimStart, g_Hiding = false, false, false
local g_Textures = {}
local g_Buffer = false

--------------------------------
-- Local function definitions --
--------------------------------

local function MiRenderMapInfo(x, y, w, h)
	-- Background
	dxDrawRectangle(x, y, w, h, BACKGROUND_COLOR)
	
	-- General info
	local author = g_MapInfo.author or MuiGetMsg("unknown")
	dxDrawText(MuiGetMsg("Map: %s"):format(g_MapInfo.name), x + 10, y + 10, x + w, y + 25, TEXT_COLOR, 1, "default-bold", "left", "top", true, false, false, true)
	dxDrawText(MuiGetMsg("Author: %s"):format(author), x + 10, y + 25, x + w, y + 40, TEXT_COLOR, 1, "default", "left", "top", true, false, false, true)
	dxDrawText(MuiGetMsg("Played: %u times"):format(g_MapInfo.played), x + 10, y + 40, 0, 0, TEXT_COLOR, 1, "default")
	
	-- Rates
	dxDrawText("Rating:", x + 10, y + 55)
	for i = 0, 4, 1 do
		if(i*2 < g_MapInfo.rating and g_MapInfo.rating <= i*2 + 1) then
			-- half star
			dxDrawImage(x + 60 + i*16, y + 55, 8, 16, g_Textures.star_l)
			dxDrawImage(x + 60 + i*16 + 8, y + 55, 8, 16, g_Textures.star_r, 0, 0, 0, DISABLED_STAR_CLR)
		else
			-- full star
			local clr = (g_MapInfo.rating <= i*2) and DISABLED_STAR_CLR or ENABLED_STAR_CLR
			dxDrawImage(x + 60 + i*16, y + 55, 16, 16, g_Textures.star, 0, 0, 0, clr)
		end
	end
	dxDrawText(MuiGetMsg("(%u rates)"):format(g_MapInfo.rates_count), x + 65 + 5*16, y + 55)
	
	-- Top times
	if(#g_Toptimes == 0) then return end
	
	dxDrawText("Top Times:", x + 10, y + 75)
	
	dxDrawText("Pos", x + 10, y + 90)
	dxDrawText("Time", x + 45, y + 90)
	dxDrawText("Player", x + 120, y + 90)
	
	dxDrawLine(x + 10, y + 105, x + w - 10, y + 105)
	
	for i, data in ipairs ( g_Toptimes ) do
		local itemY = y + 95 + i * 14
		local clr = (data.player == g_MyId) and MYSELF_COLOR or TEXT_COLOR
		
		dxDrawText(tostring(i), x + 10, itemY, x + 45, itemY + 15, clr, 1, "default-bold")
		dxDrawText(data.time, x + 45, itemY, x + 120, itemY + 15, clr, 1, "default-bold")
		dxDrawText(data.name, x + 120, itemY, x + w, itemY + 15, clr, 1, "default-bold", "left", "top", true, false, false, true)
	end
	
	if(g_MyBestTime) then
		local itemY = y + 95 + (#g_Toptimes + 1) * 14
		
		if(g_MyBestTime.place > #g_Toptimes + 1) then -- dont display "..." if we are 9th
			dxDrawText("...", x + 10, itemY)
			dxDrawText("...", x + 45, itemY)
			dxDrawText("...", x + 120, itemY)
			itemY = itemY + 14
		end
		
		dxDrawText(g_MyBestTime.place, x + 10, itemY, x + 45, itemY + 15, MYSELF_COLOR, 1, "default-bold")
		dxDrawText(g_MyBestTime.time, x + 45, itemY, x + 120, itemY + 15, MYSELF_COLOR, 1, "default-bold")
		dxDrawText(getPlayerName(g_Me), x + 120, itemY, x + w, itemY + 15, MYSELF_COLOR, 1, "default-bold", "left", "top", true, false, false, true)
	end
end

local function MiGetSize()
	local w, h = 300, 80
	if(#g_Toptimes > 0) then
		h = h + 35 + #g_Toptimes * 14
	end
	if(g_MyBestTime) then
		h = h + 14
		if(g_MyBestTime.place > #g_Toptimes + 1) then
			h = h + 14
		end
	end
	return w, h
end

local function MiUpdateBuffer()
	if(g_Buffer) then
		destroyElement(g_Buffer)
	end
	
	local w, h = MiGetSize()
	g_Buffer = dxCreateRenderTarget(w, h, true)
	dxSetRenderTarget(g_Buffer, true)
	dxSetBlendMode("modulate_add")
	MiRenderMapInfo(0, 0, w, h)
	dxSetBlendMode("blend")
	dxSetRenderTarget()
end

local function MiRender()
	local x, y = g_ScreenSize[1] / 2 + 64, 5
	local w, h = MiGetSize()
	
	-- Animation (show/hide)
	if(g_AnimStart) then
		local dt = getTickCount() - g_AnimStart
		local progress = dt / 500
		if(progress < 1) then
			if(g_Hiding) then
				progress = getEasingValue(progress, "InQuad")
				y = y - progress*(y + h)
			else
				progress = getEasingValue(progress, "InOutQuad")
				y = -h + progress*(y + h)
			end
		else
			g_AnimStart = false
			
			if(g_Hiding) then
				g_Visible = false
				removeEventHandler("onClientRender", g_Root, MiRender)
				return
			end
		end
	end
	
	if(g_Buffer) then
		dxSetBlendMode("add")
		dxDrawImage(x, y, w, h, g_Buffer)
		dxSetBlendMode("blend")
	else
		MiRenderMapInfo(x, y, w, h)
	end
end

local function MiRestore()
	if(USE_RENDER_TARGER) then
		MiUpdateBuffer()
	end
end

local function hideTopTimes()
	if(not g_Visible or g_Hiding) then return end
	
	if(g_HideTimer) then
		killTimer(g_HideTimer)
		g_HideTimer = false
	end
	
	g_Hiding = true
	g_AnimStart = getTickCount()
end

local function showTopTimes()
	if(g_Visible) then return end
	
	g_Visible = true
	g_Hiding = false
	g_AnimStart = getTickCount()
	addEventHandler("onClientRender", g_Root, MiRender)
	g_HideTimer = setTimer(hideTopTimes, 15000, 1)
end

local function keyUpHandler()
	if(g_Visible) then
		hideTopTimes()
	else
		showTopTimes()
	end
end

local function onClientInit()
	bindKey("f5", "up", keyUpHandler)
	
	g_Textures.star = dxCreateTexture("img/star.png")
	g_Textures.star_l = dxCreateTexture("img/star_l.png")
	g_Textures.star_r = dxCreateTexture("img/star_r.png")
end

local function onClientMapInfo(show, mapInfo, topTimes, myBestTime)
	g_MapInfo, g_Toptimes = mapInfo, topTimes
	g_MyBestTime = myBestTime and myBestTime.place > #g_Toptimes and myBestTime
	
	if(USE_RENDER_TARGER) then
		MiUpdateBuffer()
	end
	
	if(show) then
		showTopTimes()
		if(g_HideTimer) then
			resetTimer(g_HideTimer)
		end
	end
end

------------
-- Events --
------------

addEventHandler("onClientRestore", g_Root, MiRestore)
addInternalEventHandler($(EV_CLIENT_INIT), onClientInit)
addInternalEventHandler($(EV_CLIENT_MAP_INFO), onClientMapInfo)
