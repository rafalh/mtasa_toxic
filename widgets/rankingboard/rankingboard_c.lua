--------------
-- Includes --
--------------

#include "../../include/serv_verification.lua"
#include "../../include/widgets.lua"

---------------------
-- Local variables --
---------------------

local SCALE = 1
local FONT = "default"
local PLAYER_FONT = "default-bold"
local FONT_HEIGHT = dxGetFontHeight(SCALE, FONT)
local WHITE = tocolor(255, 255, 255)
local BLACK = tocolor(0, 0, 0)
local POS_OFFSET = 30
local USE_RENDER_TARGET = true
local g_WidgetName = {"Ranking board", pl = "Tablica wyników"}

local g_Root = getRootElement ()
local g_Me = getLocalPlayer ()
local g_ScreenSize = { guiGetScreenSize () }
local g_ScreenSizeSqrt = { g_ScreenSize[1]^(1/2), g_ScreenSize[2]^(1/2) }
local g_Show, g_Size, g_Pos = false -- set in WG_RESET
local g_WidgetCtrl = {}
local g_Items = {}
local g_FirstTime = false
local g_MaxNameW = 0
local g_InsertTimeStamp, g_InsertRank = false, false
local g_Buffer = false

addEvent("rb_addItem", true)
addEvent("rb_clear", true)

---------------------
-- Local functions --
---------------------

function formatTimePeriod(t, decimals)
	assert(t)
	local h = math.floor(t / 3600)
	local m = math.floor((t % 3600) / 60)
	local s = t % 60
	
	if(h > 0) then
		return ("%u:%02u:%05.2f"):format(h, m, s)
	else
		return ("%u:%05.2f"):format(m, s)
	end
end

--local cnt = 0
--local dt = 0

local function RbRenderBoard(x, y, w, h, anim)
	local first = true
	local maxY = y + h
	
	for rank, item in ipairs(g_Items) do
		if(item) then
			local itemY = y
			local itemAlpha = 255
			local white = WHITE
			local black = BLACK
			
			if(g_InsertRank == rank and anim) then
				local ticks = getTickCount()
				local progress = (ticks - g_InsertTimeStamp)/500
				if(progress < 1) then
					if(first) then
						-- scroll rest of items
						y = y + progress*FONT_HEIGHT - FONT_HEIGHT
					end
					itemAlpha = progress*255
					white = tocolor(255, 255, 255, itemAlpha)
					black = tocolor(0, 0, 0, itemAlpha)
				else
					g_InsertRank = false
				end
			end
			first = false
			
			local text = rank..")"
			dxDrawText(text, x+1, itemY+1, x+POS_OFFSET+1, itemY+1, black, SCALE, PLAYER_FONT, "right")
			dxDrawText(text, x, itemY, x+POS_OFFSET, itemY, white, SCALE, PLAYER_FONT, "right")
			
			local r, g, b = unpack(item.clr)
			local color = tocolor(r, g, b, itemAlpha)
			dxDrawText(item.name2..":", x+5+POS_OFFSET+1, itemY+1, 0, 0, black, SCALE, PLAYER_FONT)
			dxDrawText(item.name..":", x+5+POS_OFFSET, itemY, 0, 0, color, SCALE, PLAYER_FONT, "left", "top", false, false, false, true)
			
			dxDrawText(item[2], x+5+POS_OFFSET+g_MaxNameW+5+1, itemY+1, 0, 0, black, SCALE, FONT)
			dxDrawText(item[2], x+5+POS_OFFSET+g_MaxNameW+5, itemY, 0, 0, white, SCALE, FONT)
			
			y = y + FONT_HEIGHT
			if(y + FONT_HEIGHT > maxY) then return end
		end
	end
end

local function RbRenderBuffered()
	local x, y = g_Pos[1], g_Pos[2]
	local w, h = g_Size[1], g_Size[2]
	
	local ticks = getTickCount()
	local progress = 1
	if(g_InsertTimeStamp) then
		progress = (ticks - g_InsertTimeStamp)/500
	end
	
	--dxSetBlendMode("add")
	if(progress < 1) then
		local offset = 0
		
		-- draw lines before
		if(g_InsertRank > 1) then
			local beforeH = (g_InsertRank - 1)*FONT_HEIGHT
			dxDrawImageSection(x, y, w, beforeH, 0, 0, w, beforeH, g_Buffer)
			offset = beforeH
		end
		
		local clr = tocolor(255, 255, 255, progress*255)
		dxDrawImageSection(x, y + offset, w, FONT_HEIGHT, 0, offset, w, FONT_HEIGHT, g_Buffer, 0, 0, 0, clr)
		offset = offset + progress*FONT_HEIGHT
		
		-- draw rest
		if(g_InsertRank < #g_Items) then
			dxDrawImageSection(x, y + offset, w, h - offset, 0, offset, w, h - offset, g_Buffer)
		end
	else
		dxDrawImage(x, y, w, h, g_Buffer)
	end
		
	--dxSetBlendMode("blend")
end

local function RbRender()
	if(g_Buffer) then
		RbRenderBuffered()
	else
		RbRenderBoard(g_Pos[1], g_Pos[2], g_Size[1], g_Size[2], true)
	end
end

local function RbUpdateBuffer()
	if(not g_Buffer) then
		g_Buffer = dxCreateRenderTarget(g_Size[1], g_Size[2], true)
	end
	dxSetRenderTarget(g_Buffer, true)
	dxSetBlendMode("modulate_add")
	RbRenderBoard(0, 0, g_Size[1], g_Size[2], false)
	dxSetBlendMode("blend")
	dxSetRenderTarget()
end

local function RbClear()
	--outputDebugString("RbClear", 3)
	g_Items = {}
	g_FirstTime = false
	g_InsertTimeStamp = false
	g_InsertRank = false
	g_MaxNameW = 0
	
	if(USE_RENDER_TARGET) then
		RbUpdateBuffer()
	end
end

local function RbAddItem(player, rank, time)
	local timeStr
	if(g_FirstTime) then
		local dt = time - g_FirstTime
		assert(dt >= 0)
		timeStr = "+"..formatTimePeriod(dt)
	else
		timeStr = " "..formatTimePeriod(time)
		g_FirstTime = time
	end
	
	-- make sure there is no holes in g_Items
	while(#g_Items < rank) do
		table.insert(g_Items, false)
	end
	
	-- add item (table still doesnt have holes)
	local item = {player, timeStr, time}
	if(type(player)=="userdata") then
		item.name = getPlayerName(player)
		item.clr = {getPlayerNametagColor(player)}
	else
		item.name = player
		item.clr = {255, 255, 255}
	end
	item.name2 = item.name:gsub("#%x%x%x%x%x%x", "")
	item.nameW = dxGetTextWidth(item.name2..":", SCALE, PLAYER_FONT)
	if(item.nameW > g_MaxNameW) then
		g_MaxNameW = item.nameW + 10
	end
	
	g_Items[rank] = item
	g_InsertTimeStamp = getTickCount()
	g_InsertRank = rank
	
	if(USE_RENDER_TARGET) then
		RbUpdateBuffer()
	end
end

local function RbPlayerQuit()
	for rank, item in ipairs(g_Items) do
		if(item and item[1] == source) then
			local playerName = getPlayerName(source)
			local r, g, b = getPlayerNametagColor(source)
			playerName = ("#%02X%02X%02X"):format(r, g, b)..playerName
			item[1] = playerName
		end
	end
end

local function RbPlayerChangeNick()
	for rank, item in ipairs(g_Items) do
		if(item and item[1] == source) then
			item.name = getPlayerName(source)
			item.name2 = item.name:gsub("#%x%x%x%x%x%x", "")
			item.clr = {getPlayerNametagColor(item[1])}
			item.nameW = dxGetTextWidth(item.name2..":", SCALE, PLAYER_FONT)
			if(item.nameW > g_MaxNameW) then
				g_MaxNameW = item.nameW + 10
			end
			
			if(USE_RENDER_TARGET) then
				RbUpdateBuffer()
			end
		end
	end
end

local function RbRestore()
	
end

g_WidgetCtrl[$(wg_show)] = function(b)
	if((g_Show and b) or (not g_Show and not b)) then return end
	g_Show = b
	if(b) then
		addEventHandler("onClientRender", g_Root, RbRender)
	else
		removeEventHandler("onClientRender", g_Root, RbRender)
	end
end

g_WidgetCtrl[$(wg_isshown)] = function()
	return g_Show
end

g_WidgetCtrl[$(wg_move)] = function(x, y)
	g_Pos = { x, y }
end

g_WidgetCtrl[$(wg_resize)] = function(w, h)
	g_Size = { w, h }
	
	if(g_Buffer) then
		destroyElement(g_Buffer)
		g_Buffer = false
	end
end

g_WidgetCtrl[$(wg_getsize)] = function()
	return g_Size
end

g_WidgetCtrl[$(wg_getpos)] = function()
	return g_Pos
end

g_WidgetCtrl[$(wg_reset)] = function()
	g_Size = { 320, 0.77*g_ScreenSize[2]-250 }
	g_Pos = { 30, 250 }
	g_WidgetCtrl[$(wg_show)](true)
end

---------------------------------
-- Global function definitions --
---------------------------------

function widgetCtrl(op, arg1, arg2)
	if(g_WidgetCtrl[op]) then
		return g_WidgetCtrl[op](arg1, arg2)
	end
end

----------
-- Code --
----------

#VERIFY_SERVER_BEGIN("C1D8B0E1B3B359CF45DFADB93EC56B62")
	g_WidgetCtrl[$(wg_reset)] () -- reset pos, size, visiblity
	triggerEvent("onRafalhAddWidget", g_Root, getThisResource(), g_WidgetName)
	addEventHandler("onRafalhGetWidgets", g_Root, function()
		triggerEvent("onRafalhAddWidget", g_Root, getThisResource(), g_WidgetName)
	end)
	
	addEventHandler("rb_clear", resourceRoot, RbClear)
	addEventHandler("rb_addItem", resourceRoot, RbAddItem)
	addEventHandler("onClientPlayerQuit", root, RbPlayerQuit)
	addEventHandler("onClientPlayerChangeNick", root, RbPlayerChangeNick)
	if(USE_RENDER_TARGET) then
		addEventHandler("onClientRestore", root, RbUpdateBuffer)
	end
	
	triggerServerEvent("rb_onPlayerReady", resourceRoot)
#VERIFY_SERVER_END()