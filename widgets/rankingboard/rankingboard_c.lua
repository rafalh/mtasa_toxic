--------------
-- Includes --
--------------

#include "../../include/serv_verification.lua"
#include "../../include/widgets.lua"

---------------------
-- Local variables --
---------------------

local SCALE = 0.5
local FONT = "bankgothic"
local FONT_HEIGHT = dxGetFontHeight(SCALE, FONT)
local SHADOW_COLOR = tocolor(0, 0, 0)
local WHITE = tocolor(255, 255, 255)
local POS_OFFSET = 30

local g_Root = getRootElement ()
local g_Me = getLocalPlayer ()
local g_ScreenSize = { guiGetScreenSize () }
local g_ScreenSizeSqrt = { g_ScreenSize[1]^(1/2), g_ScreenSize[2]^(1/2) }
local g_Show, g_Size, g_Pos = false -- set in WG_RESET
local g_WidgetCtrl = {}
local g_Items = {}
local g_Dir = "down"
local g_ScrollStart = false

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

local function RbRender()
	if(not g_Items) then return end
	
	local a = (g_Dir == "down" and 1 or #g_Items)
	local b = (g_Dir == "down" and #g_Items or 1)
	local c = (g_Dir == "down" and 1 or -1)
	
	local x, y = g_Pos[1], g_Pos[2]
	if(g_ScrollStart) then
		local ticks = getTickCount()
		local progress = (ticks - g_ScrollStart)/500
		if(progress >= 1 or g_Dir == "down") then
			g_ScrollStart = false
		else
			a = a - 1
			progress = getEasingValue(progress, "InOutQuad")
			y = y + progress*FONT_HEIGHT
		end
	end
	
	for i = a, b, c do
		local item = g_Items[i]
		local pos = (g_Dir == "down" and i or (#g_Items+1-i))
		local text = pos..")"
		dxDrawText(text, x+1, y+1, x+POS_OFFSET+1, y+1, SHADOW_COLOR, SCALE, FONT, "right")
		dxDrawText(text, x, y, x+POS_OFFSET, y, tocolor(255, 255, 255), SCALE, FONT, "right")
		
		local playerName = item[1]
		local color = WHITE
		if(type(item[1]) ~= "string") then
			playerName = getPlayerName(item[1])
			color = tocolor(getPlayerNametagColor(item[1]))
		end
		local text = playerName.."#FFFFFF: "..item[2]
		dxDrawText(text:gsub("#%x%x%x%x%x%x", ""), x+POS_OFFSET+5+1, y+1, 0, 0, SHADOW_COLOR, SCALE, FONT)
		dxDrawText(text, x+5+POS_OFFSET, y, 0, 0, color, SCALE, FONT, "left", "top", false, false, false, true)
		
		y = y + FONT_HEIGHT
	end
end

local function RbClear(dir)
	g_Items = {}
	g_Dir = dir
end

local function RbAddItem(player, time)
	local timeStr
	if(#g_Items > 0) then
		local dt = time - g_Items[1][3]
		assert(dt >= 0)
		timeStr = "+"..formatTimePeriod(dt)
	else
		timeStr = formatTimePeriod(time)
	end
	
	local item = {player, timeStr, time}
	table.insert(g_Items, item)
	if(#g_Items >= 2) then
		g_ScrollStart = getTickCount()
	end
end

local function RbPlayerQuit()
	for i, item in ipairs(g_Items) do
		if(item[1] == source) then
			local playerName = getPlayerName(source)
			local r, g, b = getPlayerNametagColor(source)
			playerName = ("#%02X%02X%02X"):format(r, g, b)..playerName
			item[1] = playerName
		end
	end
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
end

g_WidgetCtrl[$(wg_getsize)] = function()
	return g_Size
end

g_WidgetCtrl[$(wg_getpos)] = function()
	return g_Pos
end

g_WidgetCtrl[$(wg_reset)] = function()
	g_Size = { g_ScreenSizeSqrt[2]*3, 0.77*g_ScreenSize[2]-250 }
	g_Pos = { 30, 250 }
	g_WidgetCtrl[$(wg_show)](false)
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
	triggerEvent("onRafalhAddWidget", g_Root, getThisResource(), "Ranking board")
	addEventHandler("onRafalhGetWidgets", g_Root, function()
		triggerEvent("onRafalhAddWidget", g_Root, getThisResource(), "Ranking board")
	end)
	
	addEventHandler("rb_clear", resourceRoot, RbClear)
	addEventHandler("rb_addItem", resourceRoot, RbAddItem)
	addEventHandler("onClientPlayerQuit", root, RbPlayerQuit)
	
	triggerServerEvent("rb_onPlayerReady", resourceRoot)
#VERIFY_SERVER_END()
